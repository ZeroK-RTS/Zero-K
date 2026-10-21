-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function gadget:GetInfo()
	return {
		name = "Portal duels",
		desc = "Manifest-driven isolated maps joined by commander loss",
		author = "Codex",
		license = "GPL v2 or later",
		layer = -50,
		enabled = true,
	}
end
local options = Spring.GetModOptions()
if not options.zk_duels or options.zk_duels == "baseline" then
	return false
end
if not gadgetHandler:IsSyncedCode() then
	local accelerated, done = false, false
	function gadget:Update()
		if not accelerated and Spring.GetGameFrame() > 0 then
			accelerated = true
			Spring.SendCommands("setspeed " .. (options.zk_duels_speed or 1))
		end
		if not done and Spring.GetGameRulesParam("zkduels_done") == 1 then
			done = true
			Spring.SendCommands("quitforce")
		end
	end
	function gadget:GameOver()
		if tonumber(options.zk_duels_end or 0) > 0 then
			Spring.SendCommands("quitforce")
		end
	end
	return
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
if not world then
	return false
end
if
	not (
		Engine.FeatureSupport
		and Engine.FeatureSupport.mapRegionViews
		and Engine.FeatureSupport.sensorRegions
		and Engine.FeatureSupport.mapDamageRegions
	)
then
	function gadget:GameFrame(f)
		if f == 1 then
			Spring.Echo(
				"Portal worlds requires engine map-region views, synced sensor regions and crater regions; disable the experimental portal option for normal ZK."
			)
			Spring.SetGameRulesParam("portal_worlds_unsupported_engine", 1)
			Spring.GameOver({})
		end
	end
	return
end
local regions, connections = world.regions, world.connections
local Region, TeamHome = world.Region, world.TeamHome
local endFrame = tonumber(options.zk_duels_end) or 0
local PORTAL_RADIUS, APPROACH_RADIUS = 180, 80
local RAW_MOVE = Spring.Utilities.CMD.RAW_MOVE
local PORTAL = Spring.Utilities.CMD.PORTAL_TRAVEL
local home, cooldown, travelers, pendingLoss, beacons = {}, {}, {}, {}, {}
local openEdges, mouths, lossOpened = {}, {}, {}
local damage, created = {}, {}
local passages, blockedDamage, wallHits, blockedOrders = 0, 0, 0, 0
local function Log(s)
	if endFrame > 0 then
		Spring.Echo("[ZKDUELS] " .. s)
	end
end
local function Valid(id)
	return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function Mobile(def)
	return def and not def.isImmobile and def.speed > 0 and not def.customParams.dontcount
end
local function IsOpen(edge)
	return openEdges[edge]
end
local function FreeSpot(def, x, z, region, exitMouth)
	local r = regions[region]
	for ring = 0, 36 do
		for j = 0, 15 do
			local tx = math.max(r.x0 + 24, math.min(r.x1 - 24, x + ring * 40 * math.cos(j * math.pi / 8)))
			local tz = math.max(r.z0 + 24, math.min(r.z1 - 24, z + ring * 40 * math.sin(j * math.pi / 8)))
			local y = Spring.GetGroundHeight(tx, tz)
			local clear = not exitMouth or (tx - exitMouth.x) ^ 2 + (tz - exitMouth.z) ^ 2 >= 240 ^ 2
			local safe = not r.surface or y > r.surface.height + 4
			if
				clear
				and safe
				and (UnitDefs[def].canFly or Spring.TestMoveOrder(def, tx, y, tz, 0, 0, 0, true, true, true))
			then
				return tx, y, tz
			end
		end
	end
end
local function PublishMouth(edge, region, m)
	local prefix = "zkduels_e" .. edge .. "_r" .. region
	Spring.SetGameRulesParam(prefix .. "_x", m.x)
	Spring.SetGameRulesParam(prefix .. "_z", m.z)
	local aiPrefix = "portal_e" .. edge .. "_r" .. region
	Spring.SetGameRulesParam(aiPrefix .. "_x", m.x)
	Spring.SetGameRulesParam(aiPrefix .. "_z", m.z)
	-- Retain these diagnostic names for the first mouth in a region.
	if not Spring.GetGameRulesParam("zkduels_m" .. region .. "_x") then
		Spring.SetGameRulesParam("zkduels_m" .. region .. "_x", m.x)
		Spring.SetGameRulesParam("zkduels_m" .. region .. "_z", m.z)
	end
end
local function OpenPortal(team, frame, loss)
	local source = loss.region
	if not source or lossOpened[source] then
		return
	end
	local chosen
	-- Prefer the outgoing edge in the authored graph; fall back to a closed neighbour.
	for i, edge in ipairs(connections) do
		if edge[1] == source and not openEdges[i] then
			chosen = i
			break
		end
	end
	if not chosen then
		for i, edge in ipairs(connections) do
			if world.Other(edge, source) and not openEdges[i] then
				chosen = i
				break
			end
		end
	end
	lossOpened[source] = true
	if not chosen then
		return
	end
	local edge = connections[chosen]
	mouths[chosen] = {}
	for _, region in ipairs(edge) do
		local r = regions[region]
		local x, z = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
		if region == source and loss.x then
			x, z = loss.x, loss.z
		end
		-- Separate the central ends of several portals in the same map.
		if region ~= source then
			for _, existing in pairs(mouths) do
				if existing[region] then
					x = x + 360
				end
			end
		end
		local y = Spring.GetGroundHeight(x, z)
		if region ~= source then
			x, y, z = FreeSpot(UnitDefNames.cloakraid.id, x, z, region)
			assert(x, "No central portal site in " .. r.name)
		end
		local m = { x = x, y = y, z = z }
		mouths[chosen][region] = m
		PublishMouth(chosen, region, m)
		local id = Spring.CreateUnit("tele_beacon", x, y, z, 0, Spring.GetGaiaTeamID())
		assert(id, "Could not create portal beacon")
		beacons[id] = { edge = chosen, region = region }
		home[id] = region
		Spring.SetUnitNeutral(id, true)
		Spring.SetUnitBlocking(id, false)
		Spring.SetUnitAlwaysVisible(id, true)
		Spring.SetUnitRulesParam(id, "zkduels_portal", chosen, { public = true })
		Spring.SetUnitRulesParam(id, "zkduels_region", region, { public = true })
		local destination = regions[world.Other(edge, region)].name
		Spring.SetUnitRulesParam(id, "portal_destination_name", destination, { public = true })
		Spring.SetUnitTooltip(id, "Portal to " .. destination .. " - Right click with mobile units to travel")
		Spring.SetUnitNoSelect(id, false)
		Spring.SetUnitHealth(id, 100000)
		Spring.SpawnCEG("teleport_in", x, y + 10, z, 0, 1, 0, 40)
	end
	openEdges[chosen] = true
	Spring.SetGameRulesParam("zkduels_e" .. chosen .. "_open", 1)
	Spring.SetGameRulesParam("portal_e" .. chosen .. "_open", 1)
	Spring.SetGameRulesParam("zkduels_open", 1)
	Spring.SetGameRulesParam("zkduels_open_frame", frame)
	Spring.SetGameRulesParam("zkduels_loser", team)
	Log(
		"OPEN frame="
			.. frame
			.. " lostTeam="
			.. team
			.. " source="
			.. source
			.. " edge="
			.. chosen
			.. " to="
			.. world.Other(edge, source)
	)
end
local function Route(id, region, destination, manual, chosen, commandTag)
	if travelers[id] or not Mobile(UnitDefs[Spring.GetUnitDefID(id)]) then
		return
	end
	local edge, nextRegion = chosen, chosen and world.Other(connections[chosen], region)
	if not edge then
		edge, nextRegion = world.Route(region, destination, IsOpen)
	end
	if not edge or not openEdges[edge] or not nextRegion then
		return
	end
	local m = mouths[edge][region]
	Spring.SetUnitTarget(id, nil)
	travelers[id] =
		{ region = region, destination = nextRegion, manual = manual, edge = edge, commandTag = commandTag }
	-- Fixed-wing defaults may finish outside the portal activation radius.
	Spring.GiveOrderToUnit(id, CMD.INSERT, { 0, RAW_MOVE, CMD.OPT_INTERNAL, m.x, m.y, m.z, APPROACH_RADIUS }, CMD.OPT_ALT)
	local current, _, tag = Spring.GetUnitCurrentCommand(id)
	-- A completed approach can expose the original request immediately,
	-- especially for fixed-wing aircraft. Never record that request as an
	-- approach tag: removing it after transit would delete the remaining route.
	if current == RAW_MOVE and tag ~= commandTag then
		travelers[id].moveTag = tag
	end
end
local unitTargets = {
	[CMD.ATTACK] = true,
	[CMD.GUARD] = true,
	[CMD.REPAIR] = true,
	[CMD.RECLAIM] = true,
	[CMD.CAPTURE] = true,
	[CMD.LOAD_UNITS] = true,
	[Spring.Utilities.CMD.REARM] = true,
	[Spring.Utilities.CMD.FIELD_FAC_SELECT] = true,
	[Spring.Utilities.CMD.WAIT_AT_BEACON] = true,
}
local targetCommands = {
	[Spring.Utilities.CMD.UNIT_SET_TARGET] = true,
	[Spring.Utilities.CMD.UNIT_SET_TARGET_CIRCLE] = true,
	[CMD.MANUALFIRE] = true,
	[Spring.Utilities.CMD.AIR_MANUALFIRE] = true,
}
for cmd in pairs(targetCommands) do
	unitTargets[cmd] = true
end
local travelCommands = { [CMD.MOVE] = true, [RAW_MOVE] = true, [CMD.FIGHT] = true, [CMD.ATTACK] = true }
local positionCommands = {}
for cmd in pairs(travelCommands) do
	positionCommands[cmd] = true
end
for cmd in pairs(unitTargets) do
	positionCommands[cmd] = true
end
for _, cmd in ipairs({
	CMD.PATROL,
	CMD.RESTORE,
	CMD.RESURRECT,
	CMD.UNLOAD_UNITS,
	CMD.UNLOAD_UNIT,
	Spring.Utilities.CMD.JUMP,
	Spring.Utilities.CMD.PLACE_BEACON,
	Spring.Utilities.CMD.AREA_GUARD,
	Spring.Utilities.CMD.RESTORE,
	Spring.Utilities.CMD.EXTENDED_UNLOAD,
	Spring.Utilities.CMD.LEVEL,
	Spring.Utilities.CMD.RAISE,
	Spring.Utilities.CMD.SMOOTH,
	Spring.Utilities.CMD.RAMP,
	Spring.Utilities.CMD.BUMPY,
}) do
	positionCommands[cmd] = true
end
local function CommandRegion(cmd, params)
	if (cmd == Spring.Utilities.CMD.ORBIT or cmd == Spring.Utilities.CMD.ORBIT_DRAW) and Valid(params[1]) then
		return home[params[1]]
	end
	if #params >= 3 and (cmd < 0 or positionCommands[cmd]) then
		return Region(params[1], params[3])
	end
	if #params == 1 then
		if (cmd == CMD.RECLAIM or cmd == CMD.RESURRECT) and params[1] >= Game.maxUnits then
			local x, _, z = Spring.GetFeaturePosition(params[1] - Game.maxUnits)
			return Region(x, z)
		end
		if unitTargets[cmd] and Valid(params[1]) then
			return home[params[1]]
		end
	end
end
function gadget:Initialize()
	assert(
		Game.mapSizeX == world.size[1] and Game.mapSizeZ == world.size[2],
		"Portal manifest and physical map disagree"
	)
	local sensorRegions = {}
	for i, r in ipairs(regions) do
		sensorRegions[i] = { r.x0, r.z0, r.x1, r.z1 }
	end
	assert(
		Spring.SetSensorRegions(sensorRegions),
		"Portal sensor regions must align to the engine sensor grid and be configured before simulation starts"
	)
	assert(
		Spring.SetMapDamageRegions(sensorRegions),
		"Portal crater regions must be configured before simulation starts"
	)
	Spring.SetGameRulesParam("zkduels_regions", #regions)
	Spring.SetGameRulesParam("zkduels_edges", #connections)
	Spring.SetGameRulesParam("zkduels_open", 0)
	-- Public topology protocol shared with native BARb/Circuit portal missions.
	Spring.SetGameRulesParam("portal_ai_version", 1)
	Spring.SetGameRulesParam("portal_ai_diagnostics", options.portal_ai_log == "1" and 1 or 0)
	Spring.SetGameRulesParam("portal_regions", #regions)
	Spring.SetGameRulesParam("portal_edges", #connections)
	for _, entry in ipairs(world.teams) do
		Spring.SetGameRulesParam("portal_team" .. entry.team .. "_region", entry.region)
		Spring.SetGameRulesParam("portal_team" .. entry.team .. "_alive", select(3, Spring.GetTeamInfo(entry.team, false)) and 0 or 1)
	end
	for i, r in ipairs(regions) do
		for _, k in ipairs({ "x0", "z0", "x1", "z1" }) do
			Spring.SetGameRulesParam("zkduels_r" .. i .. "_" .. k, r[k])
			Spring.SetGameRulesParam("portal_r" .. i .. "_" .. k, r[k])
		end
	end
	for i in ipairs(connections) do
		Spring.SetGameRulesParam("zkduels_e" .. i .. "_open", 0)
		Spring.SetGameRulesParam("portal_e" .. i .. "_open", 0)
		Spring.SetGameRulesParam("portal_e" .. i .. "_a", connections[i][1])
		Spring.SetGameRulesParam("portal_e" .. i .. "_b", connections[i][2])
	end
	-- Cubicle barriers: impassable terrain and build masks between authored regions.
	for x = 0, Game.mapSizeX - 8, 8 do
		for z = 0, Game.mapSizeZ - 8, 8 do
			if not Region(x + 4, z + 4) then
				Spring.SetMapSquareTerrainType(x, z, GG.IMPASSIBLE_TERRAIN)
				if x % 16 == 0 and z % 16 == 0 then
					Spring.SetSquareBuildingMask(x / 16, z / 16, 0)
				end
			end
		end
	end
	GG.PortalWorlds = {
		world = world,
		home = home,
		openEdges = openEdges,
		mouths = mouths,
		beacons = beacons,
		Region = Region,
	}
	Log("READY regions=" .. #regions .. " spots=" .. tostring(GG.metalSpots and #GG.metalSpots))
end
function gadget:UnitCreated(id, def, team, builder)
	created[team] = (created[team] or 0) + 1
	local x, _, z = Spring.GetUnitPosition(id)
	-- Factories validate their queue before the native spawn point exists.
	-- A child belongs to its producer even if its exit briefly lies in a strip.
	home[id] = (builder and home[builder]) or Region(x, z)
end
function gadget:TeamDied(team)
	Spring.SetGameRulesParam("portal_team" .. team .. "_alive", 0)
end
function gadget:AllowCommand(id, def, team, cmd, params, opts)
	-- Inspect inserted orders too, before interpreting their target or queue flags.
	local actual, p = cmd, params
	if cmd == CMD.INSERT then
		if #params < 3 then
			return false
		end
		actual = params[2]
		p = {}
		for i = 4, #params do
			p[#p + 1] = params[i]
		end
	end
	if actual == PORTAL then
		local edge = tonumber(p[1])
		return Mobile(UnitDefs[def])
				and home[id] ~= nil
				and (not p[2] or p[2] == home[id])
				and edge ~= nil
				and openEdges[edge]
				and world.Other(connections[edge], home[id]) ~= nil
			or false
	end
	local target = unitTargets[actual] and #p == 1 and beacons[p[1]]
	if target then
		if
			(
				actual == CMD.ATTACK
				or actual == CMD.GUARD
				or actual == CMD.REPAIR
				or actual == CMD.RECLAIM
				or actual == CMD.CAPTURE
				or actual == CMD.LOAD_UNITS
				or actual == Spring.Utilities.CMD.WAIT_AT_BEACON
			)
			and target.region == home[id]
			and Mobile(UnitDefs[def])
		then
			if cmd == CMD.INSERT then
				Spring.GiveOrderToUnit(
					id,
					CMD.INSERT,
					{ params[1], PORTAL, params[3], target.edge, target.region },
					opts.coded or 0
				)
			else
				Spring.GiveOrderToUnit(id, PORTAL, { target.edge, target.region }, opts.coded or 0)
			end
		end
		return false -- Never leave an attack or set-target order aimed at a portal.
	end
	local destination = CommandRegion(actual, p)
	if destination and home[id] and destination ~= home[id] then
		if
			not travelCommands[actual]
			or not Mobile(UnitDefs[def])
			or not world.Route(home[id], destination, IsOpen)
		then
			blockedOrders = blockedOrders + 1
			return false
		end
	end
	-- Coordinate orders into the void are never valid construction or weapon targets.
	if #p >= 3 and not destination and (actual < 0 or positionCommands[actual]) then
		return false
	end
	return true
end
function gadget:CommandFallback(id, def, team, cmd)
	if cmd == PORTAL then
		return true, false
	end -- RouteOrders starts it when it reaches the queue front.
	return false
end
function gadget:UnitPreDamaged(id, def, team, dmg)
	if beacons[id] then
		return 0, 0
	end
	return dmg
end
function gadget:UnitDamaged(id, def, team, dmg)
	damage[team] = (damage[team] or 0) + dmg
end
function gadget:UnitDestroyed(id, def, team)
	if UnitDefs[def].customParams.commtype and not (GG.wasMorphedTo and GG.wasMorphedTo[id]) then
		local x, _, z = Spring.GetUnitPosition(id)
		local region = Region(x, z) or home[id] or TeamHome(team)
		pendingLoss[team] = { due = Spring.GetGameFrame() + 30, x = x, z = z, region = region }
		Log(
			"COM_DESTROYED frame="
				.. Spring.GetGameFrame()
				.. " team="
				.. team
				.. " region="
				.. tostring(region)
		)
	end
	travelers[id] = nil
	home[id] = nil
	cooldown[id] = nil
	beacons[id] = nil
end
local function RemoveApproachOrders(id, trip)
	local remove = {}
	if trip.moveTag then
		remove[#remove + 1] = trip.moveTag
	end
	if trip.manual and trip.commandTag then
		remove[#remove + 1] = trip.commandTag
	end
	for _, command in ipairs(Spring.GetUnitCommands(id, -1)) do
		local destination = CommandRegion(command.id, command.params)
		if command.tag ~= trip.moveTag and destination and destination == trip.region then
			remove[#remove + 1] = command.tag
		end
	end
	if #remove > 0 then
		Spring.GiveOrderToUnit(id, CMD.REMOVE, remove, 0)
	end
end
local function SetHome(id, region)
	home[id] = region
	if GG.CancelAircraftPadReservation then
		GG.CancelAircraftPadReservation(id)
	end
	if GG.ClearUnitTarget then
		GG.ClearUnitTarget(id)
	end
	Spring.SetUnitRulesParam(id, "zkduels_region", region, { public = true })
	for _, cargo in ipairs(Spring.GetUnitIsTransporting(id) or {}) do
		RemoveApproachOrders(cargo, { region = home[cargo] })
		Spring.SetUnitTarget(cargo, nil)
		SetHome(cargo, region)
	end
end
local function HasTravelOrder(id, trip)
	for _, command in ipairs(Spring.GetUnitCommands(id, -1)) do
		if command.tag == trip.commandTag then
			return true
		end
	end
	return false
end
local function StepTravelers(frame)
	for id, trip in pairs(travelers) do
		if Valid(id) then
			local x, y, z = Spring.GetUnitPosition(id)
			local m = mouths[trip.edge][trip.region]
			local nearMouth = (x - m.x) ^ 2 + (z - m.z) ^ 2 < PORTAL_RADIUS ^ 2
			local _, _, tag = Spring.GetUnitCurrentCommand(id)
			if tag ~= (trip.moveTag or trip.commandTag) or (not trip.moveTag and not nearMouth) then
				travelers[id] = nil
				-- An inserted waypoint may pause travel without clearing its queue.
				-- Drop only our approach; route again when the request reaches front.
				if trip.moveTag then
					Spring.GiveOrderToUnit(id, CMD.REMOVE, { trip.moveTag }, 0)
				end
			elseif (frame % 10 == 0 or nearMouth) and not HasTravelOrder(id, trip) then
				-- Removing the original queued order must also cancel its internal
				-- approach. Check periodically en route and before every activation.
				travelers[id] = nil
				if trip.moveTag then
					Spring.GiveOrderToUnit(id, CMD.REMOVE, { trip.moveTag }, 0)
				end
			end
			if
				travelers[id]
				and Spring.GetUnitRulesParam(id, "is_jumping") ~= 1
				and not (GG.Thrower and GG.Thrower.IsFlying(id))
				and not (GG.Puppy_IsInFlight and GG.Puppy_IsInFlight(id))
				and nearMouth
				and (cooldown[id] or 0) <= frame
			then
				local to = mouths[trip.edge][trip.destination]
				local r = regions[trip.destination]
				local vx, vz = (r.x0 + r.x1) / 2 - to.x, (r.z0 + r.z1) / 2 - to.z
				local length = math.sqrt(vx * vx + vz * vz)
				if length < 1 then
					vx, vz, length = 1, 0, 1
				end
				local dx, dy, dz = FreeSpot(
					Spring.GetUnitDefID(id),
					to.x + vx / length * 340,
					to.z + vz / length * 340,
					trip.destination,
					to
				)
				if dx then
					Spring.SpawnCEG("teleport_out", x, y + 10, z, 0, 1, 0, 30)
					local def = UnitDefs[Spring.GetUnitDefID(id)]
					if def.canFly then
						Spring.SetUnitPosition(id, dx, dy + math.max(100, def.wantedHeight or 100), dz)
					else
						GG.MoveMobileUnit(id, dx, dy, dz)
					end
					SetHome(id, trip.destination)
					-- Unlike native cargo, carrier drones are independent units. Move
					-- their roster too, preserving docked construction and guard orders.
					local drones = GG.Drones_GetCarrierUnits and GG.Drones_GetCarrierUnits(id)
					for _, drone in ipairs(drones or {}) do
						if Valid(drone) then
							local cx, cy, cz = Spring.GetUnitPosition(drone)
							cx = math.max(r.x0 + 24, math.min(r.x1 - 24, dx + cx - x))
							cz = math.max(r.z0 + 24, math.min(r.z1 - 24, dz + cz - z))
							cy = dy + math.max(20, cy - y)
							SetHome(drone, trip.destination)
							if Spring.MoveCtrl.GetTag(drone) then
								Spring.MoveCtrl.SetPosition(drone, cx, cy, cz)
							else
								Spring.SetUnitPosition(drone, cx, cy, cz)
							end
							Spring.SetUnitVelocity(drone, 0, 0, 0)
							Spring.SetUnitTarget(drone, nil)
							GG.Drones_ClearOrders(drone)
						end
					end
					Spring.SetUnitVelocity(id, 0, 0, 0)
					Spring.SetUnitTarget(id, nil)
					cooldown[id] = frame + 90
					RemoveApproachOrders(id, trip)
					GG.WaitWaitMoveUnit(id)
					Spring.SpawnCEG("teleport_in", dx, dy + 10, dz, 0, 1, 0, 30)
					passages = passages + 1
					Spring.SetGameRulesParam("zkduels_passages", passages)
					Log(
						"TRANSIT frame="
							.. frame
							.. " id="
							.. id
							.. " from="
							.. trip.region
							.. " to="
							.. trip.destination
							.. " edge="
							.. trip.edge
					)
					travelers[id] = nil
				end
			end
		else
			travelers[id] = nil
		end
	end
end
local function RouteOrders()
	for _, id in ipairs(Spring.GetAllUnits()) do
		if home[id] and not travelers[id] and Mobile(UnitDefs[Spring.GetUnitDefID(id)]) then
			local commands = Spring.GetUnitCommands(id, 1)
			local command = commands and commands[1]
			if command and command.id == PORTAL then
				local edge = command.params[1]
				if
					openEdges[edge]
					and world.Other(connections[edge], home[id])
					and (not command.params[2] or command.params[2] == home[id])
				then
					Route(id, home[id], nil, true, edge, command.tag)
				else
					Spring.GiveOrderToUnit(id, CMD.REMOVE, { command.tag }, 0)
				end
			end
			local destination = command
				and travelCommands[command.id]
				and CommandRegion(command.id, command.params)
			if destination and destination ~= home[id] then
				Route(id, home[id], destination, false, nil, command.tag)
			end
		end
	end
end
function gadget:GameFrame(f)
	for team, loss in pairs(pendingLoss) do
		if f >= loss.due then
			local comm = false
			for _, id in ipairs(Spring.GetTeamUnits(team)) do
				if Valid(id) and UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
					comm = true
					break
				end
			end
			if not comm then
				OpenPortal(team, f, loss)
			end
			pendingLoss[team] = nil
		end
	end
	if f % 10 == 0 then
		RouteOrders()
	end
	StepTravelers(f)
	if f % 30 == 0 then
		for _, pair in pairs(mouths) do
			for _, m in pairs(pair) do
				Spring.SpawnCEG("teleport_progress", m.x, m.y + 12, m.z, 0, 1, 0, 20)
			end
		end
	end
	if f % 5 == 0 then
		for id, region in pairs(home) do
			if Valid(id) and not Spring.GetUnitTransporter(id) then
				local x, y, z = Spring.GetUnitPosition(id)
				local aircraft = UnitDefs[Spring.GetUnitDefID(id)].canFly
				local r = aircraft and world.objectBounds[region] or regions[region]
				-- Aircraft may use their half of the cubicle barriers to turn.
				if (aircraft and not world.ContainsObject(region, x, z)) or (not aircraft and Region(x, z) ~= region) then
					local tx = math.max(r.x0 + 24, math.min(r.x1 - 24, x))
					local tz = math.max(r.z0 + 24, math.min(r.z1 - 24, z))
					if UnitDefs[Spring.GetUnitDefID(id)].canFly then
						Spring.SetUnitPosition(id, tx, y, tz)
					else
						GG.MoveMobileUnit(id, tx, y, tz)
					end
					Spring.SetUnitVelocity(id, 0, 0, 0)
					wallHits = wallHits + 1
				end
			end
		end
	end
	if f % 30 == 0 then
		for id, region in pairs(home) do
			local r = regions[region]
			if r.surface and r.surface.damage and Valid(id) then
				local x, y, z = Spring.GetUnitPosition(id)
				if y < r.surface.height + 2 and not Spring.GetUnitTransporter(id) then
					Spring.AddUnitDamage(id, r.surface.damage)
				end
			end
		end
	end
	if endFrame > 0 and f % 1800 == 0 then
		for _, entry in ipairs(world.teams) do
			local t = entry.team
			local factories, here, away = 0, 0, 0
			for _, id in ipairs(Spring.GetTeamUnits(t)) do
				local def = UnitDefs[Spring.GetUnitDefID(id)]
				if def.isFactory then
					factories = factories + 1
				end
				if def.customParams.commtype and f <= 5400 then
					local x, _, z = Spring.GetUnitPosition(id)
					local cmd, _, _, cx, cy, cz = Spring.GetUnitCurrentCommand(id)
					Log(
						"COMMANDER team="
							.. t
							.. " position="
							.. x
							.. ","
							.. z
							.. " cmd="
							.. tostring(cmd)
							.. " target="
							.. tostring(cx)
							.. ","
							.. tostring(cz)
					)
				end
				if home[id] == entry.region then
					here = here + 1
				else
					away = away + 1
				end
			end
			Log(
				string.format(
					"TEAM frame=%d team=%d region=%d units=%d created=%d factories=%d here=%d away=%d damage=%.1f",
					f,
					t,
					entry.region,
					#Spring.GetTeamUnits(t),
					created[t] or 0,
					factories,
					here,
					away,
					damage[t] or 0
				)
			)
		end
		Log(
			string.format(
				"STATE frame=%d passages=%d wallHits=%d blockedOrders=%d",
				f,
				passages,
				wallHits,
				blockedOrders
			)
		)
	end
	if endFrame > 0 and f >= endFrame then
		Spring.SetGameRulesParam("zkduels_done", 1)
	end
end
function gadget:Shutdown()
	GG.PortalWorlds = nil
end
