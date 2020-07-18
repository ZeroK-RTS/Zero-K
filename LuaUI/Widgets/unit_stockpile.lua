--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_stockpile.lua
--  brief:   adds 100 builds to all new units that can stockpile
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Stockpiler",
		desc      = "Automatically adds 100 stockpile builds to new units",
		author    = "trepan",
		date      = "Jan 8, 2007",
		license   = "GNU GPL, v2 or later",
		layer     = 2, -- after unit_start_state.lua
		enabled   = true  --  loaded by default?
	}
end

options_path = "Settings/Unit Behaviour/Default States/Missile Stockpilers"
options = {}
for id,ud in pairs(UnitDefs) do
	if ud.canStockpile then
		options[ud.name .. "_missiles"] = {
			name = ud.humanName .. " missiles",
			desc = "Unit will build missiles whenever it has fewer than this in stock.",
			type = "number",
			value = (ud.name == "turretaaheavy" and 100 or 10),
			min = 0,
			max = 100,
			tooltip_format = "%.0f",
			noHotkey = true,
		}
	end
end

local CMD_STOCKPILE = CMD.STOCKPILE
local EMPTY_TABLE = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
	 if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		Spring.Echo("<Stockpiler>: disabled for spectators")
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if ((ud ~= nil) and (unitTeam == Spring.GetMyTeamID())) then
		if (ud.canStockpile) then
			local stocked, queued = Spring.GetUnitStockpile(unitID)
			local wanted = options[ud.name .. "_missiles"].value
			local to_add = wanted - stocked - queued
			for i = 1, to_add do
				Spring.GiveOrderToUnit(unitID, CMD.STOCKPILE, EMPTY_TABLE, 0)
			end
		end
	end
end

function widget:GameFrame(n)
	if n > 1 then
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
		end
		widgetHandler:RemoveCallIn("GameFrame")
	end
end

function widget:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
	if newCount < oldCount then
		-- We just launched a missile, so build a replacement.
		Spring.GiveOrderToUnit(unitID, CMD_STOCKPILE, EMPTY_TABLE, 0)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
