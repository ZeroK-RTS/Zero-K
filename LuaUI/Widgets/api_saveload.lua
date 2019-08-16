--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--	HOW TO USE
--	- see http://springrts.com/wiki/Lua_SaveLoad
--	- tl;dr:	/save -y <filename> to save to Spring/Saves
--					remove the -y to not overwrite
--				/savegame to save to Spring/Saves/QuickSave.ssf
--				open an .ssf with spring.exe to load
--				/reloadgame reloads the save you loaded
--					(widget purges existing units and feautres)
--	NOTES
--	- heightmap saving is implemented by engine
--	- widgets which wish to save/load their data must either submit a table and
--		filename to save, or else handle it themselves
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Save/Load API",
    desc      = "General save/load stuff",
    author    = "KingRaptor (L.J. Lim)",
    date      = "25 September 2011",
    license   = "GNU LGPL, v2 or later",
    layer     = -math.huge + 1,	-- we want this to go first
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")
WG.SaveLoad = WG.SaveLoad or {}

local generalFile = "general.lua"
local unitFile = "units.lua"
local featureFile = "features.lua"

-- vars
local savedata = {
	general = {},
	heightMap = {},
	unit = {},
	feature = {},
	projectile = {},
	widgets = {}
}
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
local function ReadFile(zip, name, file)
	name = name or ''
	if (not file) then return end
	local dataRaw, dataFunc, data, err
	
	zip:open(file)
	dataRaw = zip:read("*all")
	if not (dataRaw and type(dataRaw) == 'string') then
		err = name.." save data is empty or in invalid format"
	else
		dataFunc, err = loadstring(dataRaw)
		if dataFunc then
			success, data = pcall(dataFunc)
			if not success then -- execute Borat
				err = data
			end
		end
	end
	if err then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, 'Save/Load error: ' .. err)
		return nil
	end
	return data
end
WG.SaveLoad.ReadFile = ReadFile

local function FacingFromHeading (h)
	if h > 0 then
		if h < 8192 then
			return 's'
		elseif h < 24576 then
			return 'e'
		else
			return 'n'
		end
	else
		if h >= -8192 then
			return 's'
		elseif h >= -24576 then
			return 'w'
		else
			return 'n'
		end
	end
end

local function boolToNum(bool)
	if bool then return 1
	else return 0 end
end

-- The unitID/featureID parameter in creation does not make these remapping functions obselete.
-- That parameter is unreliable.
local function GetNewUnitID(oldUnitID)
	local newUnitID = savedata.unit[oldUnitID] and savedata.unit[oldUnitID].newID
	if not newUnitID then
		Spring.Log(widget:GetInfo().name, LOG.WARNING, "Cannot get new unit ID", oldUnitID)
	end
	return newUnitID
end
WG.SaveLoad.GetNewUnitID = GetNewUnitID

local function GetNewUnitIDKeys(data)
	local ret = {}
	for i, v in pairs(data) do
		local id = GetNewUnitID(i)
		if id then
			ret[id] = v
		end
	end
	return ret
end
WG.SaveLoad.GetNewUnitIDKeys = GetNewUnitIDKeys

local function GetNewUnitIDValues(data)
	local ret = {}
	for i, v in pairs(data) do
		local id = GetNewUnitID(v)
		if id then
			ret[i] = id
		end
	end
	return ret
end
WG.SaveLoad.GetNewUnitIDValues = GetNewUnitIDValues

-- FIXME: not implemented yet
--[[
local function GetNewFeatureID(oldFeatureID)
	return savedata.feature[oldFeatureID] and savedata.feature[oldFeatureID].newID
end
WG.SaveLoad.GetNewFeatureID = GetNewFeatureID

local function GetNewFeatureIDKeys(data)
	local ret = {}
	for i, v in pairs(data) do
		local id = GetNewFeatureID(i)
		if id then
			ret[id] = v
		end
	end
	return ret
end
WG.SaveLoad.GetNewFeatureIDKeys = GetNewFeatureIDKeys

local function GetNewProjectileID(oldProjectileID)
	return savedata.projectile[oldProjectileID] and savedata.projectile[oldProjectileID].newID
end
WG.SaveLoad.GetNewProjectileID = GetNewProjectileID

local function GetSavedGameFrame()
	return savedata.general.gameFrame
end
WG.SaveLoad.GetSavedGameFrame = GetSavedGameFrame

local function GetSavedUnitsCopy()
	return Spring.Utilities.CopyTable(savedata.unit, true)
end
WG.SaveLoad.GetSavedUnitsCopy = GetSavedUnitsCopy
]]
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

local function LoadUnits()
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local newID = units[i]
		local oldID = Spring.GetUnitRulesParam(newID, "saveload_oldID")
		if oldID and savedata.unit[oldID] then
			savedata.unit[oldID].newID = newID
		end
	end
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- callins
function widget:Load(zip)
	savedata = {
		general = {},
		heightMap = {},
		unit = {},
		feature = {},
		projectile = {},
		widgets = {}
	}
	
	savedata.general = ReadFile(zip, "General", generalFile)

	if not savedata.general then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save file corrupted (no 'general' section)")
		return
	end
	
	savedata.unit = ReadFile(zip, "Unit", unitFile) or {}
	savedata.feature = ReadFile(zip, "Feature", featureFile) or {}
	--savedata.projectile = ReadFile(zip, "Projectile", projectileFile) or {}

	--LoadGeneralInfo()
	--LoadHeightMap()
	--LoadFeatures()	-- do features before units so we can change unit orders involving features to point to new ID
	LoadUnits()
	--LoadProjectiles() -- do projectiles after units so they can home onto units.
end

--------------------------------------------------------------------------------
-- I/O utility functions
--------------------------------------------------------------------------------
local function WriteSaveData(zip, filename, data)
	zip:open(filename)
	local concat = WG.WriteTable({}, data, nil, {prefixReturn = true})
	local str = table.concat(concat, "")
	zip:write(str)
end
WG.SaveLoad.WriteSaveData = WriteSaveData

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- callins
function widget:Save(zip)
	
end

function widget:Initialize()

end

function widget:Shutdown()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
