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

local function addListener(widgetName,l)
	if l and type(l)=="function" then
		langListeners[widgetName]=l
	end
end

local function fireLangChange()
	for w,f in pairs(langListeners) do
		local okay,err=pcall(f)
		if not okay then
			Spring.Echo("Remove listener "..w..": "..err)
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


local function loadLocale(i18n,widget_name,locale)
	local path="Luaui/Configs/lang/"..widget_name.."."..locale..".json"
	if VFS.FileExists(path, VFS.ZIP) then
		local lang=Spring.Utilities.json.decode(VFS.LoadFile(path, VFS.ZIP))
		local t={}
		t[locale]=lang
		i18n.load(t)
		return true
	end
	Spring.Echo("Cannot load locale \""..locale.."\" for "..widget_name)
	return false
end

local function initializeTranslation(widget_name,listener)
	addListener(widget_name,listener)
	
	local i18n = VFS.Include("LuaUI/i18nlib/i18n/init.lua", nil, VFS.DEF_MODE)
	loadLocale(i18n,widget_name,"en") 
	
	local localsList={en=true}
	return 	function(key,data)
				local lang=WG.lang()
				if not localsList[lang] then
					loadLocale(i18n,widget_name,lang)
					localsList[lang]=true
				end
				return i18n(key,data,lang)
			end
end

local function shutdownTranslation(widget_name)
	langListeners[widget_name]=nil
end

if WG.lang then
	langValue=WG.lang()
end

WG.lang=lang
WG.initializeTranslation=initializeTranslation
WG.shutdownTranslation=shutdownTranslation
