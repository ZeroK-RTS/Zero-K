VFS.Include("LuaRules/engine_compat.lua", nil, VFS.GAME)

local VFS = VFS
local orig_VFS_Include = VFS.Include
local VFS_GAME = VFS.GAME
local VFS_MAP = VFS.MAP
local VFS_DirList = orig_VFS_Include('gamedata/recursive_dir_list.lua', nil, VFS_GAME)

local errors_during_loading = {}
local function VFS_Include(filename, env, mode, recursive)
	local ok, result = pcall(orig_VFS_Include, filename, env, mode, recursive)
	if ok then
		return result
	else
		errors_during_loading[#errors_during_loading + 1] = result
		return {}
	end
end

--[[ unitdefs_post is massively simplified by being able to assume
     that all def keys are lowercase. However, being able to use
     uppercase in the defs is also good for readability (also we
     have to support modders with lax standards anyway). This is
     why lowerkeys are applied to all defs; this has nothing to do
     with the engine (all cases are accepted by Spring). ]]
local lowerKeys = VFS_Include('gamedata/system.lua').lowerkeys

VFS_Include("LuaRules/Utilities/tablefunctions.lua")
local suCopyTable = Spring.Utilities.CopyTable

local unitDefs = {}
UnitDefs = unitDefs

local shared = VFS_Include('gamedata/unitdefs_pre.lua', nil, VFS_GAME)
Shared = shared

local zkUnits = VFS_DirList('units', '*.lua', VFS_GAME, true)
for i = 1, #zkUnits do
	suCopyTable(lowerKeys(VFS_Include(zkUnits[i], nil, VFS_GAME)), false, unitDefs)
end
-- TODO: put dynamic unit generation (comms, planet wars stuff) here

--[[ The checks in this file don't apply to map-defined units,
     only ZK-side, so can afford to be brutal (crash on failure).
     This ensures that mistakes and cargo cults don't go unnoticed. ]]
VFS_Include('gamedata/unitdefs_checks.lua', nil, VFS_GAME)

lowerkeys = lowerKeys -- legacy mapside defs might want it
local mapUnits = VFS_DirList('units', '*.lua', VFS_MAP, true)
for i = 1, #mapUnits do
	suCopyTable(lowerKeys(VFS_Include(mapUnits[i], nil, VFS_MAP)), false, unitDefs)
end

--[[ This would ideally be 'gamedata/unitdefs_post.lua' because that is
     the convention used in the past, back when map files overrode games'
     by default. Also it would be elegant if mappers could just copy our
     gameside file and get something working. However, there are issues
     preventing this from happening:

     1) VFS.FileExists is (as of 104-1435) broken and seems to behave as
        if the namespace argument was (VFS.BASE .. VFS.GAME .. VFS.MAP)
	 regardless of what it actually is. This would make us include the
	 file every time since it's present gameside. It could be worked
	 around by using pcall and ignoring an inclusion failure, but...

     2) VFS.Include is broken in the same way on old engines (specifically
        on 104-287 which we want to keep supporting for the time being).
     This means that the gameside posts would instead be included twice. ]]

local MAPSIDE_POSTS_FILEPATH = 'gamedata/unitdefs_map.lua'
if VFS.FileExists(MAPSIDE_POSTS_FILEPATH, VFS_MAP) then
	VFS_Include(MAPSIDE_POSTS_FILEPATH, nil, VFS_MAP)
end

--[[ This lets mutators add a bit of unitdefs_posts processing without
     losing access to future gameside updates to unitdefs_posts.]]
local MODSIDE_POSTS_FILEPATH = 'gamedata/unitdefs_mod.lua'
if VFS.FileExists(MODSIDE_POSTS_FILEPATH, VFS_GAME) then
	VFS_Include(MODSIDE_POSTS_FILEPATH, nil, VFS_GAME)
end

VFS_Include('gamedata/unitdefs_post.lua', nil, VFS_GAME)

local errors = #errors_during_loading
if errors > 0 then
	for i = 1, errors do
		Spring.Log("UNIT DEFS LOADING ERROR", LOG.ERROR, errors_during_loading[i])
	end

	--[[ Modders often run the game via Chobby. In that case, if parsing
	     ends with an error, whole Spring crashes and they waste a lot of
	     time setting up a room again. The solution is to continue the
	     loading, but leave a "message" that something happened. Pick any
	     unit that happened to load, since nothing is 100% to exist now. ]]
	local _, validUnit = next(unitDefs)
	unitDefs["unitdefs_failed_to_load"] = validUnit
end

return unitDefs
