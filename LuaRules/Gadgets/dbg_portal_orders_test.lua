-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function gadget:GetInfo()
	return { name = "Portal order cancellation regression", layer = -100, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "orders" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local PORTAL = Spring.Utilities.CMD.PORTAL_TRAVEL
local RAW_MOVE = Spring.Utilities.CMD.RAW_MOVE
local cases = {
	{ name = "remove_portal", cmd = PORTAL, action = "remove" },
	{ name = "remove_move", cmd = RAW_MOVE, action = "remove" },
	{ name = "remove_fight", cmd = CMD.FIGHT, action = "remove" },
	{ name = "remove_attack", cmd = CMD.ATTACK, action = "remove" },
	{ name = "stop_portal", cmd = PORTAL, action = "stop" },
	{ name = "replace_portal", cmd = PORTAL, action = "replace" },
	{ name = "stop_move", cmd = RAW_MOVE, action = "stop" },
	{ name = "replace_move", cmd = RAW_MOVE, action = "replace" },
	{ name = "remove_portal_keep_tail", cmd = PORTAL, action = "remove", tail = "source" },
	{ name = "remove_move_keep_tail", cmd = RAW_MOVE, action = "remove", tail = "source" },
	{ name = "portal_keep_destination", cmd = PORTAL, tail = "destination", travels = true },
	{ name = "move_keep_destination", cmd = RAW_MOVE, tail = "destination", travels = true },
	{ name = "remove_approach_retries", cmd = PORTAL, action = "retry", travels = true },
	{ name = "remove_portal_at_mouth", cmd = PORTAL, action = "remove", late = true },
	{ name = "remove_move_at_mouth", cmd = RAW_MOVE, action = "remove", late = true },
	{ name = "interrupt_portal", cmd = PORTAL, action = "interrupt", resumes = true },
	{ name = "interrupt_move", cmd = RAW_MOVE, action = "interrupt", resumes = true },
	{ name = "cancel_interrupted_portal", cmd = PORTAL, action = "interrupt_remove" },
	{ name = "cancel_interrupted_move", cmd = RAW_MOVE, action = "interrupt_remove" },
}
local units, checks, failures = {}, 0, 0
local mouth, target
local function Check(name, value)
	checks = checks + 1
	if not value then
		failures = failures + 1
	end
	Spring.Echo("[ORDERS_TEST] ASSERT " .. name .. " pass=" .. tostring(not not value))
end
local function HasTag(id, tag)
	for _, command in ipairs(Spring.GetUnitCommands(id, -1)) do
		if command.tag == tag then
			return true
		end
	end
	return false
end
local function Place(id, x, z)
	local def = UnitDefs[Spring.GetUnitDefID(id)]
	if def.canFly then
		Spring.SetUnitPosition(id, x, 200 + def.wantedHeight, z)
	else
		GG.MoveMobileUnit(id, x, 200, z)
	end
	Spring.SetUnitVelocity(id, 0, 0, 0)
end
local function ChangeOrder(entry)
	local action, id = entry.case.action, entry.id
	if action == "remove" or action == "retry" then
		Spring.GiveOrderToUnit(id, CMD.REMOVE, { action == "remove" and entry.tag or entry.approachTag }, 0)
	elseif action == "stop" then
		Spring.GiveOrderToUnit(id, CMD.STOP, {}, 0)
	elseif action == "replace" then
		Spring.GiveOrderToUnit(id, CMD.MOVE, { mouth.x - 1000, 200, mouth.z }, 0)
	elseif action == "interrupt" or action == "interrupt_remove" then
		Spring.GiveOrderToUnit(id, CMD.INSERT, { 0, RAW_MOVE, 0, mouth.x - 1000, 200, mouth.z }, CMD.OPT_ALT)
		local _, _, tag = Spring.GetUnitCurrentCommand(id)
		entry.prefixTag = tag
		if action == "interrupt_remove" then
			Spring.GiveOrderToUnit(id, CMD.REMOVE, { entry.tag }, 0)
		end
	end
end
function gadget:GameFrame(frame)
	if frame == 1 then
		for _, r in ipairs(world.regions) do
			Spring.LevelHeightMap(r.x0, r.z0, r.x1, r.z1, 200)
		end
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
		end
	end
	if frame == 60 then
		for _, id in ipairs(Spring.GetTeamUnits(world.teams[2].team)) do
			if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
				local r = world.regions[1]
				Place(id, r.x0 + 2500, r.z0 + 2200)
				Spring.DestroyUnit(id, false, false)
				break
			end
		end
	end
	if frame == 120 then
		mouth = assert(GG.PortalWorlds.mouths[1][1], "Portal did not open")
		local r = world.regions[2]
		target = assert(Spring.CreateUnit("energysolar", r.x0 + 1200, 200, r.z0 + 1200, 0, 2))
		for _, kind in ipairs({ "cloakraid", "gunshipraid" }) do
			for i, case in ipairs(cases) do
				local id = assert(Spring.CreateUnit(kind, mouth.x - 900, 200, mouth.z + (i - 7) * 80, 0, 0))
				Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
				local params = case.cmd == PORTAL and { 1, 1 }
					or case.cmd == CMD.ATTACK and { target }
					or { r.x0 + 1500, 200, r.z0 + 2000 }
				Spring.GiveOrderToUnit(id, case.cmd, params, 0)
				local _, _, tag = Spring.GetUnitCurrentCommand(id)
				local entry = { id = id, case = case, name = kind .. "_" .. case.name, tag = tag }
				if case.tail then
					local tail = case.tail == "source" and world.regions[1] or r
					Spring.GiveOrderToUnit(
						id,
						CMD.MOVE,
						{ tail.x0 + 1600, 200, tail.z0 + 1800 },
						CMD.OPT_SHIFT
					)
					local queue = Spring.GetUnitCommands(id, -1)
					entry.tailTag = queue[#queue].tag
				end
				units[#units + 1] = entry
			end
		end
	end
	if frame == 145 then
		for _, entry in ipairs(units) do
			local cmd, _, approachTag = Spring.GetUnitCurrentCommand(entry.id)
			entry.approachTag = approachTag
			Check(
				entry.name .. "_approaching",
				cmd == RAW_MOVE and approachTag ~= entry.tag and HasTag(entry.id, entry.tag)
			)
		end
	end
	if frame == 150 then
		for _, entry in ipairs(units) do
			if not entry.case.late then
				ChangeOrder(entry)
			end
		end
	end
	if frame == 155 then
		for _, entry in ipairs(units) do
			if not entry.case.travels and not entry.case.late then
				Check(entry.name .. "_approach_removed", not HasTag(entry.id, entry.approachTag))
			end
		end
	end
	if frame == 180 then
		-- Put every unit within activation range, including cancelled travelers.
		-- Only entries whose original order survives should actually cross.
		for _, entry in ipairs(units) do
			if not entry.case.late then
				Place(entry.id, mouth.x - 100, mouth.z)
			end
		end
	end
	if frame == 181 then
		-- Cancellation immediately before activation must not wait for the next
		-- periodic queue check (frame 190).
		for _, entry in ipairs(units) do
			if entry.case.late then
				ChangeOrder(entry)
				Place(entry.id, mouth.x - 100, mouth.z)
			end
		end
	end
	if frame == 185 then
		for _, entry in ipairs(units) do
			if entry.case.late then
				Check(entry.name .. "_approach_removed", not HasTag(entry.id, entry.approachTag))
			end
		end
	end
	if frame == 240 then
		for _, entry in ipairs(units) do
			local expected = entry.case.travels and 2 or 1
			Check(entry.name .. "_region", GG.PortalWorlds.home[entry.id] == expected)
			if entry.tailTag then
				Check(entry.name .. "_tail_retained", HasTag(entry.id, entry.tailTag))
			end
			if entry.prefixTag then
				Check(entry.name .. "_inserted_waypoint_retained", HasTag(entry.id, entry.prefixTag))
				Check(
					entry.name .. "_original_order",
					HasTag(entry.id, entry.tag) == not not entry.case.resumes
				)
			end
		end
	end
	if frame == 245 then
		for _, entry in ipairs(units) do
			if entry.case.resumes then
				Spring.GiveOrderToUnit(entry.id, CMD.REMOVE, { entry.prefixTag }, 0)
			end
		end
	end
	if frame == 270 then
		for _, entry in ipairs(units) do
			if entry.case.resumes then
				Place(entry.id, mouth.x - 100, mouth.z)
			end
		end
	end
	if frame == 330 then
		for _, entry in ipairs(units) do
			if entry.case.resumes then
				Check(entry.name .. "_resumed_travel", GG.PortalWorlds.home[entry.id] == 2)
			end
		end
		Spring.Echo("[ORDERS_TEST] DONE checks=" .. checks .. " failures=" .. failures)
	end
end
