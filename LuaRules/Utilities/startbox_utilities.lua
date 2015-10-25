function cross_product (px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

local function SanitizeBoxes (boxes)

	-- chop polies into triangles
	for id, polies in pairs(boxes) do
		local triangles = {}
		local polycount = #polies
		for i = 1, polycount do
			local polygon = polies[i]
			local A = polygon[1]
			local B = polygon[2]
			for j = 3, #polygon do
				local C = polygon[j]
				triangles[#triangles+1] = {A[1], A[2], B[1], B[2], C[1], C[2]}
				B = C
			end
			polies[i] = nil
		end
		for i = 1, #triangles do
			polies[i] = triangles[i]
		end
	end

	-- make sure the triangles are counter-clockwise
	for id, box in pairs(boxes) do
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
end

function ParseBoxes ()
	local mapsideBoxes = "mapconfig/map_startboxes.lua"
	local modsideBoxes = "LuaRules/Configs/StartBoxes/" .. (Game.mapName or "") .. ".lua"

	local startBoxConfig
	local manualStartposConfig

	if VFS.FileExists (modsideBoxes) then
		startBoxConfig, manualStartposConfig = VFS.Include (modsideBoxes)
		SanitizeBoxes (startBoxConfig)
	elseif VFS.FileExists (mapsideBoxes) then
		startBoxConfig, manualStartposConfig = VFS.Include (mapsideBoxes)
		SanitizeBoxes (startBoxConfig)
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

	return startBoxConfig, manualStartposConfig
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