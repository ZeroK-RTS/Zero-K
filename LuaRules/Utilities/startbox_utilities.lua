function cross_product (px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

local function SanitizeBoxes (boxes)

	-- chop polies into triangles
	for id, box in pairs(boxes) do
		local polies = box.boxes
		local triangles = {}
		for z = 1, #polies do
			local polygon = polies[z]

			-- find out clockwisdom
			polygon[#polygon+1] = polygon[1]
			local clockwise = 0
			for i = 2, #polygon do
				clockwise = clockwise + (polygon[i-1][1] * polygon[i][2]) - (polygon[i-1][2] * polygon[i][1])
			end
			polygon[#polygon] = nil
			local clockwise = (clockwise < 0)

			-- the van gogh concave polygon triangulation algorithm: cuts off ears
			-- is pretty shitty at O(V^3) but was easy to code and it's only done once anyway
			while (#polygon > 2) do

				-- get a candidate ear
				local triangle
				local c0, c1, c2 = 0, 0, 0
				local candidate_ok = false
				while not candidate_ok do

					c0 = c0 + 1
					c1, c2 = c0+1, c0+2
					if c1 > #polygon then c1 = c1 - #polygon end
					if c2 > #polygon then c2 = c2 - #polygon end
					triangle = {
						polygon[c0][1], polygon[c0][2],
						polygon[c1][1], polygon[c1][2],
						polygon[c2][1], polygon[c2][2],
					}

					-- make sure the ear is of proper rotation but then make it counter-clockwise
					local dir = cross_product(triangle[5], triangle[6], triangle[1], triangle[2], triangle[3], triangle[4])
					if ((dir < 0) == clockwise) then
						if dir > 0 then
							local temp = triangle[5]
							triangle[5] = triangle[3]
							triangle[3] = temp
							temp = triangle[6]
							triangle[6] = triangle[4]
							triangle[4] = temp
						end

						-- check if no point lies inside the triangle
						candidate_ok = true
						for i = 1, #polygon do
							if (i ~= c0 and i ~= c1 and i ~= c2) then
								local current_pt = polygon[i]
								if  (cross_product(current_pt[1], current_pt[2], triangle[1], triangle[2], triangle[3], triangle[4]) < 0)
								and (cross_product(current_pt[1], current_pt[2], triangle[3], triangle[4], triangle[5], triangle[6]) < 0)
								and (cross_product(current_pt[1], current_pt[2], triangle[5], triangle[6], triangle[1], triangle[2]) < 0)
								then
									candidate_ok = false
								end
							end
						end
					end
				end

				-- cut off ear
				triangles[#triangles+1] = triangle
				table.remove(polygon, c1)
			end

			polies[z] = nil
		end

		for z = 1, #triangles do
			polies[z] = triangles[z]
		end
	end
end

function ParseBoxes ()
	local mapsideBoxes = "mapconfig/map_startboxes.lua"
	local modsideBoxes = "LuaRules/Configs/StartBoxes/" .. (Game.mapName or "") .. ".lua"

	local startBoxConfig

	math.randomseed(Spring.GetGameRulesParam("public_random_seed"))

	if VFS.FileExists (modsideBoxes) then
		startBoxConfig = VFS.Include (modsideBoxes)
		SanitizeBoxes (startBoxConfig)
	elseif VFS.FileExists (mapsideBoxes) then
		startBoxConfig = VFS.Include (mapsideBoxes)
		SanitizeBoxes (startBoxConfig)
	else
		startBoxConfig = { }
		local startboxString = Spring.GetModOptions().startboxes
		if startboxString then
			local springieBoxes = loadstring(startboxString)()
			for id, box in pairs(springieBoxes) do
				local midX = (box[1]+box[3]) / 2
				local midZ = (box[2]+box[4]) / 2

				box[1] = box[1]*Game.mapSizeX
				box[2] = box[2]*Game.mapSizeZ
				box[3] = box[3]*Game.mapSizeX
				box[4] = box[4]*Game.mapSizeZ

				local longName = "Center"
				local shortName = "Center"

				if (midX < 0.33) then
					if (midZ < 0.33) then
						longName = "North-West"
						shortName = "NW"
					elseif (midZ > 0.66) then
						longName = "South-West"
						shortName = "SW"
					else
						longName = "West"
						shortName = "W"
					end
				elseif (midX > 0.66) then
					if (midZ < 0.33) then
						longName = "North-East"
						shortName = "NE"
					elseif (midZ > 0.66) then
						longName = "South-East"
						shortName = "SE"
					else
						longName = "East"
						shortName = "E"
					end
				else
					if (midZ < 0.33) then
						longName = "North"
						shortName = "N"
					elseif (midZ > 0.66) then
						longName = "South"
						shortName = "S"
					else
						longName = "Center"
						shortName = "Center"
					end
				end

				startBoxConfig[id] = {
					boxes = {
						{box[1], box[2], box[1], box[4], box[3], box[4]}, -- must be counterclockwise
						{box[1], box[2], box[3], box[4], box[3], box[2]}
					},
					startpoints = {
						{(box[1]+box[3]) / 2, (box[2]+box[4]) / 2}
					},
					nameLong = longName,
					nameShort = shortName
				}
			end
		end
	end

	return startBoxConfig
end

function GetRawBoxes ()
	local mapsideBoxes = "mapconfig/map_startboxes.lua"
	local modsideBoxes = "LuaRules/Configs/StartBoxes/" .. (Game.mapName or "") .. ".lua"

	local startBoxConfig
	math.randomseed(Spring.GetGameRulesParam("public_random_seed"))

	if VFS.FileExists (modsideBoxes) then
		startBoxConfig = VFS.Include (modsideBoxes)
	elseif VFS.FileExists (mapsideBoxes) then
		startBoxConfig = VFS.Include (mapsideBoxes)
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
					boxes = {
						{
							{box[1], box[2]},
							{box[1], box[4]},
							{box[3], box[4]},
							{box[3], box[2]},
						},
					}
				}
			end
		end
	end

	return startBoxConfig
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
