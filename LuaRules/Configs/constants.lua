-- Version compare function appears here so widgets can use the constants without gadget utilities.
local function IsCurrentVersionNewerThan(rel, dev)
	-- Argument example, <rel>.0.1-<dev>-g5072695
	local thisVersion = Game.version
	local thisRel, thisDev
	local i = 1
	for word in thisVersion:gmatch("[^%-]+") do
		if i == 1 then
			local j = 1
			for subword in word:gmatch("[^%.]+") do
				if j == 1 then
					thisRel = tonumber(subword)
					if thisRel then
						if thisRel < rel then
							return false
						end
						if thisRel > rel then
							return true
						end
					end
				end
				j = j + 1
			end
		elseif i == 2 then
			thisDev = tonumber(word)
			if thisDev then
				return thisDev > dev
			end
		end
		i = i + 1
	end
	return false -- A newer version would not fail to return before now
end

HIDDEN_STORAGE = 10000 -- hidden storage: it will spend all energy above (storage - hidden_storage)
TEAM_SLOWUPDATE_RATE = (IsCurrentVersionNewerThan(98, 379) and 30) or 32