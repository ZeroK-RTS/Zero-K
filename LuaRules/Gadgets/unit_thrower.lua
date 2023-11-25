
function gadget:GetInfo()
	return {
		name      = "Teleport Throw",
		desc      = "Implements teleportation thrower unit",
		author    = "Google Frog",
		date      = "12 Janurary 2018",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true  --  loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local throwDefs = {}
local throwWeaponDef = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.thrower_gather then
		throwDefs[i] = {
			radius = tonumber(ud.customParams.thrower_gather),
		}
	end
end

for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.customParams.thower_weapon then
		throwWeaponDef[i] = true
	end
end

local spGetUnitPosition = Spring.GetUnitPosition
local GetEffectiveWeaponRange = Spring.Utilities.GetEffectiveWeaponRange
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local applyBlockingFrame = {}
local unitIsNotBlocking = {}

local cachedAttackCommandDesc = false

local _, _, _, overkillPreventionDefault = include("LuaRules/Configs/overkill_prevention_defs.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Constants

local GRAVITY = (Game.gravity/30/30)

local FEATURE = 102
local GROUND = 103
local UNIT = 117

local MIN_FLY_TIME = 125
local MAX_FLY_TIME = 125

local SPEED_MAX = 20 --9
local SPEED_INT_WIDTH = 3
-- Dart speed is 5.1.
-- Normal launch speed is 9.9

local RECENT_MAX = -1.15 -- Ensure that units that are still being accelerated sideways cannot be rethrown
local RECENT_INT_WIDTH = 1

local MAX_ALTITUDE_AIM = 60

local NO_BLOCK_TIME = 5
local REMOVE_COMMAND_FRAME = 2
local ATTACK_BLOCK_DEFAULT = 1

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Shared functions

local spGetUnitDefID = Spring.GetUnitDefID
local getMovetype = Spring.Utilities.getMovetype

local canBeThrown = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isGroundUnit then -- includes sea units
		canBeThrown[i] = true
	end
end

local function ValidThrowTarget(unitID, targetID, speed)
	if unitID == targetID then
		return false
	end
	if speed > SPEED_MAX then
		return false
	end
	if Spring.GetUnitTransporter(targetID) then
		return false
	end
	local unitDefID = spGetUnitDefID(targetID)
	return canBeThrown[unitDefID]
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spRemoveUnitCmdDesc   = Spring.RemoveUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitLosState     = Spring.GetUnitLosState

local CMD_ATTACK = CMD.ATTACK
local CMD_INSERT = CMD.INSERT

local unitBlockAttackCmd = {
	id      = CMD_DISABLE_ATTACK,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Disable Attack',
	action  = 'disableattack',
	tooltip = 'Allow attack commands',
	params  = {0, 'Allowed','Blocked'}
}

local preventOverkillCmdDesc = {
	id      = CMD_PREVENT_OVERKILL,
	type    = CMDTYPE.ICON_MODE,
	name    = "Prevent Overkill.",
	action  = 'preventoverkill',
	tooltip	= 'Enable to prevent units shooting at units which are already going to die.',
	params 	= {0, "Fire at anything", "On automatic commands", "On fire at will", "Prevent Overkill"}
}

local recentlyLobbedLobsters = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function SetUnitDrag(unitID, drag)
	local ux, uy, uz = spGetUnitPosition(unitID)
	local rx, ry, rz = Spring.GetUnitRotation(unitID)
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	Spring.SetUnitPhysics(unitID, ux, uy, uz, vx, vy, vz, rx, ry, rz, drag, drag, drag)
end

local max = math.max
local min = math.min

local throwUnits = IterableMap.New()
local physicsRestore = IterableMap.New()
local UPDATE_PERIOD = 6

local function SendUnitToTarget(unitID, launchMult, sideMult, upMult, odx, ty, odz)
	if Spring.GetUnitTransporter(unitID) then
		return false
	end
	local _,_,_, _, ny = spGetUnitPosition(unitID, true)
	if not ny then
		return false
	end
	local ndy = ty - ny
	local flyTime = MIN_FLY_TIME -- math.max(MIN_FLY_TIME, math.min(MAX_FLY_TIME, math.sqrt(math.abs(ndy))*10))
	
	local px, py, pz = odx/flyTime, flyTime*GRAVITY/2 + ndy/flyTime, odz/flyTime
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	
	GG.AddGadgetImpulseRaw(unitID, (px - vx)*launchMult*sideMult, (py - vy)*launchMult*upMult, (pz - vz)*launchMult*sideMult, true, true, nil, nil, true)
	return flyTime
end

local function GetAffectedUnits(unitID, checkOverlobAllyTeam, unitX, unitZ)
	-- Use checkOverlobAllyTeam to check if any targets exist in LOS. It was
	-- shoehorned in as keeping validity in one place seems best.
	local data = IterableMap.Get(throwUnits, unitID)
	if not data then
		return
	end
	if not unitX then
		local _,_,_, ox, oy, oz = spGetUnitPosition(unitID, true)
		unitX, unitZ = ox, oz
	end
	
	local nearUnits = Spring.GetUnitsInCylinder(unitX, unitZ, data.def.radius)
	local affectedUnits = false
	if nearUnits then
		for i = 1, #nearUnits do
			local nearID = nearUnits[i]
			local physicsData = physicsRestore and IterableMap.Get(physicsRestore, nearID)
			local _, _, _, speed = Spring.GetUnitVelocity(nearID)
			if ((not physicsData) or (not physicsData.drag) or physicsData.drag > RECENT_MAX) and ValidThrowTarget(unitID, nearID, speed) then
				if checkOverlobAllyTeam then
					local inLos = spGetUnitLosState(nearID, checkOverlobAllyTeam, true)
					if inLos and inLos%2 == 1 then
						return true
					end
				end
				affectedUnits = affectedUnits or {}
				affectedUnits[#affectedUnits + 1] = nearUnits[i]
			end
		end
	end
	if checkOverlobAllyTeam then
		return false
	end
	return affectedUnits
end

local function CheckRedundantCommandRemoval(unitID)
	if (not Spring.ValidUnitID(unitID)) or Spring.Utilities.GetUnitRepeat(unitID) then
		return
	end
	local beingLobbedTo = IterableMap.Get(physicsRestore, unitID)
	if not beingLobbedTo then
		return
	end
	local cmdID, _, cmdTag, cp_1, cp_2, cp_3  = Spring.GetUnitCurrentCommand(unitID)
	if not (cp_3 and (cmdID == CMD_ATTACK or cmdID == CMD.MANUALFIRE)) then
		return
	end
	if math.abs(cp_1 - beingLobbedTo.tx) < 1 and math.abs(cp_3 - beingLobbedTo.tz) < 1 then
		Spring.GiveOrderToUnit(unitID, CMD.REMOVE, cmdTag, 0)
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not weaponDefID and throwWeaponDef[weaponDefID] then
		return
	end
	
	local data = IterableMap.Get(throwUnits, proOwnerID)
	if not data then
		return
	end
	
	-- Calculate target position.
	local targetType, targetPos = Spring.GetProjectileTarget(proID)
	local tx, ty, tz
	if targetType == GROUND then
		tx, ty, tz = targetPos[1], targetPos[2], targetPos[3]
	else
		_, _, _, tx, ty, tz = spGetUnitPosition(targetPos, true)
		local groundHeight = math.max(Spring.Utilities.GetGroundHeightMinusOffmap(tx, tz) or 0, 0)
		ty = math.min(ty, groundHeight - MAX_ALTITUDE_AIM)
	end
	ty = math.max(ty, 0)
	
	-- Calculate horizontal aiming parameters based on projectile owner position.
	local _,_,_, ox, oy, oz = spGetUnitPosition(proOwnerID, true)
	local odx, ody, odz = tx - ox, ty - oy, tz - oz
	local fireDistance = math.sqrt(odx^2 + odz^2)
	
	local maxRange = GetEffectiveWeaponRange(data.unitDefID, -ody, data.weaponNum)
	if maxRange and fireDistance > maxRange*1.05 then
		maxRange = maxRange*1.05
		odx = odx*maxRange/fireDistance
		odz = odz*maxRange/fireDistance
	end
	
	-- Blocking
	Spring.SetUnitBlocking(proOwnerID, true, false)
	local frame = Spring.GetGameFrame() 
	local noBlockFrame = frame + NO_BLOCK_TIME
	applyBlockingFrame[noBlockFrame] = applyBlockingFrame[noBlockFrame] or {}
	applyBlockingFrame[noBlockFrame][proOwnerID] = true
	unitIsNotBlocking[proOwnerID] = noBlockFrame
	
	-- Apply impulse
	local affectedUnits = GetAffectedUnits(proOwnerID, false, ox, oz)
	if not affectedUnits then
		Spring.DeleteProjectile(proID)
		return
	end
	
	local lobbedLobbers = {}
	for i = 1, #affectedUnits do
		local nearID = affectedUnits[i]
		local _, _, _, speed = Spring.GetUnitVelocity(nearID)
		local recentMult = max(0, min(1, (((physicsData and physicsData.drag) or 0) - RECENT_MAX)/RECENT_INT_WIDTH))
		local speedMult  = max(0, min(1, (SPEED_MAX - speed)/SPEED_INT_WIDTH))
		local launchMult = speedMult
		
		local flyTime = SendUnitToTarget(nearID, launchMult, 0, 1, odx, ty, odz)
		if flyTime then
			local nearDefID = Spring.GetUnitDefID(nearID)
			flyTime = flyTime + 15 -- Sideways time.
			
			SetUnitDrag(nearID, 0)
			GG.SetCollisionDamageMult(nearID, 0)
			Spring.SetUnitLeaveTracks(nearID, false)
			IterableMap.Add(physicsRestore, nearID,
				{
					unitDefID = nearDefID,
					tx = tx,
					ty = ty,
					tz = tz,
					odx = odx,
					odz = odz,
					sidewaysCounter = 15,
					launchMult = launchMult,
					drag = -1.5,
					collisionResistence = -5*flyTime/MIN_FLY_TIME,
				}
			)
			SendToUnsynced("addFlying", nearID, nearDefID, flyTime)
			GG.Floating_InterruptFloat(nearID, 60)
			
			if IterableMap.Get(throwUnits, nearID) then
				local removeFrame = frame + REMOVE_COMMAND_FRAME
				recentlyLobbedLobsters[removeFrame] = recentlyLobbedLobsters[removeFrame] or {}
				recentlyLobbedLobsters[removeFrame][#recentlyLobbedLobsters[removeFrame] + 1] = nearID
			end
		end
	end
	
	Spring.DeleteProjectile(proID)
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if throwWeaponDef[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if weaponID and throwWeaponDef[weaponID] then
		return 0
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local function CacheAttackCommandDesc(unitID)
	local cmdTable = Spring.GetUnitCmdDescs(unitID)
	for i = 1, #cmdTable do
		if cmdTable[i].id == CMD.ATTACK then
			cachedAttackCommandDesc = cmdTable[i]
			return
		end
	end
end

local function BlockAttackToggle(unitID, cmdParams)
	local data = IterableMap.Get(throwUnits, unitID)
	if data then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_DISABLE_ATTACK)
		
		if (cmdDescID) then
			unitBlockAttackCmd.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = unitBlockAttackCmd.params})
		end
		if state == 1 then
			local cmdDesc = spFindUnitCmdDesc(unitID, CMD.ATTACK)
			if cmdDesc then
				if not cachedAttackCommandDesc then
					CacheAttackCommandDesc(unitID)
					--Spring.Utilities.TableEcho(cachedAttackCommandDesc, "cmdDesc")
				end
				spRemoveUnitCmdDesc(unitID, cmdDesc)
			end
		elseif cachedAttackCommandDesc then
			local cmdDesc = spFindUnitCmdDesc(unitID, CMD.ATTACK)
			if not cmdDesc then
				spInsertUnitCmdDesc(unitID, cachedAttackCommandDesc)
			end
		end
		data.blockAttack = (state == 1)
	end
end

local function PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)
	local data = IterableMap.Get(throwUnits, unitID)
	if not data then
		return true
	end
	local state = cmdParams[1]
	if cmdOptions and cmdOptions.right then
		state = (state - 2)%4
	end
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PREVENT_OVERKILL)
	
	if (cmdDescID) then
		preventOverkillCmdDesc.params[1] = state
		spEditUnitCmdDesc(unitID, cmdDescID, {params = preventOverkillCmdDesc.params})
	end
	data.preventOverlob = ((state >= 1) and state)
	return false
end

function gadget:AllowCommand_GetWantedCommand()
	return {
		[CMD_DISABLE_ATTACK] = true,
		[CMD_ATTACK] = true,
		[CMD_INSERT] = true,
		[CMD_UNIT_SET_TARGET] = true,
		[CMD_UNIT_SET_TARGET_CIRCLE] = true,
		[CMD_PREVENT_OVERKILL] = true,
	}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	local wanted = {}
	for unitID, _ in pairs(throwDefs) do
		wanted[unitID] = true
	end
	return wanted
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_INSERT and cmdParams and cmdParams[2]) then
		cmdID = cmdParams[2]
	end
	
	if (cmdID == CMD_ATTACK) or (cmdID == CMD_UNIT_SET_TARGET) or (cmdID == CMD_UNIT_SET_TARGET_CIRCLE) then
		local data = IterableMap.Get(throwUnits, unitID)
		if (data and data.blockAttack) then
			return false  -- command was used
		end
		return true  -- command was not used
	end
	
	if (cmdID == CMD_PREVENT_OVERKILL) then
		return PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)
	end
	if (cmdID ~= CMD_DISABLE_ATTACK) then
		return true  -- command was not used
	end
	BlockAttackToggle(unitID, cmdParams)
	return false  -- command was used
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit Handler

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if throwDefs[unitDefID] then
		IterableMap.Add(throwUnits, unitID,
			{
				def = throwDefs[unitDefID],
				unitDefID = unitDefID,
				weaponNum = 1,
			}
		)
		
		spInsertUnitCmdDesc(unitID, unitBlockAttackCmd)
		spInsertUnitCmdDesc(unitID, preventOverkillCmdDesc)
		BlockAttackToggle(unitID, {ATTACK_BLOCK_DEFAULT})
		PreventOverkillToggleCommand(unitID, {overkillPreventionDefault[unitDefID]})
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	IterableMap.Remove(throwUnits, unitID)
	if unitIsNotBlocking[unitID] then
		local frame = unitIsNotBlocking[unitID]
		applyBlockingFrame[frame] = applyBlockingFrame[frame] or {}
		applyBlockingFrame[frame][unitID] = nil
	end
end

local externalFunc = {}
function externalFunc.BlockAttack(unitID)
	local unitData = unitID and IterableMap.Get(throwUnits, unitID)
	return unitData and unitData.blockAttack
end

function externalFunc.CheckOverlobPrevention(unitID)
	local unitData = unitID and IterableMap.Get(throwUnits, unitID)
	if not unitData then
		return false
	end
	if not unitData.preventOverlob then
		return false
	end
	if unitData.preventOverlob == 2 and Spring.Utilities.GetUnitFireState(unitID) ~= 2 then
		return false
	end
	-- Don't handle unitData.preventOverlob as Lobster is rarely fired at units and all ground commands are manual
	return not GetAffectedUnits(unitID, Spring.GetUnitAllyTeam(unitID))
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_DISABLE_ATTACK)
	
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end

	for id, _ in pairs(throwWeaponDef) do
		Script.SetWatchProjectile(id, true)
	end
	
	GG.Thrower = externalFunc
end

local function UpdateTrajectory(unitID, data)
	if not Spring.ValidUnitID(unitID) then
		return true
	end
	if data.sidewaysCounter then
		data.sidewaysCounter = data.sidewaysCounter - 1
		if data.sidewaysCounter < 10 then
			if not SendUnitToTarget(unitID, data.launchMult, 0.9*(1 - data.sidewaysCounter/10), 1, data.odx, data.ty, data.odz) then
				return true -- remove unit
			end
		end
		if data.sidewaysCounter <= 0 then
			data.sidewaysCounter = nil
		end
	end
end

local function ReinstatePhysics(unitID, data)
	GG.PokeDecloakUnit(unitID, data.unitDefID)
	if data.drag then
		SetUnitDrag(unitID, math.max(0, math.min(1, data.drag)))
		data.drag = data.drag + 0.05
		if data.drag >= 1 then
			Spring.SetUnitLeaveTracks(unitID, true)
			SetUnitDrag(unitID, 1)
			data.drag = nil
			GG.Floating_CheckAddFlyingFloat(unitID, data.unitDefID)
		end
	end
	
	if data.collisionResistence then
		GG.SetCollisionDamageMult(unitID, math.max(0, math.min(1, data.collisionResistence)))
		data.collisionResistence = data.collisionResistence + 0.066
		if data.collisionResistence >= 1 then
			GG.SetCollisionDamageMult(unitID)
			SendToUnsynced("removeFlying", unitID)
			return true -- remove unit
		end
	end
end

function gadget:GameFrame(n)
	IterableMap.Apply(physicsRestore, UpdateTrajectory)
	if n%2 == 0 then
		IterableMap.Apply(physicsRestore, ReinstatePhysics)
	end
	
	if applyBlockingFrame[n] then
		for unitID, _ in pairs(applyBlockingFrame[n]) do
			if Spring.ValidUnitID(unitID) then
				Spring.SetUnitBlocking(unitID, true, true)
				unitIsNotBlocking[unitID] = nil
			end
		end
		applyBlockingFrame[n] = nil
	end
	
	if recentlyLobbedLobsters[n] then
		local handled = {}
		for i = 1, #recentlyLobbedLobsters[n] do
			local unitID = recentlyLobbedLobsters[n][i]
			if not handled[unitID] then
				CheckRedundantCommandRemoval(unitID)
			end
		end
		recentlyLobbedLobsters[n] = nil
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Line drawing

local glVertex            = gl.Vertex
local spIsUnitInView      = Spring.IsUnitInView
local spGetUnitLosState   = Spring.GetUnitLosState
local spValidUnitID       = Spring.ValidUnitID
local spGetMyAllyTeamID   = Spring.GetMyAllyTeamID
local spGetUnitVectors    = Spring.GetUnitVectors
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local throwers = IterableMap.New()
local alreadyWired = {}

local function UnitIsActive(unitID)
	if not spValidUnitID(unitID) then
		return false
	end
	
	local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID)
	local disarmed = (spGetUnitRulesParam(unitID, "disarmed") == 1)
	return not (stunned_or_inbuild or disarmed)
end

local function DrawBezierCurve(pointA, pointB, pointC,pointD, amountOfPoints)
	local step = 1/amountOfPoints
	glVertex (pointA[1], pointA[2], pointA[3])
	for i=0, 1, step do
		local x = pointA[1]*((1-i)^3) + pointB[1]*(3*i*(1-i)^2) + pointC[1]*(3*i*i*(1-i)) + pointD[1]*(i*i*i)
		local y = pointA[2]*((1-i)^3) + pointB[2]*(3*i*(1-i)^2) + pointC[2]*(3*i*i*(1-i)) + pointD[2]*(i*i*i)
		local z = pointA[3]*((1-i)^3) + pointB[3]*(3*i*(1-i)^2) + pointC[3]*(3*i*i*(1-i)) + pointD[3]*(i*i*i)
		glVertex(x,y,z)
	end
	glVertex(pointD[1],pointD[2],pointD[3])
end

local function GetUnitTop (unitID, x,y,z)
	local height = Spring.GetUnitHeight(unitID) -- previously hardcoded to 50
	local top = select(2, spGetUnitVectors(unitID))
	local offX = top[1]*height
	local offY = top[2]*height
	local offZ = top[3]*height
	return x+offX, y+offY, z+offZ
end

local function DrawWire(emitUnitID, recUnitID, spec, myAllyTeam, x, y, z)
	local point = {}
	if spValidUnitID(recUnitID) then
		local los = spGetUnitLosState(recUnitID, myAllyTeam, true)
		if (spec or (los and los%2 == 1)) and (spIsUnitInView(emitUnitID) or spIsUnitInView(recUnitID)) then
			local topX, topY, topZ = GetUnitTop(emitUnitID, x, y, z)
			point[1] = {x, y, z}
			point[2] = {topX, topY, topZ}
			local _,_,_, rX, rY, rZ = spGetUnitPosition(recUnitID, true)
			topX, topY, topZ = GetUnitTop(recUnitID, rX, rY, rZ)
			point[3] = {topX,topY,topZ}
			point[4] = {rX, rY, rZ}
			gl.PushAttrib(GL.LINE_BITS)
			gl.DepthTest(true)
			gl.Color (0, 1, 0.5, math.random()*0.1 + 0.18)
			gl.LineWidth(3)
			gl.BeginEnd(GL.LINE_STRIP, DrawBezierCurve, point[1], point[2], point[3], point[4], 10)
			gl.DepthTest(false)
			gl.Color (1,1,1,1)
			gl.PopAttrib()
		end
	end
end

local function DrawThrowerWires(unitID, data, index, spec, myAllyTeam)
	if not UnitIsActive(unitID) then
		return
	end
	local los = spGetUnitLosState(unitID, myAllyTeam, true)
	if spec or (los and (los and los%2 == 1)) then
		local _,_,_, x, y, z = spGetUnitPosition(unitID, true)
		local nearUnits = Spring.GetUnitsInCylinder(x, z, data.def.radius)
		if nearUnits then
			for i = 1, #nearUnits do
				local nearID = nearUnits[i]
				local _, _, _, speed = Spring.GetUnitVelocity(nearID)
				if ValidThrowTarget(unitID, nearID, speed) and not alreadyWired[nearID] then
					DrawWire(unitID, nearID, spec, myAllyTeam, x, y, z)
					alreadyWired[nearID] = true
				end
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if throwDefs[unitDefID] then
		IterableMap.Add(throwers, unitID,
			{
				def = throwDefs[unitDefID],
			}
		)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	IterableMap.Remove(throwers, unitID)
end

local function DrawWorldFunc()
	if IterableMap.GetIndexMax(throwers) > 0 then
		local _, fullview = Spring.GetSpectatingState()
		alreadyWired = {}
		IterableMap.Apply(throwers, DrawThrowerWires, fullview, spGetMyAllyTeamID())
	end
end

function gadget:DrawWorld()
	DrawWorldFunc()
end

function gadget:DrawWorldRefraction()
	DrawWorldFunc()
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Flying lups

local Lups

local particleIDs = {}

local flyFX = {
	{
		class = 'StaticParticles',
		options = {
			life        = 250,
			sizeMod     = 4,
			colormap    = {{0, 0.4, 0.05, 0.006},{0, 0.6, 0.05, 0.006}, {0, 0.4, 0.05, 0.006}, {0, 0, 0, 0.006}},
			texture     = 'bitmaps/GPL/groundflash.tga',
			count       = 1,
			quality     = 1, -- Low
			noIconDraw = true,
		}
	}
}

local function removeFlying(_, unitID)
	if not particleIDs[unitID] then
		return
	end
	for i = 1, #particleIDs[unitID] do
		Lups.RemoveParticles(particleIDs[unitID][i])
	end
	particleIDs[unitID] = nil
end

local function addFlying(_, unitID, unitDefID, flyTime)
	removeFlying(nil, unitID)
	particleIDs[unitID] = {}
	local teamID = Spring.GetUnitTeam(unitID)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local radius = Spring.GetUnitRadius(unitID)
	local height = Spring.GetUnitHeight(unitID)
	for i,fx in pairs(flyFX) do
		fx.options.unit = unitID
		fx.options.unitDefID = unitDefID
		fx.options.team      = teamID
		fx.options.allyTeam  = allyTeamID
		fx.options.size = radius * (fx.options.sizeMod or 1)
		fx.options.pos = {0, height/2, 0}
		fx.options.life = flyTime*1.15
		particleIDs[unitID][#particleIDs[unitID] + 1] = Lups.AddParticles(fx.class,fx.options)
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Gadget interface

function gadget:Initialize()
	gadgetHandler:AddSyncAction("addFlying", addFlying)
	gadgetHandler:AddSyncAction("removeFlying", removeFlying)
	
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end

function gadget:Update()
	if (not Lups) then
		Lups = GG['Lups']
	end
end


function gadget:Shutdown()
	gadgetHandler.RemoveSyncAction("addFlying")
    gadgetHandler.RemoveSyncAction("removeFlying")
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
