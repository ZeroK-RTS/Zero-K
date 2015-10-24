function cross_product (px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

function SanitizeBoxes (boxes)

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