--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
Example:
local tr
function widget:Initialize()
	tr=WG.initializeTranslation(GetInfo().name,WG.lang)
end

...
...

function foo()
	Spring.Echo(tr("Hello, world"))
end
]]--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "i18n",
		desc      = "Internationalization library for Spring",
		author    = "gajop banana_Ai",
		date      = "WIP",
		license   = "GPLv2",
		version   = "0.1",
		layer     = -math.huge,
		enabled   = true,  --  loaded by default?
		handler   = true,
		api       = true,
		hidden    = true,
	}
end

VFS.Include("LuaUI/Utilities/json.lua");

local function loadLocale(i18n,widget_name,locale)
	local path="Luaui/Configs/lang/"..widget_name.."."..locale..".json"
	if VFS.FileExists(path, VFS.ZIP) then
		local lang=Spring.Utilities.json.decode(VFS.LoadFile(path, VFS.ZIP))
		local t={}
		t[locale]=lang
		i18n.load(t)
		i18n.setLocale(locale)
		return true
	end
	Spring.Echo("Cannot load locale \""..locale.."\" for "..widget_name)
	return false
end

local function initializeTranslation(widget_name,locale)
	local i18n = VFS.Include("LuaUI/i18nlib/i18n/init.lua", nil, VFS.DEF_MODE)
	
	if not loadLocale(i18n,widget_name,locale) then
		loadLocale(i18n,widget_name,"en") 
	end
	
	return i18n
end

WG.initializeTranslation=initializeTranslation
