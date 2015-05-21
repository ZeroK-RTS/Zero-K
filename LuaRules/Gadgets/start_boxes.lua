if (not gadgetHandler:IsSyncedCode()) then return end

function gadget:GetInfo() return {
	name     = "Startbox handler",
	desc     = "Handles startboxes",
	author   = "Sprung",
	date     = "2015-05-19",
	license  = "PD",
	layer    = -1,
	enabled  = true,
} end

--[[ Usage:
	* there is a "startboxes" modoption that contains a table (parse it using loadstring, see below)
	* each team can have a private TeamRulesParam called "start_box_id". This is the index of its box in the startbox table
	* no ID means there is no box (ie. can place anywhere)
	* boxes are normalised to 0..1 - multiply by Game.mapSizeX and Z to get the actual co-ordinates
]]

local startboxString = Spring.GetModOptions().startboxes
if not startboxString then return end -- missions

local startboxConfig = loadstring(startboxString)()

function gadget:Initialize()

	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))

	-- filter out fake teams (empty or Gaia)
	local allyTeamList = Spring.GetAllyTeamList()
	local actualAllyTeamList = {}
	for i = 1, #allyTeamList do
		local teamList = Spring.GetTeamList(allyTeamList[i]) or {}
		if ((#teamList > 0) and (allyTeamList[i] ~= gaiaAllyTeamID)) then
			actualAllyTeamList[#actualAllyTeamList+1] = allyTeamList[i]
		end
	end

	local shuffleMode = Spring.GetModOptions().shuffle or "off"

	if (shuffleMode == "off") then

		for i = 1, #allyTeamList do
			local allyTeamID = allyTeamList[i]
			if startboxConfig[allyTeamID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", allyTeamID)
				end
			end
		end

	elseif (shuffleMode == "shuffle") then

		local randomizedSequence = {}
		for i = 1, #actualAllyTeamList do
			randomizedSequence[#randomizedSequence + 1] = {actualAllyTeamList[i], math.random()}
		end
		table.sort(randomizedSequence, function(a, b) return (a[2] < b[2]) end)

		for i = 1, #actualAllyTeamList do
			local allyTeamID = actualAllyTeamList[i]
			local boxID = randomizedSequence[i][1]
			if startboxConfig[boxID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", boxID)
				end
			end
		end

	elseif (shuffleMode == "allshuffle") then

		local randomizedSequence = {}
		for id in pairs(startboxConfig) do
			randomizedSequence[#randomizedSequence + 1] = {id, math.random()}
		end
		table.sort(randomizedSequence, function(a, b) return (a[2] < b[2]) end)

		for i = 1, #actualAllyTeamList do
			local allyTeamID = actualAllyTeamList[i]
			local boxID = randomizedSequence[i][1]
			if startboxConfig[boxID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", boxID)
				end
			end
		end
	end
end

function gadget:AllowStartPosition(x, y, z, playerID, readyState)
	if (playerID == 255) then
		return false -- custom AI, cannot get its teamID so block it
	end

	local teamID = select(4, Spring.GetPlayerInfo(playerID))
	local boxID = Spring.GetTeamRulesParam(teamID, "start_box_id")

	if not boxID then
		Spring.SetTeamRulesParam(teamID, "valid_startpos", 1)
		return true
	end

	local box = startboxConfig[boxID]
	x = x / Game.mapSizeX
	z = z / Game.mapSizeZ

	local valid = (x > box[1]) and (z > box[2]) and (x < box[3]) and (z < box[4])
	if valid then
		Spring.SetTeamRulesParam(teamID, "valid_startpos", 1)
	end
	return valid
end