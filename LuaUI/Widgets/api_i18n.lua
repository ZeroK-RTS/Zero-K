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
		alwaysStart = true,
	}
end

VFS.Include("LuaUI/Utilities/json.lua");

local langValue="en"
local langListeners={}

local translationExtras = { -- lists databases to be merged into the main one
	units = {"campaign_units", "pw_units"},
	interface = {"common", "healthbars", "resbars"},
}

local translations = {
	units = true,
	interface = true,
	missions = true,
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

local function fireLangChange()

	for db, trans in pairs(translations) do
		if not trans.locales[langValue] then
			local extras = translationExtras[db]
			if extras then
				for i = 1, #extras do
					loadLocale(trans.i18n, extras[i], langValue)
				end
			end
			loadLocale(trans.i18n, db, langValue)
			trans.locales[langValue] = true
		end
		trans.i18n.setLocale(langValue)
	end

	for w,f in pairs(langListeners) do
		local okay,err=pcall(f)
		if not okay then
			Spring.Echo("i18n API update failed: " .. w .. "\nCause: " .. err)
			langListeners[w]=nil
		end
	end
end

local function lang (newLang)
	if not newLang then
		return langValue
	elseif langValue ~= newLang then
		langValue = newLang
		fireLangChange()
	end
end

local function initializeTranslation(database)
	local trans = {
		i18n = VFS.Include("LuaUI/i18nlib/i18n/init.lua", nil, VFS.DEF_MODE),
		locales = {en = true},
	}
	loadLocale(trans.i18n,database,"en")

	local extras = translationExtras[database]
	if extras then
		for i = 1, #extras do
			loadLocale(trans.i18n, extras[i], "en")
		end
	end

	return trans
end

local function shutdownTranslation(widget_name)
	langListeners[widget_name]=nil
end

local function Translate (db, text, data)
	return translations[db].i18n(text, data)
end

WG.lang = lang
WG.InitializeTranslation = addListener
WG.ShutdownTranslation = shutdownTranslation
WG.Translate = Translate

for db in pairs(translations) do
	translations[db] = initializeTranslation (db)
end
