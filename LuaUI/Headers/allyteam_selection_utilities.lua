local function GetLeftRightAllyTeamIDs()
	if Spring.Utilities.Gametype.isFFA() or Spring.Utilities.Gametype.isSandbox() then
		-- not 2 teams: unhandled by spec panels
		return {}
	end

	local myAllyTeamID = 0 -- FIXME Spring.GetLocalAllyTeamID()
	local enemyAllyTeamID = 1 -- FIXME assumes teams are 0 and 1
	local myTeamID = Spring.GetTeamList(myAllyTeamID)[1] -- FIXME Spring.GetLocalTeamID()

	local myBoxID = Spring.GetTeamRulesParam(myTeamID, "start_box_id")
	if not myBoxID then -- can start anywhere
		--[[ FIXME: since allyteam is hardcoded to 0 this can also mean we're in in allyteam 1+
		     and just can't read allyteam 0's box, but since currently this func's result is
		     only really used by specs so it's not apparent ]]
		return {0, 1}
	end

	local myBoxRepresentativeSpotX = Spring.GetGameRulesParam("startpos_x_" .. myBoxID .. "_1")

	local comparisonX
	if Spring.GetGameRulesParam("shuffleMode") == "allshuffle" and Spring.GetGameRulesParam("startbox_max_n") > 1 then
		-- there are multiple boxes the enemy can be in so just look where we are on the map
		-- FIXME 1: if fullview spec, should just compare to enemy box directly
		-- FIXME 2: else it should compare to the remaining boxes, not the map center
		comparisonX = Game.mapSizeX / 2
	else
		local enemyBoxID = 1 - myBoxID -- FIXME: assumes boxIDs are 0 and 1 and that there are at least 2 boxes
		comparisonX = Spring.GetGameRulesParam("startpos_x_" .. enemyBoxID .. "_1")
	end

	if (not myBoxRepresentativeSpotX) or (myBoxRepresentativeSpotX <= comparisonX) then
		return {myAllyTeamID, enemyAllyTeamID}
	else
		return {enemyAllyTeamID, myAllyTeamID}
	end
end

return GetLeftRightAllyTeamIDs
