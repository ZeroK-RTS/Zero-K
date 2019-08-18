
-- Every AI that wishes to use CAI must be entered here using the name from LuaAI.lua
-- Each AI must have these things:
--	controlFunction, a function that takes aiTeamData and frame as input and changes the weights.
--	buildConfig, an array of weighted build chances.
--	raiderBattlegroupCondition, the conditions that must be met to form a raider battlegroup
--	combatBattlegroupCondition, the conditions that must be met to form a combat battlegroup

aiConfigByName =
{
	["CAI"] =
	{
		controlFunction = constructionAndEconomyHandler,
		buildConfig = factionBuildConfig,
		raiderBattlegroupCondition = battleGroupCondition1,
		combatBattlegroupCondition = battleGroupCondition2,
		gunshipBattlegroupCondition = battleGroupCondition3,
	},
}
	
