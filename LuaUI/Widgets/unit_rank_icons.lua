function widget:GetInfo() return {
	name      = "Rank Icons 2",
	desc      = "Adds a rank icon depending on experience next to units (needs Unit Icons)",
	author    = "trepan (idea quantum,jK), CarRepairer tweak, Sprung improve",
	date      = "Nov 2014", -- "Feb, 2008"
	license   = "GNU GPL, v2 or later",
	layer     = 5,
	enabled   = true,
} end

local min   = math.min
local floor = math.floor
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local clearing_table = {
	name = 'rank',
	texture = nil
}

local rankTexBase = 'LuaUI/Images/Ranks/'
local rankTextures = {
	[0] = nil,
	[1] = rankTexBase .. 'rank1.png',
	[2] = rankTexBase .. 'rank2.png',
	[3] = rankTexBase .. 'rank3.png',
	[4] = rankTexBase .. 'star.png',
	-- [5] = rankTexBase .. 'gold_star.png',
}

local function UnitRankUp (unitID)
	UpdateUnitRank (unitID)
end

function widget:Initialize ()
	WG.icons.SetOrder ('rank', 1)
	widgetHandler:RegisterGlobal ('UnitRankUp', UnitRankUp)

	local allUnits = Spring.GetAllUnits()
	for _,unitID in pairs (allUnits) do
		UpdateUnitRank (unitID)
	end
end

function UpdateUnitRank (unitID)
	local rank = spGetUnitRulesParam (unitID, "rank")
	rank = min (#rankTextures, rank)
	WG.icons.SetUnitIcon (unitID, {
		name = 'rank',
		texture = rankTextures[rank]
	})
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	UpdateUnitRank (unitID)
end

function widget:UnitEnteredLos(unitID, unitTeam)
	UpdateUnitRank (unitID)
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
	WG.icons.SetUnitIcon (unitID, clearing_table)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	WG.icons.SetUnitIcon (unitID, clearing_table)
end
