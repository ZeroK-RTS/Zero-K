local function GetLeftRightAllyTeamIDs()
    if Spring.Utilities.Gametype.isFFA() or Spring.Utilities.Gametype.isSandbox() then
        -- not 2 teams: unhandled by spec panels
        return {}
    end


    local myAllyTeamID = 0--Spring.GetLocalAllyTeamID()
    local enemyAllyTeamID = 1 -- FIXME assumes teams are 0 and 1
    local myTeamID = Spring.GetTeamList(myAllyTeamID)[1]--Spring.GetLocalTeamID()

    local myBoxID = Spring.GetTeamRulesParam(myTeamID, "start_box_id")
    if not myBoxID then -- can start anywhere
        return {0, 1} -- players see themselves on the left, maybe should `return 0, 1` (see fixme above) so everybody sees everything the same?
    end

    local myBoxRepresentativeSpotX = Spring.GetGameRulesParam("startpos_x_" .. myBoxID .. "_1")

    local comparisonX
    if Spring.GetGameRulesParam("shuffleMode") == "allshuffle" and Spring.GetGameRulesParam("startbox_max_n") > 1 then
        -- there are multiple boxes the enemy can be in so just look where we are on the map
        comparisonX = Game.mapSizeX / 2
    else
        local enemyBoxID = 1 - myBoxID
        comparisonX = Spring.GetGameRulesParam("startpos_x_" .. enemyBoxID .. "_1")
    end

    if myBoxRepresentativeSpotX <= comparisonX then
        return {myAllyTeamID, enemyAllyTeamID}
    else
        return {enemyAllyTeamID, myAllyTeamID}
    end
end

return GetLeftRightAllyTeamIDs