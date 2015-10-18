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

if VFS.FileExists("mission.lua") then return end

local startboxConfig
local manualStartposConfig
local mapsideBoxes = "mapconfig/map_startboxes.lua"

if VFS.FileExists (mapsideBoxes) then
	startboxConfig, manualStartposConfig = VFS.Include (mapsideBoxes)
else
	startboxConfig = { }
	local startboxString = Spring.GetModOptions().startboxes
	if startboxString then
		local springieBoxes = loadstring(startboxString)()
		for id, box in pairs(springieBoxes) do
			box[1] = box[1]*Game.mapSizeX
			box[2] = box[2]*Game.mapSizeZ
			box[3] = box[3]*Game.mapSizeX
			box[4] = box[4]*Game.mapSizeZ
			startboxConfig[id] = {
				{box[1], box[2], box[1], box[4], box[3], box[4]}, -- must be counterclockwise
				{box[1], box[2], box[3], box[4], box[3], box[2]}
			}
		end
	end
end

GG.startboxConfig = startboxConfig
GG.manualStartposConfig = manualStartposConfig

function gadget:Initialize()

	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))

	-- filter out fake teams (empty or Gaia)
	local allyTeamList = Spring.GetAllyTeamList()
	local actualAllyTeamList = {}
	for i = 1, #allyTeamList do
		local teamList = Spring.GetTeamList(allyTeamList[i]) or {}
		if ((#teamList > 0) and (allyTeamList[i] ~= gaiaAllyTeamID)) then
			actualAllyTeamList[#actualAllyTeamList+1] = {allyTeamList[i], math.random()}
		end
	end

	local shuffleMode = Spring.GetModOptions().shuffle or "off"

	if (shuffleMode == "off") then

		for i = 1, #allyTeamList do
			local allyTeamID = allyTeamList[i]
			local boxID = allyTeamList[i]
			if startboxConfig[boxID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", boxID)
				end
			end
		end

	elseif (shuffleMode == "shuffle") then

		local randomizedSequence = {}
		for i = 1, #actualAllyTeamList do
			randomizedSequence[#randomizedSequence + 1] = {actualAllyTeamList[i][1], math.random()}
		end
		table.sort(randomizedSequence, function(a, b) return (a[2] < b[2]) end)

		for i = 1, #actualAllyTeamList do
			local allyTeamID = actualAllyTeamList[i][1]
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
		table.sort(actualAllyTeamList, function(a, b) return (a[2] < b[2]) end)

		for i = 1, #actualAllyTeamList do
			local allyTeamID = actualAllyTeamList[i][1]
			local boxID = randomizedSequence[i] and randomizedSequence[i][1]
			if boxID and startboxConfig[boxID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", boxID)
				end
			end
		end
	end
end

local function cross_product (px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

local function CheckStartbox (boxID, x, z)

	local box = startboxConfig[boxID]
	local valid = false

	for i = 1, #box do
		local x1, z1, x2, z2, x3, z3 = unpack(box[i])
		if (cross_product(x, z, x1, z1, x2, z2) < 0
		and cross_product(x, z, x2, z2, x3, z3) < 0
		and cross_product(x, z, x3, z3, x1, z1) < 0
		) then
			valid = true
		end
	end

	return valid
end

GG.CheckStartbox = CheckStartbox

function gadget:AllowStartPosition(x, y, z, playerID, readyState)
	if (playerID == 255) then
		return true -- custom AI, can't know which team it is on so allow it to place anywhere for now and filter invalid positions later
	end

	local teamID = select(4, Spring.GetPlayerInfo(playerID))
	local boxID = Spring.GetTeamRulesParam(teamID, "start_box_id")

	if (not boxID) or CheckStartbox(boxID, x, z) then
		Spring.SetTeamRulesParam (teamID, "valid_startpos", 1)
		return true
	else
		return false
	end
end
