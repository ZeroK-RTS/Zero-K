
local hardcodedOthers = {
	staticmissilesilo = true,
	cloakjammer = true,
	amphtele = true,
	gunshiptrans = true,
	gunshipheavytrans = true,
	planescout = true
}

local function GetUnitCategory(unitDefID)
	local ud = UnitDefs[unitDefID]
	local cp = ud.customParams
	local name = ud.name
	
	if cp.dontcount or cp.is_drone then
		return "dontcount"
	end
	
	if name == "staticarty" then
		return "def"
	end
	
	if hardcodedOthers[name] then
		return "other"
	end
	
	if cp.level then -- commander
		return "other"
	end
	
	if cp.ismex or cp.income_energy or (cp.pylonrange and ((tonumber(cp.pylonrange) or 0) > 400)) or ud.energyStorage > 0 then
		return "econ"
	end
	
	if not ud.isImmobile then
		return "army"
	end
	
	if string.find(name, "turret") or string.find(name, "shield") then
		return "def"
	end
	
	return "other"
end

local saneCat = {
	other = true,
	army = true,
	econ = true,
	def = true,
}

local unitCategory = {}
local saneUnitCategory = {}
for i = 1, #UnitDefs do
	local cat = GetUnitCategory(i)
	unitCategory[i] = cat
	if saneCat[cat] then
		saneUnitCategory[i] = cat
	end
end

return saneUnitCategory, unitCategory
