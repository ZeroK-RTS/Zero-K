local legacyToDyncommChassisMap = {
	armcom = "strike",
	corcom = "assault",
	commrecon = "recon",
	commsupport = "support",
	commstrike = "strike",
	benzcom = "assault",
	cremcom = "support",
	support = "support",
	recon = "recon",
	assault = "assault",
	strike = "strike",
	guardian = "assault",
	engineer = "support",
	knight = "knight",
}

local function TranslateModoption(legacy)
	if not legacy then
		return
	end
	
	local sorted = {}
	
	-- Find all the things which are equivalent to profileIDs
	for name, data in pairs(legacy) do
		local endName = string.sub(name, -1)
		if endName == "0" then
			local startName = string.sub(name, 1, -2)
			
			local images, decorations
			for decName, decData in pairs(data.decorations) do
				if type(decName) == "number" then
					decorations = decorations or {}
					decorations[#decorations +1] = decData
				elseif decName == "icon_overhead" then
					images = {overhead = decData.image}
					decorations = decorations or {}
					decorations[#decorations +1] = "banner_overhead"
				end
			end
			
			local sortedData = {
				legacyLevels = {
					legacy[startName .. "1"],
					legacy[startName .. "2"],
					legacy[startName .. "3"],
					legacy[startName .. "4"],
					legacy[startName .. "5"],
				},
				name = string.sub(data.name, 0, (string.find(data.name, " level 0") or 100) - 1),
				chassis = legacyToDyncommChassisMap[string.sub(data.chassis, 1, -2)],
				images = images,
				decorations = decorations,
			}
			
			sorted[startName] = sortedData
		end
	end
	
	-- Create the module lists
	for name, data in pairs(sorted) do
		local previousModuleMap = {}
		local modules = {}
	
		for level = 1, 5 do
			local newLevelData = {}
			local levelModules = data.legacyLevels[level].modules
			local nextModuleMap = {}
			
			for m = 1, #levelModules do
				local mName = levelModules[m]
				
				nextModuleMap[mName] = (nextModuleMap[mName] or 0) + 1
				
				if previousModuleMap[mName] then
					previousModuleMap[mName] = previousModuleMap[mName] - 1
					if previousModuleMap[mName] < 1 then
						previousModuleMap[mName] = nil
					end
				else
					newLevelData[#newLevelData + 1] = mName
				end
			end
			
			previousModuleMap = nextModuleMap
			
			modules[level] = newLevelData
		end
		
		data.modules = modules
		data.legacyLevels = nil
	end
	
	return sorted
end

local function FixOverheadIcon(legacy)
	if not legacy then
		return
	end
	
	for name, data in pairs(legacy) do
		if data.decorations and data.decorations.icon_overhead then
			data.images = data.images or {}
			data.images.overhead = data.decorations.icon_overhead.image
			data.decorations.icon_overhead = nil
			data.decorations[#data.decorations + 1] = "banner_overhead"
		end
	end
	return legacy
end

local function TranslatePlayerCustomkeys(legacy)
	if not legacy then
		return
	end

	local retData = {}
	for name, data in pairs(legacy) do
		retData[#retData + 1] = string.sub(data[1], 1, -2)
	end
	
	return retData
end

return {
	TranslateModoption = TranslateModoption,
	FixOverheadIcon = FixOverheadIcon,
	TranslatePlayerCustomkeys = TranslatePlayerCustomkeys,
	legacyToDyncommChassisMap = legacyToDyncommChassisMap
}
