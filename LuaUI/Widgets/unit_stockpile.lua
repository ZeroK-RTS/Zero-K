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

function widget:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
	if newCount < oldCount then
		-- We just launched a missile, so build a replacement.
		Spring.GiveOrderToUnit(unitID, CMD_STOCKPILE, EMPTY_TABLE, 0)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
