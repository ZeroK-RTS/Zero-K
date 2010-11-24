
function widget:GetInfo()
  return {
    name      = "Ferry Points",
    desc      = "Allows the creation of ferry routes that can have transports and units assigned to them",
    author    = "Google Frog",
    date      = "24 Nov 2010",
    license   = "GNU GPL, v2 or later",
	 handler   = true,
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

local spSetActiveCommand	= Spring.SetActiveCommand

local COLLECTION_RADIUS_DRAW = 120
local COLLECTION_RADIUS = 150
local NEAR_WAYPOINT_RANGE_SQ = 200^2
local NEAR_START_RANGE_SQ = 300^2
local UNLOAD_RADIUS = 160
local CANT_BE_TRANSPORTED_DECAY_TIME = 200

local CMD_SET_FERRY	= 11000
local CMD_MOVE 		= CMD.MOVE
local CMD_FIGHT		= CMD.FIGHT

local ferryRoutes = {count = 0, route = {}}

local placedRoute = false
local myTeam = Spring.GetMyTeamID()

local toBeWaited = {count = 0, unit = {}}

local wasTransported = {count = 0, unit = {}}

local transportDefs = {
	[UnitDefNames["corvalk"].id] = true,
	[UnitDefNames["corbtrans"].id] = true,
}

local transport = {}
local transportIndex = {count = 0, unit = {}}

WG.FerryUnits = {}

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

-- removes transport from whichever route it is part of
local function removeTransportFromRoute(unitID)

	local trans = transport[unitID]

	if not trans.route then
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
	
	trans.unitStillWaited = true
	
	WG.FerryUnits[unitID] = true

end

local function removeRoute(routeID)

	local route = ferryRoutes.route[routeID]
	
	for i = 1, route.transportCount do
		transport[route.transporters[i]].route = false
		transport[route.transporters[i]].routeTransportIndex = false
		transport[route.transporters[i]].waypoint = 0
		
		WG.FerryUnits[unitID] = false
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

function widget:CommandsChanged()
	local customCommands = widgetHandler.customCommands

	table.insert(customCommands, {			
		id      = CMD_SET_FERRY,
		type    = CMDTYPE.ICON_MAP,
		tooltip = 'Places a ferry route',
		cursor  = 'Repair',
		action  = 'setferry',
		params  = { }, 
		texture = 'LuaUI/Images/Crystal_Clear_action_flag.png',

		pos = {CMD_CLOAK,CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT}, 
	})
end


function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	
	if cmdID == CMD_SET_FERRY then
		
		if not placedRoute then
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
		
	elseif cmdID == CMD_MOVE or cmdID == CMD_FIGHT then
	
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
					if not ud.cantBeTransported then
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

function widget:Update()
	if placedRoute and Spring.GetActiveCommand() ~= Spring.GetCmdDescIndex(CMD_SET_FERRY) then
		Spring.SetActiveCommand(Spring.GetCmdDescIndex(CMD_SET_FERRY))
	end
	
	if toBeWaited.count ~= 0 then
		for i = 1, toBeWaited.count do
			Spring.GiveOrderToUnit(toBeWaited.unit[i], CMD.WAIT, {},{"shift"} )
		end
		toBeWaited.count = 0
		toBeWaited.unit = {}
	end	
end

-------------------------------------------------------------------
-------------------------------------------------------------------
--- UNIT HANDLING

function widget:GameFrame(frame)
	
	if frame%30 == 8 then
	
		for i = 1, wasTransported.count do
			unitID = wasTransported.unit[i]
			if Spring.ValidUnitID(unitID) then
				if Spring.GetUnitTransporter(unitID) == nil then
					local cmd = Spring.GetCommandQueue(unitID)
					if #cmd > 0 and cmd[1].id == CMD.WAIT then
						Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
						if #cmd == 1 then
							Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
						end
					end
					wasTransported.unit[i] = wasTransported.unit[wasTransported.count]
					wasTransported.unit[wasTransported.count] = nil
					wasTransported.count = wasTransported.count - 1
					break
				end
			else
				wasTransported.unit[i] = wasTransported.unit[wasTransported.count]
				wasTransported.unit[wasTransported.count] = nil
				wasTransported.count = wasTransported.count - 1
				break
			end
		end
	
	end
	
	if frame%15 == 12 then
		
		for i = 1, ferryRoutes.count do
		
			route = ferryRoutes.route[i]
		
			local unitsInArea = Spring.GetUnitsInCylinder(route.start.x, route.start.z, COLLECTION_RADIUS, myTeam)
			local unitsToTransport = {count = 0, unit = {}}
			
			for t = 1, #unitsInArea do
				local unitID = unitsInArea[t]
				local cmd = Spring.GetCommandQueue(unitID)
				if route.unitsQueuedToBeTransported[unitID] then
					if route.unitsQueuedToBeTransported[unitID] + CANT_BE_TRANSPORTED_DECAY_TIME < frame then
						route.unitsQueuedToBeTransported[unitID] = nil
					end
				else
					if #cmd > 0 and cmd[1].id == CMD.WAIT then
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
								Spring.GiveOrderToUnit(unitID, CMD.UNLOAD_UNITS, 
									{route.finish.x, route.finish.y, route.finish.z, UNLOAD_RADIUS}, {} )
							else
								Spring.GiveOrderToUnit(unitID, CMD_MOVE, 
									{route.points[trans.waypoint].x, route.points[trans.waypoint].y, route.points[trans.waypoint].z}, {} )
							end
						end
					end
					
					if trans.unitStillWaited then
						trans.unitStillWaited = false
						for u = 1, #carriedUnits do
							route.unitsQueuedToBeTransported[carriedUnits[u]] = nil
							wasTransported.count = wasTransported.count + 1
							wasTransported.unit[wasTransported.count] = carriedUnits[u]
						end
					end
					
				else
					local x,_,z = Spring.GetUnitPosition(unitID)
					if trans.waypoint > 0 then
						if trans.waypoint > route.pointcount or disSQ(x, z, route.points[trans.waypoint].x, route.points[trans.waypoint].z) < NEAR_WAYPOINT_RANGE_SQ then
							trans.waypoint = trans.waypoint - 1
							if trans.waypoint == 0 then
								trans.unitStillWaited = true
								Spring.GiveOrderToUnit(unitID, CMD_MOVE, 
									{route.start.x, route.start.y, route.start.z}, {} )
							else
								Spring.GiveOrderToUnit(unitID, CMD_MOVE, 
									{route.points[trans.waypoint].x, route.points[trans.waypoint].y, route.points[trans.waypoint].z}, {} )
							end
						end
					elseif unitsToTransport.count ~= 0 and disSQ(x, z, route.start.x, route.start.z) < NEAR_START_RANGE_SQ then
						local cmd = Spring.GetCommandQueue(unitID)
						if #cmd == 0 or cmd[1].id ~= CMD.LOAD_UNITS then
							local choice = math.floor(math.random(1,unitsToTransport.count))
							local ud = UnitDefs[Spring.GetUnitDefID(unitsToTransport.unit[choice])]
							if ud.xsize <= trans.maxSize and ud.zsize <= trans.maxSize and ud.mass <= trans.maxMass then
								Spring.GiveOrderToUnit(unitID, CMD.LOAD_UNITS, {unitsToTransport.unit[choice]}, {} )
								route.unitsQueuedToBeTransported[unitsToTransport.unit[choice]] = frame
								
								unitsToTransport.unit[choice] = unitsToTransport.unit[unitsToTransport.count]
								unitsToTransport.unit[unitsToTransport.count] = nil
								unitsToTransport.count = unitsToTransport.count - 1
							end
						end
					elseif disSQ(x, z, route.start.x, route.start.z) > NEAR_WAYPOINT_RANGE_SQ then
						Spring.GiveOrderToUnit(unitID, CMD_MOVE, 
							{route.start.x, route.start.y, route.start.z}, {} )
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
			unitStillWaited = true,
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

function widget:DrawWorld()

	gl.DepthTest(false)
	gl.LineWidth(2)
	gl.Color(1, 0, 0, 0.9)
	
	for i = 1, ferryRoutes.count do
		gl.DrawGroundCircle(ferryRoutes.route[i].start.x, ferryRoutes.route[i].start.y, ferryRoutes.route[i].start.z, COLLECTION_RADIUS_DRAW, 32)
		gl.BeginEnd(GL.LINE_STRIP, DrawRoute, ferryRoutes.route[i])
	end
	
	if placedRoute then
		local mx, my = Spring.GetMouseState()
		local _,pos = Spring.TraceScreenRay(mx, my, true, true)
		gl.DrawGroundCircle(placedRoute.start.x, placedRoute.start.y, placedRoute.start.z, COLLECTION_RADIUS_DRAW, 32)
		gl.BeginEnd(GL.LINE_STRIP, DrawPlacedRoute, pos)
	end

end


