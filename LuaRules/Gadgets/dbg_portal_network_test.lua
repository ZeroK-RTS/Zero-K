-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function gadget:GetInfo()
	return { name = "Portal independent client regression", layer = -100, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "network" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local teams, acks, units, targets, received = {}, {}, {}, {}, {}
local options = Spring.GetModOptions()
local rounds = tonumber(options.zk_duels_network_rounds) or 1
local squadSize = tonumber(options.zk_duels_network_units) or 1
assert(rounds >= 1 and rounds <= 32 and rounds % 1 == 0)
assert(squadSize >= 1 and squadSize <= 64 and squadSize % 1 == 0)
local round, squads, roundTargets = 1, { {}, {} }, {}
local function Destination(owner)
	return round % 2 == 1 and 3 - owner or owner
end
local phase, phaseFrame, failed, checks = 0, 0, false, 0
for region = 1, 2 do
	for _, entry in ipairs(world.teams) do
		if entry.region == region then
			teams[region] = entry.team
			break
		end
	end
end
local function Check(name, value, detail)
	checks = checks + 1
	failed = failed or not value
	Spring.Echo(
		"[NETWORK_TEST] ASSERT "
			.. name
			.. " pass="
			.. tostring(not not value)
			.. " "
			.. tostring(detail or "")
	)
end
local function Spawn(name, region, team, x, z)
	local r = world.regions[region]
	x, z = x or (r.x0 + r.x1) / 2, z or (r.z0 + r.z1) / 2
	local id = assert(Spring.CreateUnit(name, x, Spring.GetGroundHeight(x, z), z, 0, team))
	Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
	return id
end
local function PublishPhase(value, frame)
	phase, phaseFrame = value, frame
	Spring.SetGameRulesParam("portal_network_round", round, { public = true })
	acks = {}
	Spring.SetGameRulesParam("portal_network_phase", value, { public = true })
end
local function BothAcknowledged()
	return acks[0] and acks[1]
end
function gadget:RecvLuaMsg(message, player)
	if message == "portal_network_" .. phase and (player == 0 or player == 1) then
		acks[player] = true
	end
end
function gadget:AllowCommand(id, def, team, cmd, params, opts, tag, player, fromSynced)
	if player and player >= 0 then
		for _, squad in ipairs(squads) do
			for _, unit in ipairs(squad) do
				if unit == id and cmd == CMD.MOVE then
					received[id] = player
				end
			end
		end
	end
	return true
end
local function Witness(frame)
	local state = { tostring(frame), tostring(Spring.GetGameRulesParam("zkduels_passages") or 0) }
	for _, id in ipairs(Spring.GetAllUnits()) do
		local x, y, z = Spring.GetUnitPosition(id)
		state[#state + 1] = string.format(
			"%d:%d:%.3f:%.3f:%.3f:%.3f:%s",
			id,
			Spring.GetUnitTeam(id),
			x,
			y,
			z,
			Spring.GetUnitHealth(id),
			tostring(GG.PortalWorlds.home[id])
		)
	end
	Spring.Echo("[NETWORK_WITNESS] " .. table.concat(state, ";"))
end
function gadget:GameFrame(f)
	local finish = Spring.GetGameRulesParam("portal_network_finish")
	if f % 60 == 0 and (not finish or f <= finish) then
		Witness(f)
	end
	if f == 1 then
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
		end
	end
	if f == 30 then
		for i = 1, 2 do
			local r = world.regions[i]
			Spring.LevelHeightMap(r.x0 + 128, r.z0 + 128, r.x1 - 128, r.z1 - 128, 200)
			local radar =
				Spawn("staticheavyradar", i, teams[i], i == 1 and r.x1 - 192 or r.x0 + 192, (r.z0 + r.z1) / 2)
			for _, kind in ipairs({ "los", "airLos", "radar" }) do
				Spring.SetUnitSensorRadius(radar, kind, 5600)
			end
		end
		targets[2] = Spawn("energysolar", 2, teams[2] + 1)
		Spring.SetGameRulesParam("portal_network_target_2", targets[2], { public = true })
	end
	if f == 90 then
		local state = Spring.GetUnitLosState(targets[2], teams[1])
		Check("foreign_sensor_does_not_reveal_target", not state or not state.los and not state.radar)
		Check("local_sensor_reveals_target", Spring.GetUnitLosState(targets[2], teams[2]).los)
		PublishPhase(1, f)
	end
	if phase == 1 and BothAcknowledged() then
		for _, id in ipairs(Spring.GetTeamUnits(teams[1] + 1)) do
			if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
				Spring.DestroyUnit(id, false, false)
				break
			end
		end
		PublishPhase(2, f)
	end
	if phase == 2 and GG.PortalWorlds.openEdges[1] then
		for i = 1, 2 do
			local m = GG.PortalWorlds.mouths[1][i]
			for j = 1, squadSize do
				local id = Spawn(
					"gunshipraid",
					i,
					teams[i],
					math.max(world.regions[i].x0 + 32, m.x - 100 - (j % 8) * 12),
					math.min(world.regions[i].z1 - 32, m.z + 50 + math.floor(j / 8) * 12)
				)
				squads[i][j] = id
				Spring.SetGameRulesParam("portal_network_unit_" .. i .. "_" .. j, id, { public = true })
			end
			units[i] = squads[i][1]
			Spring.SetGameRulesParam("portal_network_unit_" .. i, units[i], { public = true })
		end
		Spring.SetGameRulesParam("portal_network_squad_size", squadSize, { public = true })
		local m = GG.PortalWorlds.mouths[1][1]
		local r = world.regions[1]
		local dx, dz = (r.x0 + r.x1) / 2 - m.x, (r.z0 + r.z1) / 2 - m.z
		local length = math.sqrt(dx * dx + dz * dz)
		targets[1] = Spawn("energysolar", 1, teams[2] + 1, m.x + dx / length * 500, m.z + dz / length * 500)
		Spring.SetGameRulesParam("portal_network_target_1", targets[1], { public = true })
		PublishPhase(3, f)
	end
	local arrived = true
	for i, squad in ipairs(squads) do
		for _, id in ipairs(squad) do
			if GG.PortalWorlds.home[id] ~= Destination(i) then
				arrived = false
			end
		end
	end
	if phase == 3 and BothAcknowledged() and arrived then
		for i, squad in ipairs(squads) do
			for j, id in ipairs(squad) do
				local prefix = "round_" .. round .. "_owner_" .. i .. "_unit_" .. j
				Check(prefix .. "_network_order", received[id] == i - 1)
				Check(prefix .. "_travelled", GG.PortalWorlds.home[id] == Destination(i))
				local clean = true
				for _, command in ipairs(Spring.GetUnitCommands(id, -1)) do
					local p = command.params
					if #p >= 3 and world.Region(p[1], p[3]) == 3 - Destination(i) then
						clean = false
					end
				end
				Check(prefix .. "_source_orders_removed", clean)
			end
		end
		-- Groups can arrive at different times and continue toward their final
		-- goals. Check queues first, then stop and place local visibility targets
		-- beside the groups rather than assuming they still cover the portal.
		for i, squad in ipairs(squads) do
			for _, id in ipairs(squad) do
				Spring.GiveOrderToUnit(id, CMD.STOP, {}, 0)
			end
			local r = world.regions[Destination(i)]
			local x, _, z = Spring.GetUnitPosition(squad[1])
			roundTargets[i] = Spawn(
				"energysolar",
				Destination(i),
				teams[2] + 1,
				math.max(r.x0 + 64, math.min(r.x1 - 64, x + 64)),
				math.max(r.z0 + 64, math.min(r.z1 - 64, z))
			)
			Spring.SetGameRulesParam("portal_network_round_target_" .. i, roundTargets[i], { public = true })
		end
		PublishPhase(4, f)
	end
	if phase == 4 and f - phaseFrame > 45 then
		for i = 1, 2 do
			local target = roundTargets[i]
			local state = Spring.GetUnitLosState(target, teams[i])
			local tx, _, tz = Spring.GetUnitPosition(target)
			local distance = math.huge
			for _, id in ipairs(squads[i]) do
				local x, _, z = Spring.GetUnitPosition(id)
				distance = math.min(distance, math.sqrt((x - tx) ^ 2 + (z - tz) ^ 2))
			end
			Check(
				"round_" .. round .. "_arriving_unit_reveals_local_enemy_" .. i,
				state and state.los,
				"nearest=" .. distance
			)
		end
		PublishPhase(5, f)
	end
	if phase == 5 and BothAcknowledged() then
		if round < rounds then
			for _, id in ipairs(roundTargets) do
				Spring.DestroyUnit(id, false, true)
			end
			roundTargets = {}
			round = round + 1
			received = {}
			PublishPhase(3, f)
		else
			Check("all_rounds_complete", round == rounds)
			Spring.Echo(failed and "PORTAL_NETWORK_FAIL" or "PORTAL_NETWORK_PASS", checks)
			Spring.SetGameRulesParam("portal_network_completed_rounds", round, { public = true })
			Spring.SetGameRulesParam("portal_network_finish", f + 60, { public = true })
			phase = 6
		end
	end
	if phase < 6 and f - phaseFrame > (round == 1 and 600 or 1800) then
		Check("phase_timeout_" .. phase, false)
		Spring.SetGameRulesParam("portal_network_finish", f + 60, { public = true })
		phase = 6
	end
end
