function widget:GetInfo() return {
	name      = "Rank Icons 2",
	desc      = "Adds a rank icon depending on experience next to units (needs Unit Icons)",
	author    = "trepan (idea quantum,jK), CarRepairer tweak, Sprung improve",
	date      = "Nov 2014", -- "Feb, 2008"
	license   = "GNU GPL, v2 or later",
	layer     = 5,
	enabled   = true,
} end

local FLASH_DURATION = 10
local rankTexBase = 'LuaUI/Images/Ranks/'
local rankTextures = {
	[0] = nil,
	[1] = rankTexBase .. 'rank1.png',
	[2] = rankTexBase .. 'rank2.png',
	[3] = rankTexBase .. 'rank3.png',
	[4] = rankTexBase .. 'star.png',
	-- [5] = rankTexBase .. 'gold_star.png',
}

local min   = math.min
local floor = math.floor
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spValidUnitID = Spring.ValidUnitID

local flashing_units = {}
local current_frame = 0

local function clear_icons (unitID)
	flashing_units [unitID] = nil
	WG.icons.SetUnitIcon (unitID, {
		name = 'rank',
		texture = nil,
	})
	WG.icons.SetUnitIcon (unitID, {
		name = 'rank_flashing',
		texture = nil,
	})
end

local function UnitRankUp (unitID)
	local rank = spGetUnitRulesParam (unitID, "rank")
	rank = min (#rankTextures, rank)
	clear_icons (unitID)

	WG.icons.SetUnitIcon (unitID, {
		name = 'rank_flashing',
		texture = rankTextures[rank]
	})
	flashing_units [unitID] = current_frame + 30*FLASH_DURATION
end

function widget:Initialize ()
	WG.icons.SetOrder ('rank', 1)
	WG.icons.SetOrder ('rank_flashing', 2)
	WG.icons.SetPulse( 'rank_flashing', true )
	widgetHandler:RegisterGlobal ('UnitRankUp', UnitRankUp)

	local allUnits = Spring.GetAllUnits()
	for _,unitID in pairs (allUnits) do
		UpdateUnitRank (unitID)
	end
end

function UpdateUnitRank (unitID)
	local rank = spGetUnitRulesParam (unitID, "rank")
	rank = min (#rankTextures, rank)
	clear_icons (unitID)

	WG.icons.SetUnitIcon (unitID, {
		name = 'rank',
		texture = rankTextures[rank]
	})
end

function widget:GameFrame (frame)
	if ((frame % 30) == 0) then
		current_frame = frame
		for unitID, timer in pairs (flashing_units) do
			if not spValidUnitID(unitID) then
				flashing_units [unitID] = nil
			elseif timer < frame then
				local rank = spGetUnitRulesParam (unitID, "rank")
				rank = min (#rankTextures, rank)
				WG.icons.SetUnitIcon (unitID, {
					name = 'rank',
					texture = rankTextures[rank],
				})
				WG.icons.SetUnitIcon (unitID, {
					name = 'rank_flashing',
					texture = nil,
				})
			end
		end
	end
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
