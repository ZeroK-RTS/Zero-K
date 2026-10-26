-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function widget:GetInfo()
	return { name = "Portal network player verification", layer = 10010, enabled = true }
end
if Spring.GetModOptions().zk_duels_test ~= "network" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local completed = {}
local region = Spring.GetMyPlayerID() == 0 and 1 or 2
local function Check(name, value)
	Spring.Echo("[NETWORK_UI] ASSERT " .. name .. " pass=" .. tostring(not not value))
end
function widget:Update()
	local f = Spring.GetGameFrame()
	if f == 0 and Spring.GetMyPlayerID() == 0 then
		local count = 0
		for _, id in ipairs(Spring.GetPlayerList()) do
			if select(2, Spring.GetPlayerInfo(id, false)) then
				count = count + 1
			end
		end
		if count == 2 then
			Spring.SendCommands("forcestart")
		end
	end
	local phase = Spring.GetGameRulesParam("portal_network_phase")
	local round = Spring.GetGameRulesParam("portal_network_round") or 1
	local key = tostring(phase) .. ":" .. round
	local destination = round % 2 == 1 and 3 - region or region
	if phase and not completed[key] then
		if phase == 1 then
			Check("sensor_setter_not_available_to_player", Spring.SetSensorRegions == nil)
			local target = Spring.GetGameRulesParam("portal_network_target_2")
			Check("player_visibility_before_portal", (Spring.GetUnitDefID(target) ~= nil) == (region == 2))
			Check(
				"view_locked_to_home",
				WG.PortalWorldView
					and WG.PortalWorldView.region == region
					and not WG.PortalAccessible(3 - region)
			)
			Spring.Echo("[NETWORK_LOCAL_VIEW] " .. region)
		elseif phase == 3 then
			local squad = {}
			for j = 1, Spring.GetGameRulesParam("portal_network_squad_size") or 1 do
				local id = Spring.GetGameRulesParam("portal_network_unit_" .. region .. "_" .. j)
				if not id then
					return
				end
				squad[#squad + 1] = id
			end
			local r, own = world.regions[destination], world.regions[3 - destination]
			Spring.GiveOrderToUnitArray(squad, CMD.MOVE, { (r.x0 + r.x1) / 2, 0, (r.z0 + r.z1) / 2 }, 0)
			Spring.GiveOrderToUnitArray(
				squad,
				CMD.MOVE,
				{ (own.x0 + own.x1) / 2, 0, (own.z0 + own.z1) / 2 },
				CMD.OPT_SHIFT
			)
			Spring.GiveOrderToUnitArray(
				squad,
				CMD.MOVE,
				{ (r.x0 + r.x1) / 2 + 100, 0, (r.z0 + r.z1) / 2 },
				CMD.OPT_SHIFT
			)
		elseif phase == 5 then
			Check("round_" .. round .. "_destination_view_unlocked", WG.PortalDuelsView(destination))
			local target = Spring.GetGameRulesParam("portal_network_round_target_" .. region)
			Check("round_" .. round .. "_player_visibility_after_arrival", Spring.GetUnitDefID(target) ~= nil)
			Spring.Echo("[NETWORK_LOCAL_VIEW] " .. destination)
		end
		completed[key] = true
		Spring.SendLuaRulesMsg("portal_network_" .. phase)
	end
	local finish = Spring.GetGameRulesParam("portal_network_finish")
	if finish and f >= finish then
		Spring.SendCommands("quitforce")
	end
end
