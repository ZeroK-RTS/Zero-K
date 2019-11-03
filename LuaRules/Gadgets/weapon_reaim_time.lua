function gadget:GetInfo()
	return {
		name      = "Weapon Reaim Time",
		desc      = "Implement weapon reaim time tag",
		author    = "GoogleFrog",
		date      = "4 February 2018",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

-------------------------------------------------------------
-------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then
	return false
end
-------------------------------------------------------------
-------------------------------------------------------------
local useRapidReaim = true
local minReaimTime = 1

-------------------------------------------------------------
-------------------------------------------------------------
local unitDefsToModify = {}

for udID = 1, #UnitDefs do
	local weapons = UnitDefs[udID].weapons
	for i = 1, #weapons do
		local wd = WeaponDefs[weapons[i].weaponDef]
		if wd and wd.customParams.reaim_time then
			unitDefsToModify[udID] = unitDefsToModify[udID] or {}
			unitDefsToModify[udID][i] = wd.customParams.reaim_time
		end
	end
end

-------------------------------------------------------------
-------------------------------------------------------------

local function UpdateRapidReaim(unitID, unitDefID)
	if not (unitDefID and unitDefsToModify[unitDefID]) then
		return
	end
	for weaponNum, reaimTime in pairs(unitDefsToModify[unitDefID]) do
		Spring.SetUnitWeaponState(unitID, weaponNum, {reaimTime = math.max(minReaimTime, (useRapidReaim and reaimTime) or 15)})
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if useRapidReaim then
		UpdateRapidReaim(unitID, unitDefID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Debug

local function ToggleReaimTime(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	
	if words[1] then
		useRapidReaim = (tonumber(words[1]) == 1)
	else
		useRapidReaim = not useRapidReaim
	end
	
	Spring.Echo("Rapid reaim " .. ((useRapidReaim and "enabled.") or "disabled."))
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitDefID = Spring.GetUnitDefID(units[i])
		UpdateRapidReaim(units[i], unitDefID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Init

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitDefID = Spring.GetUnitDefID(units[i])
		UpdateRapidReaim(units[i], unitDefID)
	end
	
	gadgetHandler:AddChatAction("debugreaim", ToggleReaimTime, "Debugs reaim time.")
end

--local START_TIME = 20*60*30
--local FLIP_PERIOD =60*30
--
--function gadget:GameFrame(n)
--	-- Performance test by switching during games.
--	if n < START_TIME then
--		return
--	end
--	if n%FLIP_PERIOD == 0 then
--		useRapidReaim = not useRapidReaim
--		Spring.Echo("useRapidReaim", useRapidReaim) -- Intentional
--		gadget:Initialize()
--	end
--end
