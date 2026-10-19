-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function gadget:GetInfo()
	return { name = "Portal special mechanics regression", layer = -100, enabled = true }
end
local options = Spring.GetModOptions()
local baseline = options.zk_duels_test == "mechanics-baseline"
if options.zk_duels_test ~= "mechanics" and not baseline then
	return false
end
if not gadgetHandler:IsSyncedCode() then
	if not baseline then
		return false
	end
	local started = false
	function gadget:Update()
		if not started and Spring.GetGameFrame() > 0 then
			started = true
			Spring.SendCommands("setspeed " .. (options.zk_duels_speed or 1))
		end
		if Spring.GetGameRulesParam("portal_mechanics_baseline_done") == 1 then
			Spring.SendCommands("quitforce")
		end
	end
	return
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
	or { regions = { { x0 = 0, z0 = 0, x1 = Game.mapSizeX, z1 = Game.mapSizeZ } } }
local commands = Spring.Utilities.CMD
local djinn, beacon, passenger, remoteDjinn, remoteBeacon, remotePassenger, travellingDjinn, oldBeacon, waitingUnit
local oldX, oldZ
local insertedPassenger, shiftedPassenger
local terraformUnits = 0
local shield, shieldBeam, shieldCalls = nil, nil, {}
local nativeShieldCalls, nativeShieldCharge
local failures = 0
local function Check(name, pass, detail)
	if not pass then
		failures = failures + 1
	end
	Spring.Echo(
		"[MECHANICS_TEST] ASSERT " .. name .. " pass=" .. tostring(not not pass) .. " " .. (detail or "")
	)
end
local function Spawn(name, region, x, z, team)
	local r = world.regions[region]
	x, z = r.x0 + x, r.z0 + z
	local id = Spring.CreateUnit(name, x, Spring.GetGroundHeight(x, z), z, 0, team or 0)
	assert(id, "Could not spawn " .. name .. " in region " .. region)
	Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
	Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, { 0 }, 0)
	return id
end
local function Link(id, bid)
	local x, _, z = Spring.GetUnitPosition(bid)
	GG.tele_createBeacon(id, UnitDefNames.amphtele.id, x, z, bid)
end
local function Deploy(id)
	Spring.UnitScript.CallAsUnit(id, Spring.UnitScript.GetScriptEnv(id).DeployTeleportInstant)
end
function gadget:ShieldPreDamaged(id, owner, weapon, carrier)
	shieldCalls[carrier] = (shieldCalls[carrier] or 0) + 1
	return false
end
local function TerraformAPIChecks(con)
	local r = world.regions[2]
	local points = {
		{ x = r.x0 + 2800, z = r.z0 + 3000 },
		{ x = r.x0 + 2900, z = r.z0 + 3000 },
		{ x = r.x0 + 2900, z = r.z0 + 3100 },
		{ x = r.x0 + 2800, z = r.z0 + 3100 },
	}
	for _, kind in ipairs({ "TerraformArea", "TerraformWall" }) do
		local before = terraformUnits
		GG.Terraform[kind](1, points, 4, 300, { con }, 1, 0, 0, false, r.x0 + 2850, r.z0 + 3050, 8010)
		Check("foreign_scripted_" .. kind .. "_rejected", terraformUnits == before)
	end
	local before = terraformUnits
	GG.Terraform.TerraformRamp(
		r.x0 + 2000,
		200,
		r.z0 + 3000,
		r.x0 + 2400,
		300,
		r.z0 + 3000,
		100,
		{ con },
		1,
		0,
		0,
		false,
		r.x0 + 2200,
		r.z0 + 3000,
		8011
	)
	Check("foreign_scripted_ramp_rejected", terraformUnits == before)
	before = terraformUnits
	GG.Terraform.TerraformRamp(
		1700,
		200,
		3000,
		2100,
		260,
		3000,
		100,
		{ con },
		1,
		0,
		0,
		false,
		1900,
		3000,
		8012
	)
	Check("local_scripted_ramp_created", terraformUnits > before)
	before = terraformUnits
	GG.Terraform.TerraformWall(
		2,
		{ { x = 2300, z = 3000 }, { x = 2500, z = 3000 } },
		2,
		30,
		{ con },
		1,
		0,
		0,
		false,
		2400,
		3000,
		8013
	)
	Check("local_scripted_wall_created", terraformUnits > before)
	before = terraformUnits
	GG.Terraform.TerraformRamp(
		4000,
		200,
		3000,
		4000,
		260,
		3300,
		300,
		{ con },
		1,
		0,
		0,
		false,
		4000,
		3150,
		8014
	)
	Check("ramp_width_cannot_cross_map_edge", terraformUnits == before)
	local voidX = (world.regions[1].x1 + world.regions[2].x0) / 2
	Check("terraform_cannot_spread_into_barrier", not GG.Terraform.IsPositionTerraformable(voidX, 2000, true))
end
function gadget:UnitCreated(id, def)
	if def == UnitDefNames.terraunit.id then
		terraformUnits = terraformUnits + 1
	end
end
local function Terraform(con, region, tag)
	local r = world.regions[region]
	local x, z = r.x0 + 3100, r.z0 + 3100
	local p = {
		1,
		0,
		x,
		z,
		tag,
		1,
		300,
		5,
		1,
		0,
		x - 48,
		z - 48,
		x - 48,
		z + 48,
		x + 48,
		z + 48,
		x + 48,
		z - 48,
		x - 48,
		z - 48,
		con,
	}
	local before = terraformUnits
	Spring.GiveOrderToUnit(con, commands.TERRAFORM_INTERNAL, p, 0)
	return terraformUnits - before, x, z
end
function gadget:GameFrame(f)
	if f == 1 then
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
		end
		for _, r in ipairs(world.regions) do
			Spring.LevelHeightMap(r.x0 + 800, r.z0 + 800, r.x0 + 3400, r.z0 + 3400, 200)
		end
	end
	if f == 60 then
		if baseline then
			Check("portal_mode_absent", GG.PortalWorlds == nil and GG.PortalIsolation == nil)
		end
		local con = Spawn("cloakcon", 1, 3100, 2800)
		local localCount, lx, lz = Terraform(con, 1, 8001)
		Check("local_terraform_created", localCount > 0)
		GG.Terraform.ForceTerraformCompletion(false)
		Check("local_terraform_changed_ground", Spring.GetGroundHeight(lx, lz) > 250)
		if not baseline then
			local count, rx, rz = Terraform(con, 2, 8002)
			Check("foreign_terraform_command_rejected", count == 0)
			GG.Terraform.ForceTerraformCompletion(false)
			Check(
				"foreign_terraform_did_not_change_ground",
				math.abs(Spring.GetGroundHeight(rx, rz) - 200) < 0.1
			)
			TerraformAPIChecks(con)
		end
		djinn = Spawn("amphtele", 1, 1200, 1200)
		beacon = Spawn("tele_beacon", 1, 2000, 1200)
		passenger = Spawn("cloakraid", 1, 2000, 1200)
		Link(djinn, beacon)
		if not baseline then
			remoteDjinn = Spawn("amphtele", 1, 1200, 2400)
			local r = world.regions[2]
			Spring.GiveOrderToUnit(remoteDjinn, commands.PLACE_BEACON, { r.x0 + 2400, 200, r.z0 + 2400 }, 0)
			Check("remote_beacon_placement_order_rejected", #Spring.GetUnitCommands(remoteDjinn, -1) == 0)
			remoteBeacon = Spawn("tele_beacon", 2, 2800, 1600)
			Link(remoteDjinn, remoteBeacon)
			Check(
				"scripted_foreign_beacon_link_rejected",
				Spring.GetUnitRulesParam(remoteBeacon, "connectto") ~= remoteDjinn
			)
			remotePassenger = Spawn("cloakraid", 1, 2400, 2400)
			Spring.GiveOrderToUnit(remotePassenger, commands.WAIT_AT_BEACON, { remoteBeacon }, 0)
			Check("remote_beacon_wait_order_rejected", #Spring.GetUnitCommands(remotePassenger, -1) == 0)
			for _, id in ipairs(Spring.GetTeamUnits(1)) do
				if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
					Spring.DestroyUnit(id, false, false)
					break
				end
			end
		end
	end
	if f == 90 then
		Deploy(djinn)
		Spring.GiveOrderToUnit(passenger, commands.WAIT_AT_BEACON, { beacon }, 0)
		insertedPassenger = Spawn("cloakraid", 1, 2000, 1200)
		shiftedPassenger = Spawn("cloakraid", 1, 2000, 1200)
		Spring.GiveOrderToUnit(
			insertedPassenger,
			CMD.INSERT,
			{ 0, commands.WAIT_AT_BEACON, 0, beacon },
			CMD.OPT_ALT
		)
		local queue = Spring.GetUnitCommands(insertedPassenger, -1)
		Check("inserted_local_djinn_wait_accepted", queue[1] and queue[1].id == commands.WAIT_AT_BEACON)
		Spring.GiveOrderToUnit(shiftedPassenger, CMD.WAIT, {}, 0)
		Spring.GiveOrderToUnit(shiftedPassenger, commands.WAIT_AT_BEACON, { beacon }, CMD.OPT_SHIFT)
	end
	if f == 120 then
		Spring.GiveOrderToUnit(shiftedPassenger, CMD.WAIT, {}, 0)
	end
	if f == 180 and not baseline then
		local beam = Spawn("turretlaser", 3, 1800, 2400, 2)
		shieldBeam = beam
		local foreign = Spawn("turretlaser", 4, 1800, 2400, 2)
		shield = Spawn("staticshield", 3, 2200, 2400)
		Spring.SetUnitShieldState(shield, -1, true, 3000)
		local _, before = Spring.GetUnitShieldState(shield)
		local bx, by, bz = Spring.GetUnitPosition(beam)
		local sx, sy, sz = Spring.GetUnitPosition(shield)
		local handled = gadgetHandler.gadgetHandler:ShieldPreDamaged(
			-1,
			foreign,
			1,
			shield,
			false,
			1,
			foreign,
			bx,
			by + 30,
			bz,
			sx - 350,
			sy + 30,
			sz
		)
		Check("foreign_beam_shield_callback_blocked", handled and not shieldCalls[shield])
		Check("foreign_beam_preserves_shield_charge", select(2, Spring.GetUnitShieldState(shield)) == before)
		local x, y, z = Spring.GetUnitPosition(foreign)
		local projectile = Spring.SpawnProjectile(
			WeaponDefNames.vehassault_plasma.id,
			{ pos = { x, y + 100, z }, speed = { 0, 0, 0 }, owner = foreign, ttl = 300 }
		)
		handled = gadgetHandler.gadgetHandler:ShieldPreDamaged(
			projectile,
			foreign,
			1,
			shield,
			false,
			nil,
			nil,
			bx,
			by + 30,
			bz,
			sx - 350,
			sy + 30,
			sz
		)
		Check("foreign_projectile_shield_callback_blocked", handled and not shieldCalls[shield])
		Check(
			"foreign_projectile_preserves_shield_charge",
			select(2, Spring.GetUnitShieldState(shield)) == before
		)
		Spring.DeleteProjectile(projectile)
		gadgetHandler.gadgetHandler:ShieldPreDamaged(
			-1,
			beam,
			1,
			shield,
			false,
			1,
			beam,
			bx,
			by + 30,
			bz,
			sx - 350,
			sy + 30,
			sz
		)
		Check("local_beam_shield_callback_runs", shieldCalls[shield] == 1)
		nativeShieldCalls = shieldCalls[shield]
		nativeShieldCharge = select(2, Spring.GetUnitShieldState(shield))
		Spring.GiveOrderToUnit(beam, CMD.FIRE_STATE, { 2 }, 0)
		Spring.GiveOrderToUnit(beam, CMD.ATTACK, { shield }, 0)
	end
	if f == 300 then
		if not baseline then
			Check("native_beam_hits_local_shield", (shieldCalls[shield] or 0) > nativeShieldCalls)
			Check(
				"native_beam_drains_local_shield",
				select(2, Spring.GetUnitShieldState(shield)) < nativeShieldCharge
			)
			Spring.GiveOrderToUnit(shieldBeam, CMD.FIRE_STATE, { 0 }, 0)
		end
		local x, _, z = Spring.GetUnitPosition(passenger)
		local tx, _, tz = Spring.GetUnitPosition(djinn)
		Check(
			"ordinary_local_djinn_teleport_works",
			(x - tx) ^ 2 + (z - tz) ^ 2 < 200 ^ 2,
			"distance=" .. math.sqrt((x - tx) ^ 2 + (z - tz) ^ 2)
		)
		for i, id in ipairs({ insertedPassenger, shiftedPassenger }) do
			local px, _, pz = Spring.GetUnitPosition(id)
			Check("queued_local_djinn_transit_" .. i, (px - tx) ^ 2 + (pz - tz) ^ 2 < 200 ^ 2)
		end
		if baseline then
			Spring.SetGameRulesParam("portal_mechanics_baseline_done", 1)
			if options.zk_duels_save == "1" then
				Spring.Echo("[FULL_SAVELOAD] BASELINE_DONE failures=" .. failures)
				Spring.SetGameRulesParam("portal_save_loaded_done", failures == 0 and 1 or 0)
			end
			return
		end
		local m = GG.PortalWorlds.mouths[1][1]
		oldX = math.max(world.regions[1].x0 + 300, math.min(world.regions[1].x1 - 300, m.x + 400))
		oldZ = math.max(world.regions[1].z0 + 300, math.min(world.regions[1].z1 - 300, m.z + 400))
		travellingDjinn = assert(Spring.CreateUnit("amphtele", m.x, m.y, m.z, 0, 0))
		oldBeacon = Spawn("tele_beacon", 1, oldX, oldZ)
		waitingUnit = Spawn("cloakraid", 1, oldX, oldZ)
		Link(travellingDjinn, oldBeacon)
		Spring.GiveOrderToUnit(waitingUnit, CMD.WAIT, {}, 0)
		Spring.GiveOrderToUnit(waitingUnit, commands.WAIT_AT_BEACON, { oldBeacon }, CMD.OPT_SHIFT)
		Check("stale_djinn_wait_initially_local", #Spring.GetUnitCommands(waitingUnit, -1) == 2)
		Spring.GiveOrderToUnit(travellingDjinn, commands.PORTAL_TRAVEL, { 1, 1 }, 0)
	end
	if f == 600 then
		Check("djinn_crossed_open_portal", GG.PortalWorlds.home[travellingDjinn] == 2)
		Deploy(travellingDjinn)
		Spring.GiveOrderToUnit(waitingUnit, CMD.WAIT, {}, 0)
	end
	if f == 900 then
		Check("djinn_foreign_link_cannot_deploy", Spring.GetUnitRulesParam(travellingDjinn, "deploy") ~= 1)
		Check("stale_djinn_wait_order_removed", #Spring.GetUnitCommands(waitingUnit, -1) == 0)
		local x, _, z = Spring.GetUnitPosition(waitingUnit)
		Check("stale_djinn_link_did_not_move_waiting_unit", (x - oldX) ^ 2 + (z - oldZ) ^ 2 < 200 ^ 2)
	end
end
