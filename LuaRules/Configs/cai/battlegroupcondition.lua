
function battleGroupCondition1(idleFactor, idleCost) -- raider
	return idleFactor > 0.6 or idleCost > 1000
end

function battleGroupCondition2(idleFactor, idleCost) -- combat
	return idleCost > 400 and (idleFactor > 0.9 or (idleCost > 2000 and idleFactor > 0.4) or idleCost > 4000)
end

function battleGroupCondition3(idleFactor, idleCost) -- gunship
	return idleCost > 1000
end
