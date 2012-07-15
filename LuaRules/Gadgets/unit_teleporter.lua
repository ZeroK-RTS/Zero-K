
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

local BEACON_PLACE_RANGE_SQR = 80000^2
local BEACON_PLACE_RANGE_MOVE = 75000
local BEACON_WAIT_RANGE_MOVE = 150
local BEACON_TELEPORT_RADIUS = 200
local BEACON_TELEPORT_RADIUS_SQR = BEACON_TELEPORT_RADIUS^2

if (gadgetHandler:IsSyncedCode()) then

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

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
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local teleDef = {
	[UnitDefNames["amphtele"].id] = true,
}

local beaconDef = UnitDefNames["tele_beacon"].id

-- frames to teleport = unit mass * COST_FACTOR
local COST_FACTOR = 0.8

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

local teleID = {count = 0, data = {}}
local tele = {}
local beacon = {}

local beaconWaiter = {}
local teleportingUnit = {}

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
	local func = Spring.UnitScript.GetScriptEnv(tid).activity_mode
	Spring.UnitScript.CallAsUnit(tid,func,speed)
	if bid then
		local func = Spring.UnitScript.GetScriptEnv(bid).activity_mode
		Spring.UnitScript.CallAsUnit(bid,func,speed)
	end
end

local function interruptTeleport(unitID, doNotChangeSpeed)
	if tele[unitID].teleportiee then
		teleportingUnit[tele[unitID].teleportiee] = nil
	end
	tele[unitID].teleFrame = false
	tele[unitID].cost = false
	
	Spring.SetUnitRulesParam(unitID,"teleportend",0)

	if tele[unitID].link then
		local func = Spring.UnitScript.GetScriptEnv(tele[unitID].link).endTeleOutLoop
		Spring.UnitScript.CallAsUnit(tele[unitID].link,func)
		Spring.SetUnitRulesParam(tele[unitID].link,"teleportend",0)
	end

	if not doNotChangeSpeed and tele[unitID].deployed then
		changeSpeed(unitID, tele[unitID].link, 2)
	end
end

function GG.tele_ableToDeploy(unitID)
	return tele[unitID].link and not tele[unitID].deployed
end

function GG.tele_deployTeleport(unitID)
	tele[unitID].deployed = true
	checkFrame[Spring.GetGameFrame() + 1] = true
	
	changeSpeed(unitID, tele[unitID].link, 2)
end

function GG.tele_undeployTeleport(unitID)
	if tele[unitID].deployed then
		interruptTeleport(unitID)
	end
	tele[unitID].deployed = false	
	changeSpeed(unitID, tele[unitID].link, 1)
end

function GG.tele_createBeacon(unitID,x,z)
	local y = Spring.GetGroundHeight(x,z)
	local place, feature = Spring.TestBuildOrder(beaconDef, x, y, z, 1)
	changeSpeed(unitID, nil, 1)
	if place == 2 and feature == nil then
		if tele[unitID].link and Spring.ValidUnitID(tele[unitID].link) then
			Spring.DestroyUnit(tele[unitID].link, true)
		end
		Spring.PlaySoundFile("sounds/misc/teleport2.wav", 10, x, Spring.GetGroundHeight(x,z) or 0, z)
		local beaconID = Spring.CreateUnit(beaconDef, x, y, z, 1, Spring.GetUnitTeam(unitID))
		Spring.SetUnitPosition(beaconID, x, y, z)
		tele[unitID].link = beaconID
		beacon[beaconID] = {link = unitID, x = x, z = z}
	end
	Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, {})
	Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, {})
end

local function undeployTeleport(unitID)
	if tele[unitID].deployed then 
		local func = Spring.UnitScript.GetScriptEnv(unitID).UndeployTeleport
		Spring.UnitScript.CallAsUnit(unitID,func)
		GG.tele_undeployTeleport(unitID)
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Handle Teleportation

function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOptions)
	
	if teleportingUnit[unitID] and cmdID ~= 1 and cmdID ~= 2 and cmdID ~= CMD.FIRESTATE and cmdID ~= CMD.MOVESTATE and cmdID ~= CMD.CLOAK then
		interruptTeleport(teleportingUnit[unitID])
	end
	
	local ud = UnitDefs[unitDefID]
	
	if   not ud 
	  or
	    (ud.speed == 0 or ud.isBomber or ud.isFighter) 
      or
	    not (
		  (cmdID == CMD.GUARD and cmdParams[1] and beacon[cmdParams[1]])
		or 
		  (cmdID == CMD.INSERT and cmdParams[2] == CMD.GUARD and beacon[cmdParams[4]])
		) then
		return true
	end
	
	local bid = (cmdID == CMD.INSERT and cmdParams[4]) or cmdParams[1]
	
	if Spring.GetUnitAllyTeam(unitID) ~= Spring.GetUnitAllyTeam(bid) then
		return false
	end
	
	-- NOTE: param 4 is the first real command param for command insert
	beaconWaiter[unitID] = {lastSetMove = false,}
	local bx,by,bz = Spring.GetUnitPosition(bid)
	local params = {bx, by, bz, bid, Spring.GetGameFrame()}
	
	if cmdID == CMD.INSERT then
		Spring.GiveOrderToUnit(unitID,CMD.INSERT,{cmdParams[1],CMD_WAIT_AT_BEACON,cmdParams[3], unpack(params)}, {"alt"})
	else
		local opt = (cmdOptions.shift and {"shift"}) or {}
		Spring.GiveOrderToUnit(unitID,CMD_WAIT_AT_BEACON, params, opt)
	end
	
	return false
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Create the beacon


function gadget:CommandFallback(unitID, unitDefID, teamID,    -- keeps getting 
                                cmdID, cmdParams, cmdOptions) -- called until
	
	if cmdID == CMD_PLACE_BEACON and tele[unitID] then
		local f = Spring.GetGameFrame()
		if not (tele[unitID].lastSetMove and tele[unitID].lastSetMove + 16 == f) then
			Spring.SetUnitMoveGoal(unitID, cmdParams[1], cmdParams[2], cmdParams[3], BEACON_PLACE_RANGE_MOVE)
		end
		tele[unitID].lastSetMove = f
		
		local tx, ty, tz = Spring.GetUnitBasePosition(unitID)
		
		local ux,_,uz = Spring.GetUnitPosition(unitID)
		if BEACON_PLACE_RANGE_SQR > (cmdParams[1]-ux)^2 + (cmdParams[3]-uz)^2 and ty == Spring.GetGroundHeight(tx, tz) then
			local cx, cz = math.floor((cmdParams[1]+8)/16)*16, math.floor((cmdParams[3]+8)/16)*16
			Spring.SetUnitMoveGoal(unitID, ux,0,uz)
			--local place, feature = Spring.TestBuildOrder(beaconDef, cx, 0 ,cz, 1)
			--local inLos = Spring.IsPosInLos(cx,0,cz,Spring.GetUnitAllyTeam(unitID))
			--if (place == 2 and feature == nil) or not inLos then
				Spring.MoveCtrl.Enable(unitID)
				Spring.SetUnitVelocity(unitID, 0, 0, 0)
				local func = Spring.UnitScript.GetScriptEnv(unitID).Create_Beacon
				Spring.UnitScript.CallAsUnit(unitID,func,cx,cz)
			--end
			return true, true -- command was used and remove it
		end
		
		return true, false -- command was used but don't remove it
	end
	
	if cmdID == CMD_WAIT_AT_BEACON and beaconWaiter[unitID] then
		
		local ud = UnitDefs[UnitDefID]
		
		if ud and ((not beacon[cmdParams[4]]) or ud.speed == 0 or ud.isBomber or ud.isFighter) then
			return true, true -- command was used and remove it
		end
		
		local f = Spring.GetGameFrame()
		if not ((beaconWaiter[unitID].lastSetMove and beaconWaiter[unitID].lastSetMove + 16 == f)) then
			Spring.SetUnitMoveGoal(unitID, cmdParams[1], cmdParams[2], cmdParams[3], BEACON_WAIT_RANGE_MOVE)
		end
		beaconWaiter[unitID].lastSetMove = f
	
		local ux,_,uz = Spring.GetUnitPosition(unitID)
		if BEACON_TELEPORT_RADIUS_SQR > (cmdParams[1]-ux)^2 + (cmdParams[3]-uz)^2 then
			
			if not beaconWaiter[unitID].waitingAtBeacon then
				Spring.SetUnitMoveGoal(unitID, ux,0,uz)
				beaconWaiter[unitID].waitingAtBeacon = true
			end
			
			--local bid = cmdParams[4]
			--local tid = beacon[bid].link
			--nearBeacon[bid] = true
		elseif teleportingUnit[unitID] then
			interruptTeleport(teleportingUnit[unitID])
		end
		
		return true, false -- command was used but don't remove it
	end
	
	return false
end

function gadget:GameFrame(f)
	
	for i = 1, teleID.count do
		local tid = teleID.data[i]	
		local bid = tele[tid].link
		if tele[tid].teleFrame then
			local stunned_or_inbuild = Spring.GetUnitIsStunned(tid) or Spring.GetUnitIsStunned(bid)
			if stunned_or_inbuild then
				if not tele[tid].stunned then
					tele[tid].stunned = true
					
					Spring.SetUnitRulesParam(tid,"teleportend",tele[tid].teleFrame - f)
					Spring.SetUnitRulesParam(bid,"teleportend",tele[tid].teleFrame - f)
				end
			
				tele[tid].teleFrame = tele[tid].teleFrame + 1
			elseif tele[tid].stunned then
				checkFrame[tele[tid].teleFrame] = true
				
				Spring.SetUnitRulesParam(tid,"teleportend",tele[tid].teleFrame)
				Spring.SetUnitRulesParam(bid,"teleportend",tele[tid].teleFrame)
				
				tele[tid].stunned = false
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
			
				if teleFinished then
					
					local teleportiee = tele[tid].teleportiee
					
					local cQueue = Spring.GetCommandQueue(teleportiee, 1)
					if cQueue and #cQueue > 0 and cQueue[1].id == CMD_WAIT_AT_BEACON and cQueue[1].params[4] == bid then
						local ud = Spring.GetUnitDefID(teleportiee)
						ud = ud and UnitDefs[ud]
						if ud then
							local size = ud.xsize
							local ux,uy,uz = Spring.GetUnitPosition(teleportiee)		
							local tx, _, tz = Spring.GetUnitPosition(tid)
							local dx, dz = tx + offset[tele[tid].offsetIndex].x*(size*4+40), tz + offset[tele[tid].offsetIndex].z*(size*4+40)
							local dy 
							
							if ud.floater or ud.canFly then
								dy = uy - math.max(0, Spring.GetGroundHeight(ux,uz)) +  math.max(0, Spring.GetGroundHeight(dx,dz))
							else
								dy = uy - Spring.GetGroundHeight(ux,uz) + Spring.GetGroundHeight(dx,dz)
							end
							
							Spring.PlaySoundFile("sounds/misc/teleport.wav", 10, ux, uy, uz)
							Spring.PlaySoundFile("sounds/misc/teleport2.wav", 10, dx, dy, dz)
							
							Spring.SpawnCEG("teleport_out", ux, uy, uz, 0, 0, 0, size)
							
							
							teleportingUnit[teleportiee] = false
							
							if not callScript(teleportiee, "unit_teleported", {dx, dy, dz}) then
								Spring.SetUnitPosition(teleportiee, dx, dz)
								Spring.MoveCtrl.Enable(teleportiee)
								Spring.MoveCtrl.SetPosition(teleportiee, dx, dy, dz)
								Spring.MoveCtrl.Disable(teleportiee)
							end
							
							local ux, uy, uz = Spring.GetUnitPosition(teleportiee)
							Spring.SpawnCEG("teleport_in", ux, uy, uz, 0, 0, 0, size)
							
							Spring.SetUnitMoveGoal(teleportiee, dx,0,dz)
							
							Spring.GiveOrderToUnit(teleportiee,CMD.REMOVE, {cQueue[1].tag}, {})
							
							Spring.GiveOrderToUnit(teleportiee,CMD.WAIT, {}, {})
							Spring.GiveOrderToUnit(teleportiee,CMD.WAIT, {}, {})
						end
					end
					
					interruptTeleport(tid, true)
				end
			
				if not tele[tid].teleFrame then
				
					local bx, bz = beacon[bid].x, beacon[bid].z
					local tx, _, tz = Spring.GetUnitPosition(tid)
					local units = Spring.GetUnitsInCylinder(bx, bz, BEACON_TELEPORT_RADIUS)
					local allyTeam = Spring.GetUnitAllyTeam(bid)
					
					local teleportiee = false
					local bestPriority = false
					local teleTarget = false
					
					for i = 1, #units do
						local nid = units[i]
						if allyTeam == Spring.GetUnitAllyTeam(nid) then
							local cQueue = Spring.GetCommandQueue(nid, 1)
							if #cQueue > 0 and cQueue[1].id == CMD_WAIT_AT_BEACON and cQueue[1].params[4] == bid and 
									((not bestPriority) or cQueue[1].params[5] < bestPriority) then
								local ud = Spring.GetUnitDefID(nid)
								ud = ud and UnitDefs[ud]
								if ud then
									local size = ud.xsize
									local startCheck = math.floor(math.random(8))
									local direction = (math.random() < 0.5 and -1) or 1
									for j = 0, 7 do
										local spot = (j*direction+startCheck)%8
										local place, feature = Spring.TestBuildOrder(ud.id, tx + offset[spot].x*(size*4+40), 0 ,tz + offset[spot].z*(size*4+40), 1)
										if (place == 2 and feature == nil) or ud.canFly then
											teleportiee = nid
											bestPriority = cQueue[1].params[5]
											teleTarget = spot
											break
										end
									end
								end
							end
						end
					end
					
					if teleportiee then
						local ud = Spring.GetUnitDefID(teleportiee)
						ud = ud and UnitDefs[ud]
						if ud then
							local cost = math.floor(ud.mass*COST_FACTOR + math.random())
							--Spring.Echo(cost/30)
							tele[tid].teleportiee = teleportiee
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
	if teleDef[unitDefID] then
		Spring.InsertUnitCmdDesc(unitID, placeBeaconCmdDesc)
		
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
			stunned = Spring.GetUnitIsStunned(unitID),
		}
	end
end

-- Tele automatically undeploy
function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	
	if beacon[unitID] then
		local _,_,_,_,_,oldA = Spring.GetTeamInfo(oldTeamID)
		local _,_,_,_,_,newA = Spring.GetTeamInfo(teamID)
		if newA ~= oldA then
			undeployTeleport(beacon[unitID].link)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	
	if teleportingUnit[teleportiee] then
		interruptTeleport(teleportingUnit[teleportiee])
	end
	
	if tele[unitID] then
		if tele[unitID].link and Spring.ValidUnitID(tele[unitID].link) then
			Spring.DestroyUnit(tele[unitID].link, true)
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
end

function gadget:Initialize()
	_G.tele = tele

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local team = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
	end
end


else
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_PLACE_BEACON)
	gadgetHandler:RegisterCMDID(CMD_WAIT_AT_BEACON)
	
	Spring.AssignMouseCursor("Beacon", "cursorunload", true)
	Spring.AssignMouseCursor("Beacon Queue", "cursorpickup", true)
	Spring.SetCustomCommandDrawData(CMD_PLACE_BEACON, "Beacon", {0.2, 0.8, 0, 1})
	Spring.SetCustomCommandDrawData(CMD_WAIT_AT_BEACON, "Beacon Queue", {0.1, 0.1, 1, 1})
end


local glVertex 				= gl.Vertex
local spIsUnitInView 		= Spring.IsUnitInView
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitLosState 	= Spring.GetUnitLosState
local spValidUnitID 		= Spring.ValidUnitID
local spGetMyAllyTeamID 	= Spring.GetMyAllyTeamID 	
local spGetModKeyState      = Spring.GetModKeyState

local myTeam = spGetMyAllyTeamID()

local function DrawFunc(u1, u2)
	glVertex(spGetUnitPosition(u1))
	glVertex(spGetUnitPosition(u2))
end

function gadget:DrawWorld()

	local spec, fullview = Spring.GetSpectatingState()
	spec = spec or fullview

	if SYNCED.tele and snext(SYNCED.tele) then
		gl.PushAttrib(GL.LINE_BITS)
		
		gl.DepthTest(true)
		
		gl.LineWidth(2)
        gl.LineStipple('')
		local tele = SYNCED.tele
		local alt,ctrl,meta,shift = spGetModKeyState()
		for tid, data in spairs(tele) do
			local bid = data.link
			if spValidUnitID(tid) and spValidUnitID(bid) and (shift or (Spring.IsUnitSelected(tid) or Spring.IsUnitSelected(bid))) then
				
				gl.Color(0.1, 0.3, 1, 0.9)
				gl.BeginEnd(GL.LINES, DrawFunc, bid, tid)
				
				local x,y,z = spGetUnitPosition(bid)
				
				gl.DrawGroundCircle(x,y,z, BEACON_TELEPORT_RADIUS, 32)
			end
	
		end
		
		gl.DepthTest(false)
		gl.Color(1,1,1,1)
                gl.LineStipple(false)
		
		gl.PopAttrib()
	end
	
end


end