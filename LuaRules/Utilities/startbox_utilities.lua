function cross_product (px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

function SanitizeBoxes (boxes)
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