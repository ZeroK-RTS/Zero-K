function widget:GetInfo() return {
	name    = "Startbox API",
	desc    = "Processes and exposes startboxes",
	author  = "Sprung",
	layer   = -9001,
	enabled = true,
	api     = true,
	hidden  = true,
} end

if VFS.FileExists("mission.lua") then return end

local startBoxConfig
local mapsideBoxes = "mapconfig/map_startboxes.lua"

local function cross_product (px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

function GetTeamCount()
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
	local allyTeamList = Spring.GetAllyTeamList()
	local actualAllyTeamList = {}
	for i = 1, #allyTeamList do
		local teamList = Spring.GetTeamList(allyTeamList[i]) or {}
		if ((#teamList > 0) and (allyTeamList[i] ~= gaiaAllyTeamID)) then
			actualAllyTeamList[#actualAllyTeamList+1] = allyTeamList[i]
		end
	end
	return #actualAllyTeamList
end

if VFS.FileExists (mapsideBoxes) then
	startBoxConfig = VFS.Include (mapsideBoxes)
	for id, box in pairs(startBoxConfig) do
		for i = 1, #box do
			local conf = box[i]
			if cross_product(conf[5], conf[6], conf[1], conf[2], conf[3], conf[4]) > 0 then
				local temp = conf[5]
				conf[5] = conf[3]
				conf[3] = temp
				temp = conf[6]
				conf[6] = conf[4]
				conf[4] = temp
			end
		end
	end
else
	startBoxConfig = { }
	local startboxString = Spring.GetModOptions().startboxes
	if startboxString then
		local springieBoxes = loadstring(startboxString)()
		for id, box in pairs(springieBoxes) do
			box[1] = box[1]*Game.mapSizeX
			box[2] = box[2]*Game.mapSizeZ
			box[3] = box[3]*Game.mapSizeX
			box[4] = box[4]*Game.mapSizeZ
			startBoxConfig[id] = {
				{box[1], box[2], box[1], box[4], box[3], box[4]}, -- must be counterclockwise
				{box[1], box[2], box[3], box[4], box[3], box[2]}
			}
		end
	end
end

WG.startBoxConfig = startBoxConfig