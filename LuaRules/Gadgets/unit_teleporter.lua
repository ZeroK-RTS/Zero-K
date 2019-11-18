
function gadget:GetInfo()
  return {
    name      = "Teleporter",
    desc      = "Implements mass teleporter",
    author    = "Google Frog",
    date      = "29 Feb 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

include("LuaRules/Configs/customcmds.h.lua")
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

--local BEACON_PLACE_RANGE_SQR = 80000^2	-- causes SIGFPE, max tested value is ~46340^2 (see http://code.google.com/p/zero-k/issues/detail?id=1506)
--local BEACON_PLACE_RANGE_MOVE = 75000
local BEACON_WAIT_RANGE_MOVE = 150
local BEACON_TELEPORT_RADIUS = 200
local BEACON_TELEPORT_RADIUS_SQR = BEACON_TELEPORT_RADIUS^2

-- Used in synced and unsynced
local canTeleport = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isFactory or not (ud.isImmobile or ud.isStrafingAirUnit) then
		canTeleport[i] = true
	end
end

if (gadgetHandler:IsSyncedCode()) then

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local GiveClampedMoveGoalToUnit = Spring.Utilities.GiveClampedMoveGoalToUnit

local placeBeaconCmdDesc = {
	id      = CMD_PLACE_BEACON,
	type    = CMDTYPE.ICON_MAP,
	name    = 'Beacon',
	cursor  = 'Unload units',
	action  = 'placebeacon',
	tooltip = 'Place teleport entrance at selected location.',
}

local waitAtBeaconCmdDesc = {
	id      = CMD_WAIT_AT_BEACON,
	type    = CMDTYPE.ICON_UNIT,
	name    = 'Beacon Queue',
	cursor  = 'Load units',
	action  = 'beaconqueue',
	tooltip = 'Wait to be teleported by a beacon.',
	hidden  = true,
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local beaconDef = UnitDefNames["tele_beacon"].id

local offset = {
	[0] = {x = 1, z = 0},
	[1] = {x = 1, z = 1},
	[2] = {x = 0, z = 1},
	[3] = {x = -1, z = 1},
	[4] = {x = 0, z = -1},
	[5] = {x = -1, z = -1},
	[6] = {x = 1, z = -1},
	[7] = {x = -1, z = 0},
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local teleID = {count = 0, data = {}}	-- data = {djinnID1, djinnID2, ...}
local tele = {}	-- {[unitID] = {Djinn's data}}
local beacon = {}	-- [unitID] = {link = Djinn ID, x = x, z = z}
local orphanedBeacons = {}	-- array of beacon IDs, beacons are destroyed every gameframe

local beaconWaiter = {}	-- {[waiting unit ID] = {bunch of stuff}}
local teleportingUnit = {}	-- {[teleportiee ID] = Djinn ID}

--[[
local nearRead = 1
local nearWrite = 2
local nearBeacon = {
	[1] = {},
	[2] = {},
}--]]

local checkFrame = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Most script interaction

local function callScript(unitID, funcName, args)
	local func = Spring.UnitScript.GetScriptEnv(unitID)
	if func then
		func = func[funcName]
		if func then
			return Spring.UnitScript.CallAsUnit(unitID,func, args)
		end
	end
	return false
end

local function changeSpeed(tid, bid, speed)
	Spring.UnitScript.CallAsUnit(tid, Spring.UnitScript.GetScriptEnv(tid).activity_mode, speed)
	if bid then
		Spring.UnitScript.CallAsUnit(bid,Spring.UnitScript.GetScriptEnv(bid).activity_mode, speed)
	end
end

local function interruptTeleport(unitID, doNotChangeSpeed)
	if not tele[unitID] then
		return
	end
	if tele[unitID].teleportiee then
		teleportingUnit[tele[unitID].teleportiee] = nil
		tele[unitID].teleportiee = false
		Spring.SetUnitRulesParam(unitID, "teleportiee", -1)
	end
	tele[unitID].teleFrame = false
	tele[unitID].cost = false
	
	Spring.SetUnitRulesParam(unitID,"teleportend",-1)

	if tele[unitID].link then
		local func = Spring.UnitScript.GetScriptEnv(tele[unitID].link).endTeleOutLoop
		Spring.UnitScript.CallAsUnit(tele[unitID].link,func)
		Spring.SetUnitRulesParam(tele[unitID].link,"teleportend",-1)
	end

	if not doNotChangeSpeed and tele[unitID].deployed then
		changeSpeed(unitID, tele[unitID].link, 2)
	end
end

function tele_ableToDeploy(unitID)
	return tele[unitID] and tele[unitID].link and not tele[unitID].deployed
end

function tele_deployTeleport(unitID)
	tele[unitID].deployed = true
	checkFrame[Spring.GetGameFrame() + 1] = true
	
	changeSpeed(unitID, tele[unitID].link, 2)
	Spring.SetUnitRulesParam(unitID, "deploy", 1)
end

function tele_undeployTeleport(unitID)
	if tele[unitID].deployed then
		interruptTeleport(unitID)
	end
	tele[unitID].deployed = false
	changeSpeed(unitID, tele[unitID].link, 1)
	Spring.SetUnitRulesParam(unitID, "deploy", 0)
end

function tele_createBeacon(unitID, x, z, beaconID)
	local y = Spring.GetGroundHeight(x,z)
	local place, feature = Spring.TestBuildOrder(beaconDef, x, y, z, 1)
	changeSpeed(unitID, nil, 1)
	if beaconID or (place == 2 and feature == nil) then
		if tele[unitID].link and Spring.ValidUnitID(tele[unitID].link) then
			Spring.DestroyUnit(tele[unitID].link, true)
		end
		if not beaconID then
			GG.PlayFogHiddenSound("sounds/misc/teleport2.wav", 10, x, Spring.GetGroundHeight(x,z) or 0, z)
		end
		beaconID = beaconID or Spring.CreateUnit(beaconDef, x, y, z, 1, Spring.GetUnitTeam(unitID))
		if beaconID then
			Spring.SetUnitPosition(beaconID, x, y, z)
			Spring.SetUnitNeutral(beaconID,true)
			tele[unitID].link = beaconID
			beacon[beaconID] = {link = unitID, x = x, z = z}
			Spring.SetUnitRulesParam(beaconID, "connectto", unitID)
		end
	end
	Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, 0)
	Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, 0)
end

local function undeployTeleport(unitID)
	if tele[unitID].deployed then
		local func = Spring.UnitScript.GetScriptEnv(unitID).UndeployTeleport
		Spring.UnitScript.CallAsUnit(unitID,func)
		tele_undeployTeleport(unitID)
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Handle Teleportation

local function isUnitFlying(unitID)
	local x,y,z = Spring.GetUnitPosition(unitID)
	if x then
		local height = Spring.GetGroundHeight(x,z)
		if height == y then
			return false
		end
	end
	return true
end

local function isUnitDisabled(unitID)
	return (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) or select(1, Spring.GetUnitIsStunned(unitID))
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if teleportingUnit[unitID] and not (cmdID == CMD.INSERT or cmdOptions.shift) and cmdID ~= CMD.REMOVE and cmdID ~= CMD.FIRE_STATE and cmdID ~= CMD.MOVE_STATE and cmdID ~= CMD_WANT_CLOAK then
		interruptTeleport(teleportingUnit[unitID])
	end
	
	if cmdID == CMD.STOP and not (cmdID == CMD.INSERT or cmdOptions.shift) and tele[unitID] then
		local func = Spring.UnitScript.GetScriptEnv(unitID).StopCreateBeacon
		Spring.UnitScript.CallAsUnit(unitID, func)
	end

	if cmdID == CMD.INSERT then
		cmdID = cmdParams[2]
	end

	if cmdID == CMD_WAIT_AT_BEACON and not canTeleport[unitDefID] then
		return false
	end
	
	return true
end

local function Teleport_AllowCommand(unitID, unitDefID, cmdID, cmdParams, cmdOptions)
	return gadget:AllowCommand(unitID, unitDefID, false, cmdID, cmdParams, cmdOptions)
end

-- pick a point on map (towards random one of 8 directions) to teleport to
-- ud is teleportiee's unitdef, tx and tz are Djinn's position
local function GetTeleTargetPos(ud, tx, tz)
	local size = ud.xsize
	local startCheck = math.floor(math.random(8))
	local direction = (math.random() < 0.5 and -1) or 1
	for j = 0, 7 do
		local spot = (j*direction+startCheck)%8
		local place, feature = Spring.TestBuildOrder(ud.id, tx + offset[spot].x*(size*4+40), 0 ,tz + offset[spot].z*(size*4+40), 1)
		if (place == 2 and feature == nil) or ud.canFly then
			return spot
		end
	end
	return nil
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Create the beacon


function gadget:CommandFallback(unitID, unitDefID, teamID,    -- keeps getting
                                cmdID, cmdParams, cmdOptions) -- called until
	if cmdID == CMD_PLACE_BEACON and tele[unitID] then
		local f = Spring.GetGameFrame()
		--if not (tele[unitID].lastSetMove and tele[unitID].lastSetMove + 16 == f) then
		--	Spring.SetUnitMoveGoal(unitID, cmdParams[1], cmdParams[2], cmdParams[3], BEACON_PLACE_RANGE_MOVE)
		--end
		tele[unitID].lastSetMove = f
		
		local tx, ty, tz = Spring.GetUnitPosition(unitID)
		
		local ux,_,uz = Spring.GetUnitPosition(unitID)
		if ty == Spring.GetGroundHeight(tx, tz) then
			local cx, cz = math.floor((cmdParams[1]+8)/16)*16, math.floor((cmdParams[3]+8)/16)*16
			local inLos = Spring.IsPosInLos(cx,0,cz,Spring.GetUnitAllyTeam(unitID))
			
			local beaconX = Spring.GetUnitRulesParam(unitID, "tele_creating_beacon_x")
			local beaconZ = Spring.GetUnitRulesParam(unitID, "tele_creating_beacon_z")
			
			if cx == beaconX and cz == beaconZ then
				return true, false -- command was used but don't remove it
			end
			
			if (inLos) then --if LOS: check for obstacle
				local place, feature = Spring.TestBuildOrder(beaconDef, cx, 0, cz, 1)
				if not (place == 2 and feature == nil) then
					return true, true -- command was used and remove it
				end
			end
			
			local myBeacon = Spring.GetUnitsInRectangle(cx-1,cz-1,cx+1,cz+1,teamID)
			if #myBeacon > 0 then -- check if beacon is already in progress here
				return true, true -- command was used and remove it
			end
			
			local func = Spring.UnitScript.GetScriptEnv(unitID).Create_Beacon
			Spring.UnitScript.CallAsUnit(unitID,func,cx,cz)
			
			return true, false -- command was used but don't remove it
		end
		
		return true, false -- command was used but don't remove it
	end
	
	if cmdID == CMD_WAIT_AT_BEACON then
		local beaconID = cmdParams[1]

		if not beaconID
		or not beacon[beaconID]
		or not Spring.AreTeamsAllied(teamID, Spring.GetUnitTeam(beaconID))
		then
			-- don't remove command if we're in game load
			-- at this point the commands have been loaded but beacon table hasn't been regenerated
			return true, Spring.GetGameRulesParam("loadPurge") == 1
		end

		if not (beaconWaiter[unitID] and beaconWaiter[unitID].beaconID == beaconID) then
			local bx,by,bz = Spring.GetUnitPosition(beaconID)
			if bx then
				beaconWaiter[unitID] = {
					lastSetMove = false,
					beaconID = beaconID,
					frame = Spring.GetGameFrame(),
					bx = bx,
					by = by,
					bz = bz,
				}
			else
				beaconWaiter[unitID] = nil
				return true, true -- command was used and remove it
			end
		end

		local waitData = beaconWaiter[unitID]

		local f = Spring.GetGameFrame()
		if not ((beaconWaiter[unitID].lastSetMove and beaconWaiter[unitID].lastSetMove + 16 == f)) then
			Spring.SetUnitMoveGoal(unitID, waitData.bx, waitData.by, waitData.bz, BEACON_WAIT_RANGE_MOVE)
		end
		beaconWaiter[unitID].lastSetMove = f
	
		local ux,_,uz = Spring.GetUnitPosition(unitID)
		if BEACON_TELEPORT_RADIUS_SQR > (waitData.bx - ux)^2 + (waitData.bz - uz)^2 then
			if not beaconWaiter[unitID].waitingAtBeacon then
				Spring.SetUnitMoveGoal(unitID, ux, 0, uz)
				beaconWaiter[unitID].waitingAtBeacon = true
			end
		elseif teleportingUnit[unitID] then
			interruptTeleport(teleportingUnit[unitID])
		end
		
		return true, false -- command was used but don't remove it
	end
	
	return false
end

function gadget:GameFrame(f)
	-- kill orphaned beacons
	if #orphanedBeacons > 0 then
		for i = 1, #orphanedBeacons do
			Spring.DestroyUnit(orphanedBeacons[i], true)
		end
		orphanedBeacons = {}
	end
	
	-- progress teleport
	for i = 1, teleID.count do
		local tid = teleID.data[i]
		local bid = tele[tid].link
		if tele[tid].teleFrame then
			-- Cannont teleport if Teleporter or Beacon are disarmed, stunned or nanoframes and cannot teleport a nanoframe.
			local flying = isUnitFlying(tid)
			if flying then
				interruptTeleport(tid)
			else
				local stunned_or_inbuild = isUnitDisabled(tid) or isUnitDisabled(bid) or select(3, Spring.GetUnitIsStunned(tele[tid].teleportiee))
				if stunned_or_inbuild then
					tele[tid].teleFrame = tele[tid].teleFrame + 1
					Spring.SetUnitRulesParam(tid,"teleportend", tele[tid].teleFrame)
					Spring.SetUnitRulesParam(bid,"teleportend", tele[tid].teleFrame)
				elseif tele[tid].stunned then
					checkFrame[tele[tid].teleFrame] = true
					Spring.SetUnitRulesParam(tid,"teleportend",tele[tid].teleFrame)
					Spring.SetUnitRulesParam(bid,"teleportend",tele[tid].teleFrame)
				end
				tele[tid].stunned = stunned_or_inbuild
			end
		end
	end
	
	if f%16 == 0 or checkFrame[f] then
	
		if checkFrame[f] then
			checkFrame[f] = nil
		end
		
		for i = 1, teleID.count do
			local tid = teleID.data[i]
			local bid = tele[tid].link
			
			if bid and tele[tid].deployed then
				
				local teleFinished = tele[tid].teleFrame and f >= tele[tid].teleFrame
				
				-- complete teleport
				if teleFinished then
					local teleportiee = tele[tid].teleportiee
					local cmdID, _, cmdTag, cmdParam_1 = Spring.GetUnitCurrentCommand(teleportiee)
					if cmdID and cmdID == CMD_WAIT_AT_BEACON and cmdParam_1 == bid then
						local ud = Spring.GetUnitDefID(teleportiee)
						ud = ud and UnitDefs[ud]
						if ud then
							local size = ud.xsize
							local _,_,_,ux, uy, uz = Spring.GetUnitPosition(teleportiee, true)
							local _,_,_,tx, _, tz = Spring.GetUnitPosition(tid, true)
							local dx, dz = tx + offset[tele[tid].offsetIndex].x*(size*4+40), tz + offset[tele[tid].offsetIndex].z*(size*4+40)
							local dy
							
							if ud.floatOnWater or ud.canFly then
								dy = uy - math.max(0, Spring.GetGroundHeight(ux,uz)) +  math.max(0, Spring.GetGroundHeight(dx,dz))
							else
								dy = uy - Spring.GetGroundHeight(ux,uz) + Spring.GetGroundHeight(dx,dz)
							end
							
							GG.PlayFogHiddenSound("sounds/misc/teleport.wav", 10, ux, uy, uz)
							GG.PlayFogHiddenSound("sounds/misc/teleport2.wav", 10, dx, dy, dz)
							
							Spring.SpawnCEG("teleport_out", ux, uy, uz, 0, 0, 0, size)
							
							teleportingUnit[teleportiee] = nil
							tele[tid].teleportiee = nil
							Spring.SetUnitRulesParam(tid, "teleportiee", -1)
							
							if not callScript(teleportiee, "unit_teleported", {dx, dy, dz}) then
								Spring.SetUnitPosition(teleportiee, dx, dz)
								Spring.MoveCtrl.Enable(teleportiee)
								Spring.MoveCtrl.SetPosition(teleportiee, dx, dy, dz)
								Spring.MoveCtrl.Disable(teleportiee)
							end
							
							-- actual pos might not match nominal destination due to floating amphs
							local ax, ay, az = Spring.GetUnitPosition(teleportiee)
							Spring.SpawnCEG("teleport_in", ax, ay, az, 0, 0, 0, size)
							
							local mx, mz = tx + offset[tele[tid].offsetIndex].x*(size*4 + 120), tz + offset[tele[tid].offsetIndex].z*(size*4 + 120)
							GiveClampedMoveGoalToUnit(teleportiee, mx, mz)
							
							Spring.GiveOrderToUnit(teleportiee, CMD.WAIT, {}, 0)
							Spring.GiveOrderToUnit(teleportiee, CMD.WAIT, {}, 0)
							Spring.GiveOrderToUnit(teleportiee, CMD.REMOVE, {cmdTag}, 0)
						end
					end
					
					interruptTeleport(tid, true)
				end
				
				-- pick a unit to start teleporting
				if not tele[tid].teleFrame then
				
					local bx, bz = beacon[bid].x, beacon[bid].z
					local tx, _, tz = Spring.GetUnitPosition(tid)
					local units = Spring.GetUnitsInCylinder(bx, bz, BEACON_TELEPORT_RADIUS)
					local allyTeam = Spring.GetUnitAllyTeam(bid)
					
					local teleportiee = false
					local bestPriority = false
					local teleTarget = false
					
					for j = 1, #units do
						local nid = units[j]
						if allyTeam == Spring.GetUnitAllyTeam(nid) and beaconWaiter[nid] then
							local cmdID, _, _, cmdParam_1 = Spring.GetUnitCurrentCommand(nid)
							if cmdID and cmdID == CMD_WAIT_AT_BEACON and cmdParam_1 == bid then
								local priority = beaconWaiter[nid].frame
								if ((not bestPriority) or priority < bestPriority) then
									local ud = Spring.GetUnitDefID(nid)
									ud = ud and UnitDefs[ud]
									if ud then
										local spot = GetTeleTargetPos(ud, tx, tz)
										if spot then
											teleportiee = nid
											bestPriority = priority
											teleTarget = spot
										end
									end
								end
							end
						end
					end
					
					if teleportiee then
						local ud = Spring.GetUnitDefID(teleportiee)
						ud = ud and UnitDefs[ud]
						local flying = isUnitFlying(tid)
						if ud and not flying then

							local mass = Spring.GetUnitRulesParam(teleportiee, "massOverride") or ud.mass

							local cost = math.floor(mass/tele[tid].throughput)
							--Spring.Echo(cost/30)
							tele[tid].teleportiee = teleportiee
							Spring.SetUnitRulesParam(tid, "teleportiee", teleportiee)
							tele[tid].teleFrame = f + cost
							tele[tid].offsetIndex = teleTarget
							tele[tid].cost = cost
							
							Spring.SetUnitRulesParam(tid,"teleportcost",tele[tid].cost)
							Spring.SetUnitRulesParam(bid,"teleportcost",tele[tid].cost)
							
							Spring.SetUnitRulesParam(tid,"teleportend",tele[tid].teleFrame)
							Spring.SetUnitRulesParam(bid,"teleportend",tele[tid].teleFrame)
							
							checkFrame[tele[tid].teleFrame] = true
							teleportingUnit[teleportiee] = tid
							
							changeSpeed(tid, bid, 3)
							
							local func = Spring.UnitScript.GetScriptEnv(bid).startTeleOutLoop
							Spring.UnitScript.CallAsUnit(bid,func, teleportiee, tid)
						end
					else
						if teleFinished then
							changeSpeed(tid, bid, 2)
						end
					end
				end
			end
		end
	end

end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if UnitDefs[unitDefID].customParams.teleporter then
		Spring.InsertUnitCmdDesc(unitID, placeBeaconCmdDesc)
		Spring.SetUnitRulesParam(unitID, "teleportiee", -1)
		Spring.SetUnitRulesParam(unitID, "deploy", 0)
		teleID.count = teleID.count + 1
		teleID.data[teleID.count] = unitID
		tele[unitID] = {
			index = teleID.count,
			lastSetMove = false,
			link = false,
			teleportiee = false,
			teleFrame = false,
			offsetIndex = false,
			deployed = false,
			cost = false,
			stunned = isUnitDisabled(unitID),
			throughput = tonumber(UnitDefs[unitDefID].customParams.teleporter_throughput) / Game.gameSpeed,
		}
	end
	if canTeleport[unitDefID] then
		Spring.InsertUnitCmdDesc(unitID, waitAtBeaconCmdDesc)
	end
end

-- Tele automatically undeploy
function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	
	if beacon[unitID] then
		local _,_,_,_,_,oldA = Spring.GetTeamInfo(oldTeamID, false)
		local _,_,_,_,_,newA = Spring.GetTeamInfo(teamID, false)
		if newA ~= oldA then
			undeployTeleport(beacon[unitID].link)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

	if teleportingUnit[unitID] then
		interruptTeleport(teleportingUnit[unitID])
	end

	if tele[unitID] then
		local beaconID = tele[unitID].link
		if beaconID and Spring.ValidUnitID(beaconID) then
			orphanedBeacons[#orphanedBeacons + 1] = beaconID
			beacon[beaconID] = nil
		end
		tele[teleID.data[teleID.count]].index = tele[unitID].index
		teleID.data[tele[unitID].index] = teleID.data[teleID.count]
		teleID.data[teleID.count] = nil
		tele[unitID] = nil
		teleID.count = teleID.count - 1
	end
	if beacon[unitID] then
		undeployTeleport(beacon[unitID].link)
		tele[beacon[unitID].link].link = false
		interruptTeleport(beacon[unitID].link)
		beacon[unitID] = nil
	end

	beaconWaiter[unitID] = nil
end

function gadget:Initialize()
	GG.tele_ableToDeploy = tele_ableToDeploy
	GG.tele_deployTeleport = tele_deployTeleport
	GG.tele_undeployTeleport = tele_undeployTeleport
	GG.tele_createBeacon = tele_createBeacon
	
	GG.Teleport_AllowCommand = Teleport_AllowCommand

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local team = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save/Load

function gadget:Load(zip)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		-- reconnect beacons and Djinns, deploy Djinns
		local parentID = Spring.GetUnitRulesParam(unitID, "connectto")
		if parentID then
			parentID = GG.SaveLoad.GetNewUnitID(parentID)
			if parentID then
				local x,_,z = Spring.GetUnitPosition(unitID)
				tele_createBeacon(parentID, x, z, unitID)
				if Spring.GetUnitRulesParam(parentID, "deploy") == 1 then
					callScript(parentID, "DeployTeleportInstant")
				else
					callScript(parentID, "DeployTeleport")
				end
			end
		end
		
		-- restart beacon placement if it was in progress
		if Spring.GetUnitRulesParam(unitID, "tele_creating_beacon_x") then
			Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_x", nil)
			Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_z", nil)
		end
		
		-- load offset teleport end frame
		local teleportEnd = Spring.GetUnitRulesParam(unitID, "teleportend")
		if teleportEnd and teleportEnd > 0 then
			teleportEnd = teleportEnd - GG.SaveLoad.GetSavedGameFrame()
			Spring.SetUnitRulesParam(unitID, "teleportend", teleportEnd)
			if tele[unitID] then
				tele[unitID].teleFrame = teleportEnd
			end
		end
		
		-- load teleportiee with new ID and teleport destination
		local teleportieeOld = Spring.GetUnitRulesParam(unitID, "teleportiee")
		if teleportieeOld and teleportieeOld > 0 then
			local teleportiee = GG.SaveLoad.GetNewUnitID(teleportieeOld)
			if teleportiee and tele[unitID] then
				local udID = Spring.GetUnitDefID(teleportiee)
				local ud = UnitDefs[udID]
				local tx, ty, tz = Spring.GetUnitPosition(unitID)
				-- pick a new teleport destination
				local teleTarget = GetTeleTargetPos(ud, tx, tz)
				if teleTarget then
					tele[unitID].teleportiee = teleportiee
					tele[unitID].offsetIndex = teleTarget
					Spring.SetUnitRulesParam(unitID, "teleportiee", teleportiee)
				else
					Spring.SetUnitRulesParam(unitID, "teleportiee", -1)
				end
			else
				Spring.SetUnitRulesParam(unitID, "teleportiee", -1)
			end
		end
	end
end

else
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local glVertex           = gl.Vertex
local spIsUnitInView     = Spring.IsUnitInView
local spGetUnitPosition  = Spring.GetUnitPosition
local spGetUnitLosState  = Spring.GetUnitLosState
local spValidUnitID      = Spring.ValidUnitID
local spGetMyTeamID      = Spring.GetMyTeamID
local spGetMyAllyTeamID  = Spring.GetMyAllyTeamID
local spGetModKeyState   = Spring.GetModKeyState
local spAreTeamsAllied   = Spring.AreTeamsAllied
local spGetUnitVectors   = Spring.GetUnitVectors
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitTeam      = Spring.GetUnitTeam
local spGetLocalTeamID   = Spring.GetLocalTeamID

local myTeam = spGetMyTeamID()
local myAllyTeam = spGetMyAllyTeamID()

local beaconDef = UnitDefNames["tele_beacon"].id
local beacons = {}
local beaconCount = 0

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_PLACE_BEACON)
	gadgetHandler:RegisterCMDID(CMD_WAIT_AT_BEACON)
	
	Spring.AssignMouseCursor("Beacon", "cursorunload", true)
	Spring.AssignMouseCursor("Beacon Queue", "cursorpickup", true)
	Spring.SetCustomCommandDrawData(CMD_PLACE_BEACON, "Beacon", {0.2, 0.8, 0, 0.7})
	Spring.SetCustomCommandDrawData(CMD_WAIT_AT_BEACON, "Beacon Queue", {0.1, 0.1, 1, 0.7})
end

function gadget:DefaultCommand(type, targetID)
	if (type == 'unit') and beaconDef == spGetUnitDefID(targetID) then
		local targetTeam = spGetUnitTeam(targetID)
		local selfTeam = spGetLocalTeamID()
		if not (spAreTeamsAllied(targetTeam, selfTeam)) then
			return
		end

		local selUnits = spGetSelectedUnits()
		if (not selUnits[1]) then
			return
		end

		local unitID, unitDefID
		for i = 1, #selUnits do
			unitID    = selUnits[i]
			unitDefID = spGetUnitDefID(unitID)
			if canTeleport[unitDefID] then
				return CMD_WAIT_AT_BEACON
			end
		end
	end
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

local function DrawWire(spec)
	for i=1, beaconCount do
		local bid = beacons[i]
		local tid = Spring.GetUnitRulesParam(bid, "connectto")

		if tid and (Spring.GetUnitRulesParam(tid, "deploy") == 1) then
			local point = {nil, nil, nil, nil}
			local teleportiee = Spring.GetUnitRulesParam(tid, "teleportiee")
			if (teleportiee >= 0) and spValidUnitID(teleportiee) and spValidUnitID(bid) then
				local los1 = spGetUnitLosState(teleportiee, myAllyTeam, false)
				local los2 = spGetUnitLosState(bid, myAllyTeam, false)
				if (spec or (los1 and los1.los) or (los2 and los2.los)) and (spIsUnitInView(teleportiee) or spIsUnitInView(bid)) then
					local _,_,_,xxx,yyy,zzz = Spring.GetUnitPosition(bid, true)
					local topX, topY, topZ = GetUnitTop(bid, xxx, yyy, zzz)
					point[1] = {xxx, yyy, zzz}
					point[2] = {topX, topY, topZ}
					_,_,_,xxx,yyy,zzz = Spring.GetUnitPosition(teleportiee, true)
					topX, topY, topZ = GetUnitTop(teleportiee, xxx, yyy, zzz)
					point[3] = {topX,topY,topZ}
					point[4] = {xxx,yyy,zzz}
					gl.PushAttrib(GL.LINE_BITS)
					gl.DepthTest(true)
					gl.Color (0, 0.75, 1, math.random()*0.3+0.2)
					gl.LineWidth(3)
					gl.BeginEnd(GL.LINE_STRIP, DrawBezierCurve, point[1], point[2], point[3], point[4], 10)
					gl.DepthTest(false)
					gl.Color (1,1,1,1)
					gl.PopAttrib()
				end
			end
		end
	end
end

local function DrawFunc(u1, u2)
	local _,_,_,x1,y1,z1 = spGetUnitPosition(u1,true)
	local _,_,_,x2,y2,z2 = spGetUnitPosition(u2,true)
	glVertex(x1,y1,z1)
	glVertex(x2,y2,z2)
end

function gadget:UnitCreated(unitID, unitDefID)
	if (unitDefID == beaconDef) then
		beacons[beaconCount + 1] = unitID
		beaconCount = beaconCount + 1
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if (unitDefID == beaconDef) then
		for i=1, #beacons do
			if beacons[i] == unitID then
				beacons[i] = beacons[beaconCount]
				beaconCount = beaconCount - 1
				table.remove(beacons)
				break;
			end
		end
	end
end

local function DrawWorldFunc()
	if beaconCount > 0 then
		local _, fullview = Spring.GetSpectatingState()

		DrawWire(fullview)
		
		local shift = select (4, spGetModKeyState())
		local drawnSomethingYet = false
		for i = 1, beaconCount do
			local bid = beacons[i]
			local tid = Spring.GetUnitRulesParam(bid, "connectto")
			if tid then
				local team = Spring.GetUnitTeam(tid)
				if spValidUnitID(tid) and spValidUnitID(bid) and (fullview or spAreTeamsAllied(myTeam, team)) and (shift or (Spring.IsUnitSelected(tid) or Spring.IsUnitSelected(bid))) then
					
					if not drawnSomethingYet then
						gl.PushAttrib(GL.LINE_BITS)
			
						gl.DepthTest(true)
						
						gl.LineWidth(2)
						gl.LineStipple('')
						drawnSomethingYet = true
					end
					
					gl.Color(0.1, 0.3, 1, 0.9)
					gl.BeginEnd(GL.LINES, DrawFunc, bid, tid)
					
					local x,y,z = spGetUnitPosition(bid)
					
					gl.DrawGroundCircle(x,y,z, BEACON_TELEPORT_RADIUS, 32)
				end
			end
		end

		if drawnSomethingYet then
			gl.DepthTest(false)
			gl.Color(1,1,1,1)
			gl.LineStipple(false)
			
			gl.PopAttrib()
		end
	end
end

function gadget:DrawWorld()
	DrawWorldFunc()
end
function gadget:DrawWorldRefraction()
	DrawWorldFunc()
end


end
