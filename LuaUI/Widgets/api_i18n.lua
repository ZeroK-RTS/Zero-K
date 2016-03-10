--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
Example:
local tr
local hellWorld
function widget:Initialize()
	tr=WG.initializeTranslation(GetInfo().name,langCallback)
	hellWorld=tr("helloworld")
end

...
...

function foo()
	Spring.Echo(hellWorld)
end

...
...
function langCallback()
	hellWorld=tr("helloworld")
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

local langValue="en"
local langListeners={}

local translations = {
	common = true,
	healthbars = true,
	units = true,
}

local function addListener(l, widgetName)
	if l and type(l)=="function" then
		local okay, err = pcall(l)
		if okay then
			langListeners[widgetName]=l
		else
			Spring.Echo("i18n API subscribe failed: " .. widgetName .. "\nCause: " .. err)
		end
	end
end

local function fireLangChange()
	for w,f in pairs(langListeners) do
		local okay,err=pcall(f)
		if not okay then
			Spring.Echo("i18n API update failed: " .. w .. "\nCause: " .. err)
			langListeners[w]=nil
		end
	end
end

local function lang(l)
	if not l then
		return langValue
	else
		if langValue~=l then
			langValue=l
			fireLangChange()
		end
	end
end


local function loadLocale(i18n,database,locale)
	local path="Luaui/Configs/lang/"..database.."."..locale..".json"
	if VFS.FileExists(path, VFS.ZIP) then
		local lang=Spring.Utilities.json.decode(VFS.LoadFile(path, VFS.ZIP))
		local t={}
		t[locale]=lang
		i18n.load(t)
		return true
	end
	Spring.Echo("Cannot load locale \""..locale.."\" for "..database)
	return false
end

local function initializeTranslation(database, listener, widget_name)
	local i18n = VFS.Include("LuaUI/i18nlib/i18n/init.lua", nil, VFS.DEF_MODE)
	loadLocale(i18n,database,"en") 
	
	local localsList={en=true}
	return 	function(key,data)
				local lang=WG.lang()
				if not localsList[lang] then
					loadLocale(i18n,database,lang)
					localsList[lang]=true
				end
				return i18n(key,data,lang)
			end
end

local function shutdownTranslation(widget_name)
	langListeners[widget_name]=nil
end

local function Translate (db, text, data)
	return translations[db](text, data)
end

if WG.lang then
	langValue=WG.lang()
end

WG.lang=lang
WG.InitializeTranslation = addListener
WG.ShutdownTranslation = shutdownTranslation
WG.Translate = Translate

for db in pairs(translations) do
	translations[db] = initializeTranslation (db)
end
