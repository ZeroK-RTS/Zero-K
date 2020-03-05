local VFS = VFS
local VFS_Include = VFS.Include
local VFS_GAME = VFS.GAME
local VFS_MAP = VFS.MAP

local system = VFS_Include('gamedata/system.lua')
local lowerKeys = system.lowerkeys

VFS_Include("LuaRules/Utilities/tablefunctions.lua")
local suCopyTable = Spring.Utilities.CopyTable

local unitDefs = {}
UnitDefs = unitDefs

local shared = VFS_Include('gamedata/unitdefs_pre.lua', nil, VFS_GAME)
Shared = shared

local zkUnits = VFS.DirList('units', '*.lua', VFS_GAME)
for i = 1, #zkUnits do
	suCopyTable(lowerKeys(VFS_Include(zkUnits[i], nil, VFS_GAME)), false, unitDefs)
end
-- TODO: put dynamic unit generation (comms, planet wars stuff) here

--[[ The checks in this file don't apply to map-defined units,
     only ZK-side, so can afford to be brutal (crash on failure).
     This ensures that mistakes and cargo cults don't go unnoticed. ]]
Game = Game or { gameSpeed = 30 } -- compat for 287, would ideally be in defs.lua but 287 has some VFS fuckup which disallows that
VFS_Include('gamedata/unitdefs_checks.lua', nil, VFS_GAME)

lowerkeys = lowerKeys -- legacy mapside defs might want it
local mapUnits = VFS.DirList('units', '*.lua', VFS_MAP)
for i = 1, #mapUnits do
	suCopyTable(lowerKeys(VFS_Include(mapUnits[i], nil, VFS_MAP)), false, unitDefs)
end

if VFS.FileExists('gamedata/unitdefs_post.lua', VFS_MAP) then
	--VFS_Include('gamedata/unitdefs_post.lua', nil, VFS_MAP)
end
VFS_Include('gamedata/unitdefs_post.lua', nil, VFS_GAME)

return unitDefs
