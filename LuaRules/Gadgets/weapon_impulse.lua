
function gadget:GetInfo()
  return {
    name      = "Weapon Impulse ",
    desc      = "Implements impulse relaint weapons because engine impelementation is prettymuch broken.",
    author    = "Google Frog",
    date      = "1 April 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local GRAVITY = Game.gravity
local GRAVITY_BASELINE = 120
local GROUND_PUSH_CONSTANT = 1.1*GRAVITY/30/30

local spSetUnitVelocity = Spring.SetUnitVelocity
local spAddUnitImpulse = Spring.AddUnitImpulse
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitStates = Spring.GetUnitStates
local spGetCommandQueue = Spring.GetCommandQueue
local CMD_IDLEMODE = CMD.IDLEMODE
local CMD_REPEAT = CMD.REPEAT
local CMD_GUARD = CMD.GUARD
local CMD_STOP = CMD.STOP
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local abs = math.abs
local getMovetype = Spring.Utilities.getMovetype


local UNSTICK_CONSTANT = 0
if (Game.version:find('91.0') == 1) then
	UNSTICK_CONSTANT = 2.74 -- for Spring 91.0
elseif (Game.version:find('94') and Game.version:find('94.1.1')== nil) then
	UNSTICK_CONSTANT = 3.00 -- for Spring 94.1
end

--local BALLISTIC_GUNSHIP_GRAVITY = -0.2
--local BALLISTIC_GUNSHIP_HEIGHT = 600000

--local spAreTeamsAllied = Spring.AreTeamsAllied

local GUNSHIP_VERTICAL_MULT = 0.25 -- prevents rediculus gunship climb

local impulseMult = {
	[0] = 0.02, -- fixedwing
	[1] = 0.004, -- gunships
	[2] = 0.0032, -- other
}
local impulseWeaponID = {}
for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
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

for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	mass[i] = ud.mass
	moveTypeByID[i] = getMovetype(ud)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local thereIsStuffToDo = false
local unitByID = {count = 0, data = {}}
local unit = {}

local transportMass = {}
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

local function DetatchFromGround(unitID)
	local x,y,z = spGetUnitPosition(unitID)
	local h = spGetGroundHeight(x,z)
	--GG.UnitEcho(unitID,h-y)
	if h >= y - 0.01 or y >= h - 0.01 then
		--spAddUnitImpulse(unitID, 0,1000,0)
		Spring.MoveCtrl.Enable(unitID)
		Spring.MoveCtrl.SetPosition(unitID, x, y+0.1, z)
		Spring.MoveCtrl.Disable(unitID)
		--spAddUnitImpulse(unitID, 0,-1000,0)
	end
end

local function AddGadgetImpulseRaw(unitID, x, y, z, pushOffGround, useDummy, unitDefID, moveType) -- could be GG if needed.
	moveType = moveType or moveTypeByID[unitDefID or spGetUnitDefID(unitID)]
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
	
	local myMass = transportMass[unitID] or mass[unitDefID]
	local mag = magnitude*GRAVITY_BASELINE/dis*impulseMult[moveTypeByID[unitDefID]]*myImpulseMult[moveTypeByID[unitDefID]+1]/myMass
	
	if moveTypeByID[unitDefID] == 0 then
		x,y,z = x*mag, y*mag, z*mag
	elseif moveTypeByID[unitDefID] == 1 then
		x,y,z = x*mag, y*mag * GUNSHIP_VERTICAL_MULT, z*mag
	elseif moveTypeByID[unitDefID] == 2 then
		x,y,z = x*mag, y*mag, z*mag
		y = y + abs(magnitude)/(20*myMass)
		pushOffGround = pushOffGround and IsUnitOnGround(unitID)
		GG.AddSphereicalLOSCheck(unitID, unitDefID)
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
		local myMass = transportMass[unitID] or mass[unitDefID]
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
					GG.attUnits[unitID] = true
					GG.UpdateUnitAttributes(unitID)
					data.inSpace = true
				end
				AddGadgetImpulse(unitID, 0, BALLISTIC_GUNSHIP_GRAVITY, 0, 0, 1)
			else
				if data.inSpace then
					--Spring.SetUnitRulesParam(unitID, "inSpace", 0)
					GG.attUnits[unitID] = true
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
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Transport Handling

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(transportID) then
		spSetUnitVelocity(unitID, 0, 0, 0) -- prevent the impulse capacitor
	end
	
	if transportMass[transportID] then
		transportMass[transportID] = transportMass[transportID] - mass[unitDefID]
		--Spring.Echo(transportMass[transportID])
	end
	inTransport[unitID] = nil
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if transportMass[transportID] then
		transportMass[transportID] = transportMass[transportID] + mass[unitDefID]
	else
		local tudid = spGetUnitDefID(transportID)
		transportMass[transportID] = mass[tudid] + mass[unitDefID]
	end
	inTransport[unitID] = {id = transportID, def = spGetUnitDefID(transportID)}
	--Spring.Echo(transportMass[transportID])
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if inTransport[unitID] then
		local transportID = inTransport[unitID].id
		if transportMass[transportID] then
			transportMass[transportID] = transportMass[transportID] - mass[unitDefID]
			--Spring.Echo(transportMass[transportID])
		end
		inTransport[unitID] = nil
		--Spring.Echo(transportMass[transportID])
	end
end

function gadget:Initialize()
	-- load active units
	for _, transportID in ipairs(Spring.GetAllUnits()) do
		local transporting = Spring.GetUnitIsTransporting(transportID)
		if transporting then
			for i = 1, #transporting do
				local unitID = transporting[i]
				local unitDefID = spGetUnitDefID(unitID)
				if unitDefID then
					gadget:UnitLoaded(unitID, unitDefID, nil, transportID, nil)
				end
			end
		end
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
	if impulseWeaponID[weaponDefID] and Spring.ValidUnitID(attackerID) then
		local defData = impulseWeaponID[weaponDefID]
		local _,_,_,ux, uy, uz = spGetUnitPosition(unitID, true)
		local_,_,_,ax, ay, az = spGetUnitPosition(attackerID, true)
		
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
		
		AddGadgetImpulse(unitID, x, y, z, magnitude, true, false, true, false, unitDefID) 
		
		if defData.selfImpulse then
			AddGadgetImpulse(attackerID, x, y, z, -magnitude, true, false, true, false, unitDefID) 
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
						local cQueue = spGetCommandQueue(unitID,1)
						if #cQueue >= 1 and cQueue[1].id == CMD_GUARD then
							spGiveOrderToUnit(unitID, CMD_STOP, {0},{})
						end
						
						local states = spGetUnitStates(unitID)
						if states["repeat"] then
							spGiveOrderToUnit(unitID, CMD_REPEAT, {0},{})
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