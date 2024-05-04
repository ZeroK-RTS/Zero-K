local sets = {
	SMALL_AOE = {
		'unknown/scars_newer/scar1.png',
		'unknown/scars_newer/scar2.png',
		'unknown/scars_newer/scar3.png',
		'unknown/scars_newer/scar4.png',
	},
	MEDIUM_AOE = {
		'unknown/scars_newer/scar1.png',
		'unknown/scars_newer/scar2.png',
		'unknown/scars_newer/scar3.png',
		'unknown/scars_newer/scar4.png',
	},
	LARGE_AOE = {
		'unknown/scars_newer/scar5_big.png',
	},
	SUMO = {
		'unknown/scars_newer/stomp.png',
	},
}

-- Decals are broken in various ways before 105-2400ish, so use
-- old scars. They are all same-ish so no preset differentiation.
-- Sets only do anything in engine releases past 105-2314, otherwise
-- every weapon uses every referenced scar.
if not Script.IsEngineMinVersion(105, 0, 2400) then
	local fallbackSet = {
		'unknown/enlarge/scar1.png',
		'unknown/enlarge/scar2.png',
		'unknown/enlarge/scar3.png',
		'unknown/enlarge/scar4.png',
	}
    for i in pairs(sets) do
        sets[i] = fallbackSet
    end
end

if VFS.FileExists("gamedata/scars_mod.lua", VFS.MOD) then
	local modSets = VFS.Include("gamedata/scars_mod.lua", nil, VFS.MOD)
	for setName, textureNames in pairs(modSets) do
		sets[setName] = textureNames
	end
end

-- Processing
local id = 1
local scarIDs, scarNames = {}, {}
local function GetTextureID(texName)
	local texID = scarIDs[texName]
	if not texID then
		texID = id
		scarIDs[texName] = id
		scarNames[id] = texName
		id = id + 1
	end
	return texID
end

local setsByID = {}
for setName, textureNames in pairs(sets) do
	local setByID = {}
	for i = 1, #textureNames do
		local texName = textureNames[i]
		local texID = GetTextureID(texName)
		setByID[i] = texID
	end
	setsByID[setName] = setByID
end

return setsByID, scarNames
