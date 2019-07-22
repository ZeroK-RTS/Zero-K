
function widget:GetInfo()
	return {
		name      = "Ferry Points",
		desc      = "Allow the creation of ferry routes for transports. Move transports and units to route entrance to assign them to the ferry route.",
		author    = "Google Frog",
		date      = "24 Nov 2010",
		license   = "GNU GPL, v2 or later",
		handler   = true,
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local spSetActiveCommand = Spring.SetActiveCommand

local COLLECTION_RADIUS_DRAW         = 120
local COLLECTION_RADIUS              = 150
local NEAR_WAYPOINT_RANGE_SQ         = 200^2
local NEAR_START_RANGE_SQ            = 300^2
local CONST_UNLOAD_RADIUS            = 100
local CANT_BE_TRANSPORTED_DECAY_TIME = 200
local COMMAND_MOVE_RADIUS            = 80

VFS.Include("LuaRules/Configs/customcmds.h.lua")
local CMD_FIGHT                = CMD.FIGHT
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED or 70

--VFS.Include("LuaRules/Utilities/ClampPosition.lua")
--local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local ferryRoutes = {count = 0, route = {}}

local placedRoute = false
local myTeam = Spring.GetMyTeamID()

local movingPoint = false
local movingPointNeighbours = false

local toBeWaited = {count = 0, unit = {}}

local wasTransported = {count = 0, unit = {}}

local transportDefs = {
	[UnitDefNames["gunshiptrans"].id] = true,
	[UnitDefNames["gunshipheavytrans"].id] = true,
}

local transport = {}
local transportIndex = {count = 0, unit = {}}

WG.FerryUnits = {}

local EMPTY_TABLE = {}

-------------------------------------------------------------------
-------------------------------------------------------------------
--- ROUTE HANDLING

local function disSQ(x1,y1,x2,y2)
	return (x1-x2)^2 + (y1-y2)^2
end

local function nearFerryPoint(x, z, r)
	local rsq = r^2
	
	for i = 1, ferryRoutes.count do
		if disSQ(x, z, ferryRoutes.route[i].start.x, ferryRoutes.route[i].start.z) < rsq then
			return i
		end
	end
	
	return false
end

local function nearAnyPoint(x, z, r)
	local rsq = r^2
	
	for i = 1, ferryRoutes.count do
		if disSQ(x, z, ferryRoutes.route[i].start.x, ferryRoutes.route[i].start.z) < rsq then
			return {r = i, index = 0}
		end
		for p = 1, ferryRoutes.route[i].pointcount do
			if disSQ(x, z, ferryRoutes.route[i].points[p].x, ferryRoutes.route[i].points[p].z) < rsq then
				return {r = i, index = p}
			end
		end
		if disSQ(x, z, ferryRoutes.route[i].finish.x, ferryRoutes.route[i].finish.z) < rsq then
			return {r = i, index = ferryRoutes.route[i].pointcount+1}
		end
	end
	
	return false
end

-- removes transport from whichever route it is part of
local function removeTransportFromRoute(unitID)
	local trans = transport[unitID]

	if not (trans and trans.route) then
		return
	end
	
	local route = ferryRoutes.route[trans.route]
	
	route.unitsQueuedToBeTransported = {} -- clear because this transporter may have been queued to transport
	
	route.transporters[trans.routeTransportIndex] = route.transporters[route.transportCount]
	transport[route.transporters[trans.routeTransportIndex]].routeTransportIndex = trans.routeTransportIndex
	route.transportCount = route.transportCount - 1
	
	trans.route = false
	trans.routeTransportIndex = false
	trans.waypoint = 0
	
	WG.FerryUnits[unitID] = false
end

-- it is assumed that the transport is not part of a route
local function addTransportToRoute(unitID, routeID)
	local trans = transport[unitID]
	local route = ferryRoutes.route[routeID]
	
	route.transportCount = route.transportCount + 1
	route.transporters[route.transportCount] = unitID
	
	trans.route = routeID
	trans.routeTransportIndex = route.transportCount
	
	WG.FerryUnits[unitID] = true
end

local function removeRoute(routeID)
	local route = ferryRoutes.route[routeID]
	
	for i = 1, route.transportCount do
		transport[route.transporters[i]].route = false
		transport[route.transporters[i]].routeTransportIndex = false
		transport[route.transporters[i]].waypoint = 0
		
		WG.FerryUnits[route.transporters[i]] = false
	end
	
	ferryRoutes.route[routeID] = ferryRoutes.route[ferryRoutes.count]
	ferryRoutes.route[ferryRoutes.count] = nil
	ferryRoutes.count = ferryRoutes.count - 1
	
	local route = ferryRoutes.route[routeID]
	if route then
		for i = 1, route.transportCount do
			transport[route.transporters[i]].route = routeID
		end
	end
end

-------------------------------------------------------------------
-------------------------------------------------------------------
--- COMMAND HANDLING

local function GiveUnloadOrder(transportID, x, y, z)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x - 2, y, z - 2}, CMD.OPT_RIGHT)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x + 2, y, z + 2, CONST_UNLOAD_RADIUS}, CMD.OPT_SHIFT)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x - 2, y, z + 2, CONST_UNLOAD_RADIUS*2}, CMD.OPT_SHIFT)
	spGiveOrderToUnit(transportID, CMD.UNLOAD_UNIT, {x + 2, y, z - 2, CONST_UNLOAD_RADIUS*4}, CMD.OPT_SHIFT)
end

function widget:CommandsChanged()
	local customCommands = widgetHandler.customCommands

	customCommands[#customCommands+1] = {
		id      = CMD_SET_FERRY,
		type    = CMDTYPE.ICON_MAP,
		tooltip = 'Places a ferry route',
		cursor  = 'Repair',
		action  = 'setferry',
		params  = { }, 
		texture = 'LuaUI/Images/commands/Bold/ferry.png',

		pos = {CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT}, 
	}
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SET_WANTED_MAX_SPEED then
		return false
	end
	
	if cmdID == CMD_SET_FERRY then
		if movingPoint then
			local route = ferryRoutes.route[movingPoint.r]
			if movingPoint.index == 0 then
				route.start = {x = cmdParams[1], y = cmdParams[2], z = cmdParams[3]}
				for i = 1, route.transportCount do
					local trans = transport[route.transporters[i]]
					if trans.waypoint == 0 then
						Spring.GiveOrderToUnit(route.transporters[i], CMD.MOVE, 
							{route.start.x, route.start.y, route.start.z}, 0 )
					end
				end
			elseif movingPoint.index <= ferryRoutes.route[movingPoint.r].pointcount then
				route.points[movingPoint.index] = {x = cmdParams[1], y = cmdParams[2], z = cmdParams[3]}
				for i = 1, route.transportCount do
					local trans = transport[route.transporters[i]]
					if trans.waypoint == movingPoint.index then
						Spring.GiveOrderToUnit(route.transporters[i], CMD.MOVE, 
							{route.points[movingPoint.index].x, route.points[movingPoint.index].y, route.points[movingPoint.index].z}, 0 )
					end
				end
			else
				route.finish = {x = cmdParams[1], y = cmdParams[2], z = cmdParams[3]}
				for i = 1, route.transportCount do
					local trans = transport[route.transporters[i]]
					if trans.waypoint > route.pointcount then
						GiveUnloadOrder(route.transporters[i], route.finish.x, route.finish.y, route.finish.z)
					end
				end
			end
			movingPointNeighbours = false
			movingPoint = false
		elseif not placedRoute then
			if cmdOptions.shift then
				movingPoint = nearAnyPoint(cmdParams[1], cmdParams[3], COMMAND_MOVE_RADIUS)
				if movingPoint then
					movingPointNeighbours = {}
					if movingPoint.index == 0 then
						if ferryRoutes.route[movingPoint.r].pointcount == 0 then
							movingPointNeighbours[1] = ferryRoutes.route[movingPoint.r].finish
						else
							movingPointNeighbours[1] = ferryRoutes.route[movingPoint.r].points[1]
						end
					elseif movingPoint.index <= ferryRoutes.route[movingPoint.r].pointcount then
						if movingPoint.index == ferryRoutes.route[movingPoint.r].pointcount then
							movingPointNeighbours[1] = ferryRoutes.route[movingPoint.r].finish
						else
							movingPointNeighbours[1] = ferryRoutes.route[movingPoint.r].points[movingPoint.index+1]
						end
						if movingPoint.index == 1 then
							movingPointNeighbours[2] = ferryRoutes.route[movingPoint.r].start
						else
							movingPointNeighbours[2] = ferryRoutes.route[movingPoint.r].points[movingPoint.index-1]
						end
					else
						if ferryRoutes.route[movingPoint.r].pointcount == 0 then
							movingPointNeighbours[1] = ferryRoutes.route[movingPoint.r].start
						else
							movingPointNeighbours[1] = ferryRoutes.route[movingPoint.r].points[ferryRoutes.route[movingPoint.r].pointcount]
						end
					end
					return true
				end
			end
			
			local pointHere = nearFerryPoint(cmdParams[1], cmdParams[3], COLLECTION_RADIUS_DRAW)
			if pointHere then
				removeRoute(pointHere)
			else
				placedRoute = {
					start = {
						x = cmdParams[1],
						y = cmdParams[2],
						z = cmdParams[3],
					},
					pointcount = 0,
					points = {},
					finish = false,
					transporters = {},
					transportCount = 0,
					unitsQueuedToBeTransported = {},
				}
			end
		else
			if cmdOptions.shift then
				placedRoute.pointcount = placedRoute.pointcount + 1
				placedRoute.points[placedRoute.pointcount] = {
					x = cmdParams[1],
					y = cmdParams[2],
					z = cmdParams[3],
				}
			else
				placedRoute.finish = {
					x = cmdParams[1],
					y = cmdParams[2],
					z = cmdParams[3],
				}
				ferryRoutes.count = ferryRoutes.count + 1
				ferryRoutes.route[ferryRoutes.count] = placedRoute
				placedRoute = false
			end
		end
		
		return true
	elseif (cmdID == CMD_RAW_MOVE or cmdID == CMD.MOVE or cmdID == CMD_FIGHT) and cmdParams then
		local routeID = nearFerryPoint(cmdParams[1], cmdParams[3], COLLECTION_RADIUS_DRAW)
		if routeID then
			local selected = Spring.GetSelectedUnits()
			local count = #selected
			for i = 1, count do
				if transport[selected[i]] then
					removeTransportFromRoute(selected[i])
					addTransportToRoute(selected[i], routeID)
				else
					local unitDefID = Spring.GetUnitDefID(selected[i])
					local ud = UnitDefs[unitDefID]
					if (not ud.cantBeTransported) or ud.isFactory then
						toBeWaited.count = toBeWaited.count + 1
						toBeWaited.unit[toBeWaited.count] = selected[i]
					end
				end
			end
			return false
		end
	elseif cmdID == CMD.LOAD_ONTO and transport[cmdParams[1]] and transport[cmdParams[1]].route then
		removeTransportFromRoute(cmdParams[1])
	end
	
	local selected = Spring.GetSelectedUnits()
	local count = #selected
	for i = 1, count do
		if transport[selected[i]] then
			removeTransportFromRoute(selected[i])
		end
	end
end

function widget:MousePress(mx, my, button)
	if placedRoute and button == 3 then
		placedRoute = false
	end
end

--function widget:MouseMove(x,y,dx,dy,button)
	--Spring.Echo(x)
--end

function widget:Update()
	if (placedRoute or movingPoint) and Spring.GetActiveCommand() ~= Spring.GetCmdDescIndex(CMD_SET_FERRY) then
		Spring.SetActiveCommand(Spring.GetCmdDescIndex(CMD_SET_FERRY))
	end
	
	if toBeWaited.count ~= 0 then
		for i = 1, toBeWaited.count do
			Spring.GiveOrderToUnit(toBeWaited.unit[i], CMD.WAIT, EMPTY_TABLE, CMD.OPT_SHIFT)
		end
		toBeWaited.count = 0
		toBeWaited.unit = {}
	end	
end

-------------------------------------------------------------------
-------------------------------------------------------------------
--- UNIT HANDLING

function widget:UnitUnloaded(unitID, unitDefID, teamID, transportID) 
	if Spring.ValidUnitID(unitID) then
		local currentCmd = Spring.GetUnitCurrentCommand(unitID)
		if currentCmd == CMD.WAIT then
			Spring.GiveOrderToUnit(unitID, CMD.WAIT, EMPTY_TABLE, 0)

			-- unsure why this is done but probably to make sure UnitIdle works correctly or somesuch
			if Spring.GetCommandQueue(unitID, 0) == 1 then
				Spring.GiveOrderToUnit(unitID, CMD.STOP, EMPTY_TABLE, 0)
			end
		end
	end
end

function widget:GameFrame(frame)
	if frame%15 == 12 then
		for i = 1, ferryRoutes.count do
			route = ferryRoutes.route[i]
		
			local unitsInArea = Spring.GetUnitsInCylinder(route.start.x, route.start.z, COLLECTION_RADIUS, myTeam)
			local unitsToTransport = {count = 0, unit = {}}
			
			for t = 1, #unitsInArea do
				local unitID = unitsInArea[t]
				if route.unitsQueuedToBeTransported[unitID] then
					if route.unitsQueuedToBeTransported[unitID] + CANT_BE_TRANSPORTED_DECAY_TIME < frame then
						route.unitsQueuedToBeTransported[unitID] = nil
					end
				else
					if Spring.GetUnitCurrentCommand(unitID) == CMD.WAIT then
						unitsToTransport.count = unitsToTransport.count + 1
						unitsToTransport.unit[unitsToTransport.count] = unitID
					end
				end
			end
			for tid = 1, route.transportCount do
				local unitID = route.transporters[tid]
				local trans = transport[unitID]
				local carriedUnits = Spring.GetUnitIsTransporting(unitID)
				
				if #carriedUnits == trans.capacity then
					if trans.waypoint <= route.pointcount then
						local x,_,z = Spring.GetUnitPosition(unitID)
						if trans.waypoint == 0 or disSQ(x, z, route.points[trans.waypoint].x, route.points[trans.waypoint].z) < NEAR_WAYPOINT_RANGE_SQ then
							trans.waypoint = trans.waypoint + 1
							if trans.waypoint > route.pointcount then
								GiveUnloadOrder(unitID, route.finish.x, route.finish.y, route.finish.z)
							else
								spGiveOrderToUnit(unitID, CMD.MOVE, {route.points[trans.waypoint].x, route.points[trans.waypoint].y, route.points[trans.waypoint].z}, 0 )
							end
						end
					end
				else
					local x,_,z = Spring.GetUnitPosition(unitID)
					if trans.waypoint > 0 then
						if trans.waypoint > route.pointcount or disSQ(x, z, route.points[trans.waypoint].x, route.points[trans.waypoint].z) < NEAR_WAYPOINT_RANGE_SQ then
							trans.waypoint = trans.waypoint - 1
							if trans.waypoint == 0 then
								spGiveOrderToUnit(unitID, CMD.MOVE, {route.start.x, route.start.y, route.start.z}, 0 )
							else
								spGiveOrderToUnit(unitID, CMD.MOVE, {route.points[trans.waypoint].x, route.points[trans.waypoint].y, route.points[trans.waypoint].z}, 0 )
							end
						end
					elseif unitsToTransport.count ~= 0 and disSQ(x, z, route.start.x, route.start.z) < NEAR_START_RANGE_SQ then
						if Spring.GetUnitCurrentCommand(unitID) ~= CMD.LOAD_UNITS then
							local choice = math.floor(math.random(1,unitsToTransport.count))
							local choiceUnitID = unitsToTransport.unit[choice]
							local ud = UnitDefs[Spring.GetUnitDefID(choiceUnitID)]
							if ud.xsize <= trans.maxSize and ud.zsize <= trans.maxSize and ud.mass <= trans.maxMass then
								Spring.GiveOrderToUnit(unitID, CMD.LOAD_UNITS, {choiceUnitID}, 0 )
								route.unitsQueuedToBeTransported[choiceUnitID] = frame
								
								unitsToTransport.unit[choice] = unitsToTransport.unit[unitsToTransport.count]
								unitsToTransport.unit[unitsToTransport.count] = nil
								unitsToTransport.count = unitsToTransport.count - 1
							end
						end
					elseif disSQ(x, z, route.start.x, route.start.z) > NEAR_WAYPOINT_RANGE_SQ then
						spGiveOrderToUnit(unitID, CMD.MOVE, {route.start.x, route.start.y, route.start.z}, 0 )
					end
				end
			end
		end
	end
end

local function addUnit(unitID, unitDefID, unitTeam)
	if unitTeam == myTeam and transportDefs[unitDefID] then
		local ud = UnitDefs[unitDefID]
		
		transportIndex.count = transportIndex.count + 1
		transportIndex.unit[transportIndex.count] = unitID
		transport[unitID] = {
			route = false,
			index = transportIndex.count,
			routeTransportIndex = false,
			waypoint = 0,
			capacity = ud.transportCapacity,
			maxMass = ud.transportMass,
			maxSize = ud.transportSize*2,
		}
	end
end

local function removeUnit(unitID, unitDefID, unitTeam)
	if unitTeam == myTeam and transportDefs[unitDefID] then
		local trans = transport[unitID]
		
		removeTransportFromRoute(unitID)
		
		transportIndex.unit[trans.index] = transportIndex.unit[transportIndex.count]
		transport[transportIndex.unit[trans.index]].index = trans.index
		transportIndex.unit[transportIndex.count] = nil
		transportIndex.count = transportIndex.count - 1
		transport[unitID] = nil
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	removeUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	addUnit(unitID, unitDefID, newTeam)
end

function widget:Initialize()
	local myUnits = Spring.GetTeamUnits(myTeam)
	
	for i = 1, #myUnits do
		local unitDefID = Spring.GetUnitDefID(myUnits[i])
		addUnit(myUnits[i], unitDefID, myTeam)
	end

end
-------------------------------------------------------------------
-------------------------------------------------------------------
--- DRAWING

local function DrawRoute(route)
	gl.Vertex(route.start.x, route.start.y, route.start.z)
	for i = 1, route.pointcount do
		gl.Vertex(route.points[i].x, route.points[i].y, route.points[i].z)
	end
	gl.Vertex(route.finish.x, route.finish.y, route.finish.z)
end

local function DrawPlacedRoute(pos)
	gl.Vertex(placedRoute.start.x, placedRoute.start.y, placedRoute.start.z)
	for i = 1, placedRoute.pointcount do
		gl.Vertex(placedRoute.points[i].x, placedRoute.points[i].y, placedRoute.points[i].z)
	end
	if placedRoute.finish then
		gl.Vertex(placedRoute.finish.x, placedRoute.finish.y, placedRoute.finish.z)
	end
	if pos then
		gl.Vertex(pos[1],pos[2],pos[3])
	end
end

local function DrawMovingPoints(pos)
	if movingPointNeighbours[2] then
		gl.Vertex(movingPointNeighbours[2].x, movingPointNeighbours[2].y, movingPointNeighbours[2].z)
	end
	gl.Vertex(pos[1],pos[2],pos[3])
	gl.Vertex(movingPointNeighbours[1].x, movingPointNeighbours[1].y, movingPointNeighbours[1].z)
end

function widget:DrawWorld()
	gl.DepthTest(false)
	gl.LineWidth(2)
	gl.Color(1, 0, 0, 0.9)
	
	for i = 1, ferryRoutes.count do
		gl.DrawGroundCircle(ferryRoutes.route[i].start.x, ferryRoutes.route[i].start.y, ferryRoutes.route[i].start.z, COLLECTION_RADIUS_DRAW, 32)
		gl.BeginEnd(GL.LINE_STRIP, DrawRoute, ferryRoutes.route[i])
	end
	
	local pos
	if( movingPoint and movingPointNeighbours) or placedRoute then
		local mx, my = Spring.GetMouseState()
		local _,p = Spring.TraceScreenRay(mx, my, true, true)
		pos = p
	end
	
	if movingPoint and pos and movingPointNeighbours then
		gl.LineStipple(true)
		if movingPoint.index == 0 then
			gl.DrawGroundCircle(pos[1], pos[2], pos[3], COLLECTION_RADIUS_DRAW, 32)
		end
		gl.BeginEnd(GL.LINE_STRIP, DrawMovingPoints, pos)
		gl.LineStipple(false)
	end
	
	if placedRoute then
		gl.DrawGroundCircle(placedRoute.start.x, placedRoute.start.y, placedRoute.start.z, COLLECTION_RADIUS_DRAW, 32)
		gl.BeginEnd(GL.LINE_STRIP, DrawPlacedRoute, pos)
	end

	gl.Color(1, 1, 1, 1)
end
