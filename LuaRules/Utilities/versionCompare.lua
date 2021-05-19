Spring.Utilities = Spring.Utilities or {}

-- for some reason IsEngineMinVersion breaks on develop (X.1.Y-...) tags
if (not Script.IsEngineMinVersion(1, 0, 0)) then
	Spring.Echo("[versionCompare.lua] WARNING: IsEngineMinVersion is not working. This means version constants aren't being set correctly. Note that Zero-K was not designed for .1 releases.")
	Script.IsEngineMinVersion = function (major, minor, commit)
		return true -- hacky but if we are on a develop tag we can't really rely on the versioning system
	end
end


function Spring.Utilities.GetEngineVersion()
	return (Game and Game.version) or (Engine and Engine.version) or "Engine version error"
end

function Spring.Utilities.IsCurrentVersionNewerThan(rel, dev)
	-- Argument example, <rel>.0.1-<dev>-g5072695
	local thisVersion = Spring.Utilities.GetEngineVersion()
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
