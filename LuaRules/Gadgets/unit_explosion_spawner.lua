-- $Id: unit_explosion_spawner.lua 3171 2008-11-06 09:06:29Z det $
function gadget:GetInfo()
	return {
		name = "Unit Explosion Spawner",
		desc = "Spawns units using an explosion as a trigger.",
		author = "KDR_11k (David Becker), lurker",
		date = "2007-11-18",
		license = "None",
		layer = 50,
		enabled = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then return end

local wantedList = {}
local spawn_defs_id = {}
local createList = {}
local expireList = {}

local GetUnitTeam = Spring.GetUnitTeam
local CreateFeature = Spring.CreateFeature
local CreateUnit = Spring.CreateUnit
local DestroyUnit = Spring.DestroyUnit
local SetUnitRulesParam = Spring.SetUnitRulesParam

local ALLY_ACCESS = {allied = true}

function gadget:Initialize()
	spawn_defs_id = VFS.Include("LuaRules/Configs/explosion_spawn_defs.lua")
	for weaponID, spawn_def in pairs (spawn_defs_id) do
		wantedList [#wantedList + 1] = weaponID
		Script.SetWatchWeapon (weaponID, true)
	end
end

function gadget:Explosion_GetWantedWeaponDef()
	return wantedList
end

function gadget:Explosion(w, x, y, z, owner)
	if spawn_defs_id[w] and owner then
		createList[#createList+1] = {
			name = spawn_defs_id[w].name,
			owner = GetUnitTeam(owner),
			x = x, y = y, z = z,
			expire = spawn_defs_id[w].expire,
			feature = spawn_defs_id[w].feature,
		}
		return false
	end
	return false
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	expireList[unitID] = nil
end

function gadget:GameFrame (f)
	local n = #createList
	for i = 1, n do
		local c = createList[i]
		if c.feature then
			CreateFeature (c.name, c.x, c.y, c.z, 0, c.owner)
		else
			local unitID = CreateUnit (c.name, c.x, c.y, c.z, 0, c.owner)
			if (c.expire > 0) and unitID then
				local timed_life = c.expire * 30
				expireList[unitID] = f + timed_life
				SetUnitRulesParam(unitID, "timed_life_duration", timed_life, ALLY_ACCESS)
				SetUnitRulesParam(unitID, "timed_life_end", f + timed_life, ALLY_ACCESS)
			end
		end
		createList[i] = nil
	end

	if ((f%30) == 7) then
		for i, e in pairs (expireList) do
			if (f > e) then
				DestroyUnit (i, true)
			end
		end
	end
end
