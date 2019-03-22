--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Weapon Impulse",
    desc      = "Implements impulse reliant weapons because engine implementation is pretty much broken.",
    author    = "Google Frog",
    date      = "1 April 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
include("LuaRules/Configs/customcmds.h.lua")

local GRAVITY = Game.gravity
local GRAVITY_BASELINE = 120
local GROUND_PUSH_CONSTANT = 1.12*GRAVITY/30/30
local UNSTICK_CONSTANT = 4

local spSetUnitVelocity = Spring.SetUnitVelocity
local spAddUnitImpulse = Spring.AddUnitImpulse
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetCommandQueue = Spring.GetCommandQueue
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc   = Spring.RemoveUnitCmdDesc
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local getMovetype = Spring.Utilities.getMovetype
local abs = math.abs

local CMD_IDLEMODE = CMD.IDLEMODE
local CMD_REPEAT = CMD.REPEAT
local CMD_GUARD = CMD.GUARD
local CMD_STOP = CMD.STOP
local CMD_ONOFF = CMD.ONOFF

--local BALLISTIC_GUNSHIP_GRAVITY = -0.2
--local BALLISTIC_GUNSHIP_HEIGHT = 600000

--local spAreTeamsAllied = Spring.AreTeamsAllied

local GUNSHIP_VERTICAL_MULT = 0.25 -- prevents rediculus gunship climb

local impulseMult = {
	[0] = 0.02, -- fixedwing
	[1] = 0.004, -- gunships
	[2] = 0.0036, -- other
}

local pushPullCmdDesc = {
	id      = CMD_PUSH_PULL,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Push / Pull',
	action  = 'pushpull',
	tooltip = 'Toggles whether gravity weapons push or pull',
	params  = {0, 'Push','Pull'}
}

local pushPullState = {}

local impulseWeaponID = {}
for i, wd in pairs(WeaponDefs) do
	if wd.customParams and wd.customParams.impulse then
		impulseWeaponID[wd.id] = {
			impulse = tonumber(wd.customParams.impulse),
			normalDamage = (wd.customParams.normaldamage and true or false),
			checkLOS = true
		}

		if wd.customParams.impulsemaxdepth and wd.customParams.impulsedepthmult then
			impulseWeaponID[wd.id].impulseMaxDepth = -tonumber(wd.customParams.impulsemaxdepth)
			impulseWeaponID[wd.id].impulseDepthMult = -tonumber(wd.customParams.impulsedepthmult)
		end
	end
end

local moveTypeByID = {}
local mass = {}
local impulseUnitDefID = {}

for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	mass[i] = ud.mass
	moveTypeByID[i] = getMovetype(ud)

	for _, w in pairs(ud.weapons) do
		if impulseWeaponID[w.weaponDef] then
			impulseUnitDefID[i] = true
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local thereIsStuffToDo = false
local unitByID = {count = 0, data = {}}
local unit = {}

local inTransport = {}

--local risingByID = {count = 0, data = {}}
--local rising = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function IsUnitOnGround(unitID)
	local x,y,z = spGetUnitPosition(unitID)
	local ground =  spGetGroundHeight(x,z)

	if ground and y then
		local diff = y - ground
		if diff < 1 then
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- General Functionss

local function DetatchFromGround(unitID, threshold, height, doImpulse)
	if UnitDefs[Spring.GetUnitDefID(unitID)].isImmobile then
		return
	end

	threshold = threshold or 0.01
	height = height or 0.1
	local x,y,z = spGetUnitPosition(unitID)
	local h = spGetGroundHeight(x,z)
	--GG.UnitEcho(unitID,h-y)
	if h >= y - threshold or y >= h - threshold then
		if doImpulse then
			spAddUnitImpulse(unitID, 0, doImpulse, 0)
		end
		Spring.MoveCtrl.Enable(unitID)
		Spring.MoveCtrl.SetPosition(unitID, x,  y + height, z)
		Spring.MoveCtrl.Disable(unitID)
		if doImpulse then
			spAddUnitImpulse(unitID, 0, -doImpulse, 0)
		end
	end
end

local function AddGadgetImpulseRaw(unitID, x, y, z, pushOffGround, useDummy, unitDefID, moveType, doLosCheck) -- could be GG if needed.
	unitDefID = unitDefID or spGetUnitDefID(unitID)
	moveType = moveType or moveTypeByID[unitDefID]
	if not unit[unitID] then
		unit[unitID] = {
			moveType = moveType,
			useDummy = useDummy,
			pushOffGround = pushOffGround,
			x = x, y = y, z = z
		}
		unitByID.count = unitByID.count + 1
		unitByID.data[unitByID.count] = unitID
	else
		unit[unitID].x = unit[unitID].x + x
		unit[unitID].y = unit[unitID].y + y
		unit[unitID].z = unit[unitID].z + z
		if useDummy then
			unit[unitID].useDummy = true
		end
		if pushOffGround then
			unit[unitID].pushOffGround = true
		end
	end
	
	if doLosCheck and moveType == 2 then -- Only los check for land/sea units.
		GG.AddSphericalLOSCheck(unitID, unitDefID)
	end
	thereIsStuffToDo = true
end


local function AddGadgetImpulse(unitID, x, y, z, magnitude, affectTransporter, pushOffGround, useDummy, myImpulseMult, unitDefID, moveType)
	if inTransport[unitID] then
		if not affectTransporter then
			return
		end
		unitDefID = inTransport[unitID].def
		unitID = inTransport[unitID].id
	else
		unitDefID = unitDefID or spGetUnitDefID(unitID)
	end

	if not moveTypeByID[unitDefID] then
		return
	end

	local _, _, inbuild = Spring.GetUnitIsStunned(unitID)
	if inbuild then
		return
	end

	local dis = math.sqrt(x^2 + y^2 + z^2)

	myImpulseMult = myImpulseMult or {1,1,1}

	local myMass = Spring.GetUnitRulesParam(unitID, "massOverride") or mass[unitDefID]
	local mag = magnitude*GRAVITY_BASELINE/dis*impulseMult[moveTypeByID[unitDefID]]*myImpulseMult[moveTypeByID[unitDefID]+1]/myMass

	if moveTypeByID[unitDefID] == 0 then
		x,y,z = x*mag, y*mag, z*mag
	elseif moveTypeByID[unitDefID] == 1 then
		x,y,z = x*mag, y*mag * GUNSHIP_VERTICAL_MULT, z*mag
	elseif moveTypeByID[unitDefID] == 2 then
		x,y,z = x*mag, y*mag, z*mag
		y = y + abs(magnitude)/(20*myMass)
		pushOffGround = pushOffGround and IsUnitOnGround(unitID)
		GG.AddSphericalLOSCheck(unitID, unitDefID)
	end

	AddGadgetImpulseRaw(unitID, x, y, z, pushOffGround, useDummy, unitDefID, moveType)

	--if moveTypeByID[unitDefID] == 1 and attackerTeam and spAreTeamsAllied(unitTeam, attackerTeam) then
	--	unit[unitID].allied	= true
	--end

end

local function DoAirDrag(unitID, factor, unitDefID)
	unitDefID = unitDefID or spGetUnitDefID(unitID)
	local vx,vy,vz = spGetUnitVelocity(unitID)
	if unitDefID and vx then
		local myMass = Spring.GetUnitRulesParam(unitID, "massOverride") or mass[unitDefID]
		factor = factor/(factor+myMass^1.5)
		--Spring.Echo(factor)
		spSetUnitVelocity(unitID, vx*(1-factor), vy*(1-factor), vz*(1-factor))
	end
end

GG.DetatchFromGround = DetatchFromGround
GG.AddGadgetImpulseRaw = AddGadgetImpulseRaw
GG.AddGadgetImpulse = AddGadgetImpulse
GG.DoAirDrag = DoAirDrag

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Space Gunship Handling
--[[
local function CheckSpaceGunships(f)
	local i = 1
	while i <= risingByID.count do
		local unitID = risingByID.data[i]
		local data = rising[unitID]
		local removeEntry = false

		if Spring.ValidUnitID(unitID) then

			local _,_,_, ux, uy, uz = spGetUnitPosition(unitID, true)
			local groundHeight = spGetGroundHeight(ux,uz)

			if (uy-groundHeight) > BALLISTIC_GUNSHIP_HEIGHT then
				if not data.inSpace then
					--Spring.SetUnitRulesParam(unitID, "inSpace", 1)
					GG.UpdateUnitAttributes(unitID)
					data.inSpace = true
				end
				AddGadgetImpulse(unitID, 0, BALLISTIC_GUNSHIP_GRAVITY, 0, 0, 1)
			else
				if data.inSpace then
					--Spring.SetUnitRulesParam(unitID, "inSpace", 0)
					GG.UpdateUnitAttributes(unitID)
					data.inSpace = false
				end
				local vx, vy, vz = Spring.GetUnitVelocity(unitID)
				if vy < 0 then
					removeEntry = true
				end
			end
		else
			removeEntry = false
		end

		if removeEntry then
			risingByID.data[i] = risingByID.data[risingByID.count]
			risingByID.data[risingByID.count] = nil
			risingByID.count = risingByID.count - 1
			rising[unitID] = nil
		else
			i = i + 1
		end
	end
end
--]]


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local function PushPullToggleCommand(unitID, unitDefID, state)
	if not impulseUnitDefID[unitDefID] then
		return
	end
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PUSH_PULL)
	if not cmdDescID then
		return
	end
	
	if state then
		if state ~= pushPullState[unitID] then
			pushPullState[unitID] = state
			pushPullCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, {params = pushPullCmdDesc.params})
		end
	else
		state = pushPullState[unitID]
	end
	
	if state then
		GG.DelegateOrder(unitID, CMD_ONOFF, {state, CMD_PUSH_PULL}, 0)
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_PUSH_PULL] = true, [CMD_ONOFF] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return impulseUnitDefID
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_ONOFF) then
		return cmdParams[2] == CMD_PUSH_PULL -- we block any on/off that we didn't call ourselves
	end
	if (cmdID ~= CMD_PUSH_PULL) then
		return true  -- command was not used
	end
	PushPullToggleCommand(unitID, unitDefID, cmdParams[1])
	return false  -- command was used
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(transportID) then
		spSetUnitVelocity(unitID, 0, 0, 0) -- prevent the impulse capacitor
	end

	inTransport[unitID] = nil
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	inTransport[unitID] = {id = transportID, def = spGetUnitDefID(transportID)}
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	inTransport[unitID] = nil
	if impulseUnitDefID[unitDefID] then
		pushPullState[unitID] = nil
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if not impulseUnitDefID[unitDefID] then
		return
	end
	PushPullToggleCommand(unitID, unitDefID)
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if not impulseUnitDefID[unitDefID] then
		return
	end

	spInsertUnitCmdDesc(unitID, pushPullCmdDesc)
	PushPullToggleCommand(unitID, unitDefID, 1)
	local onoffDescID = spFindUnitCmdDesc(unitID, CMD_ONOFF)
	spRemoveUnitCmdDesc(unitID, onoffDescID)
end

function gadget:Initialize()
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)

		local transporting = Spring.GetUnitIsTransporting(unitID)
		if transporting then
			for i = 1, #transporting do
				local transporteeID = transporting[i]
				local transporteeDefID = spGetUnitDefID(transporteeID)
				if transporteeDefID then
					gadget:UnitLoaded(transporteeID, transporteeDefID, nil, unitID, nil)
				end
			end
		end
	end
end

function gadget:Load(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	local units = GG.SaveLoad.GetSavedUnitsCopy()
	for oldID, data in pairs(units) do
		local newID = GG.SaveLoad.GetNewUnitID(oldID)
		if newID and data.states.custom then
			local state = data.states.custom[CMD_PUSH_PULL]
			if state then
				local unitDefID = Spring.GetUnitDefID(newID)
				PushPullToggleCommand(newID, unitDefID, tonumber(state))
			end
		end
	end
	if collectgarbage then
		units = nil
		collectgarbage("collect")
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Main Impulse Handling

local function distance(x1,y1,z1,x2,y2,z2)
	return math.sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2)
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if impulseWeaponID[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	--spAddUnitImpulse(unitID,0,3,0)
	if weaponDefID and attackerID and impulseWeaponID[weaponDefID] and Spring.ValidUnitID(attackerID) then
		local defData = impulseWeaponID[weaponDefID]
		local _,_,_,ux, uy, uz = spGetUnitPosition(unitID, true)
		local _,_,_,ax, ay, az = spGetUnitPosition(attackerID, true)

		local x,y,z = (ux-ax), (uy-ay), (uz-az)
		local magnitude = defData.impulse

		if defData.impulseMaxDepth then
			local depth = spGetGroundHeight(ax,az)
			if depth < 0 then
				if depth < defData.impulseMaxDepth then
					depth = defData.impulseMaxDepth
				end
				magnitude = magnitude + depth*defData.impulseDepthMult
			end
		end

		AddGadgetImpulse(unitID, x, y, z, magnitude*(0.4 + math.random()*1.2), true, false, true, false, unitDefID)

		if defData.selfImpulse then
			AddGadgetImpulse(attackerID, x, y, z, -magnitude*(0.4 + math.random()*1.2), true, false, true, false, unitDefID)
		end

		if defData.normalDamage then
			return damage
		else
			return 0
		end
	end
	return damage
end

local function AddImpulses()
	if thereIsStuffToDo then
		for i = 1, unitByID.count do
			local unitID = unitByID.data[i]
			local data = unit[unitID]
			if data.moveType == 1 then
				local vx, vy, vz = spGetUnitVelocity(unitID)
				if vx then
					spSetUnitVelocity(unitID, vx + data.x, vy + data.y, vz + data.z)

					--if data.allied then
						if Spring.Utilities.GetUnitFirstCommand(unitID) == CMD_GUARD then
							spGiveOrderToUnit(unitID, CMD_STOP, {0}, 0)
						end

						if Spring.Utilities.GetUnitRepeat(unitID) then
							spGiveOrderToUnit(unitID, CMD_REPEAT, {0}, 0)
						end
					--end
					--[[
					if vy + data.y > 0 and not rising[unitID] then
						rising[unitID] = {inSpace = false}
						risingByID.count = risingByID.count + 1
						risingByID.data[risingByID.count] = unitID
					end
					--]]
				end
			elseif data.moveType == 0 then
				spAddUnitImpulse(unitID, data.x, data.y, data.z)
			else
				if data.pushOffGround then
					data.y = data.y + GROUND_PUSH_CONSTANT
				end
				if data.useDummy then
					spAddUnitImpulse(unitID, UNSTICK_CONSTANT,0,0) --dummy impulse (applying impulse>1 make unit less sticky to map surface)
					spAddUnitImpulse(unitID, data.x, data.y, data.z)
					spAddUnitImpulse(unitID, -UNSTICK_CONSTANT,0,0) --remove dummy impulse
				else
					spAddUnitImpulse(unitID, data.x, data.y, data.z)
				end
				--GG.UnitEcho(unitID,data.y)
			end
		end
		unitByID = {count = 0, data = {}}
		unit = {}
		thereIsStuffToDo = false
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Game Frame

function gadget:GameFrame(f)
	--CheckSpaceGunships()
	AddImpulses()
end
