function widget:GetInfo() return {
	name      = "Rank Icons 2",
	desc      = "Adds a rank icon depending on experience next to units (needs Unit Icons)",
	author    = "trepan (idea quantum,jK), CarRepairer tweak",
	date      = "Feb, 2008",
	license   = "GNU GPL, v2 or later",
	layer     = 5,
	enabled   = true,  -- loaded by default?
} end

local min   = math.min
local floor = math.floor

local rankTexBase = 'LuaUI/Images/Ranks/'
local rankTextures = {
	[0] = nil,
	[1] = rankTexBase .. 'rank1.png',
	[2] = rankTexBase .. 'rank2.png',
	[3] = rankTexBase .. 'rank3.png',
	[4] = rankTexBase .. 'star.png',
}

local XP_PER_RANK

function widget:Initialize ()
	WG.icons.SetOrder ('rank', 1)
	XP_PER_RANK = Spring.GetGameRulesParam ("xp_per_rank")

	local allUnits = Spring.GetAllUnits()
	for _,unitID in pairs (allUnits) do
		UpdateUnitRank (unitID)
	end
end

function UpdateUnitRank (unitID)
	local rank = spGetUnitRulesParam (unitID, "rank")
	WG.icons.SetUnitIcon (unitID, {name='rank', texture=rankTextures[xp]})
end

function widget:UnitExperience(unitID, unitDefID, unitTeam, newXP, oldXP)
	newXP = newXP / XP_PER_RANK
	oldXP = oldXP / XP_PER_RANK
	if (oldXP ~= newXP) then
		WG.icons.SetUnitIcon (unitID, {name='rank', texture=rankTextures[newXP]})
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	UpdateUnitRank (unitID)
end

function widget:UnitEnteredLos(unitID, unitTeam)
	UpdateUnitRank (unitID)
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
	WG.icons.SetUnitIcon( unitID, {name='rank', texture=nil} )
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	WG.icons.SetUnitIcon( unitID, {name='rank', texture=nil} )
end
