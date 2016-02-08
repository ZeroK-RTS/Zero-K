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

local spGetSpectatingState = Spring.GetSpectatingState

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
	[5] = rankTexBase .. 'star.png',
	[6] = rankTexBase .. 'star.png',
	[7] = rankTexBase .. 'goldstar.png',
	[8] = rankTexBase .. 'goldstar.png',
	[9] = rankTexBase .. 'goldstar.png',
	[10] = rankTexBase .. 'goldeverything.png',
}

function widget:Initialize ()
	WG.icons.SetOrder ('rank', 1)

	local allUnits = Spring.GetAllUnits()
	for _,unitID in pairs (allUnits) do
		UpdateUnitRank (unitID)
	end
end

function UpdateUnitRank (unitID)
	local rank = math.floor(0.01 + (Spring.GetUnitExperience(unitID) or 0)) -- 0.01 for float errors
	rank = min(#rankTextures or 0, rank)
	WG.icons.SetUnitIcon (unitID, {
		name = 'rank',
		texture = rankTextures[rank]
	})
end

function widget:UnitExperience(unitID)
	UpdateUnitRank(unitID)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	UpdateUnitRank(unitID)
end

function widget:UnitEnteredLos(unitID, unitTeam)
	UpdateUnitRank(unitID)
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
	if not spGetSpectatingState() then
		WG.icons.SetUnitIcon(unitID, clearing_table)
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	WG.icons.SetUnitIcon(unitID, clearing_table)
end
