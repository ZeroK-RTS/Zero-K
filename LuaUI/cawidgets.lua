-- $Id: cawidgets.lua 4261 2009-03-31 16:34:36Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    widgets.lua
--  brief:   the widget manager, a call-in router
--  author:  Dave Rodgers
--
--  modified by jK and quantum
--
--  Copyright (C) 2007,2008,2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local ignorelist = {count = 0, ignorees = {} } -- Ignore workaround for WG table.
local playerstate = {} -- for PlayerChangedTeam, PlayerResigned
local resetWidgetDetailLevel = false -- has widget detail level changed
local myPlayerID = Spring.GetLocalPlayerID()

local ORDER_VERSION = 8 --- change this to reset enabled/disabled widgets
local DATA_VERSION = 9 -- change this to reset widget settings

local PROFILE_INIT = false
local MEMORY_DEBUG = false

local vfs = VFS
local vfsInclude = vfs.Include
local vfsGame = vfs.GAME

WG = {}
Spring.Utilities = {}

Spring.Utilities.json = vfsInclude("LuaRules/Utilities/json.lua"          , nil, vfsGame)

vfsInclude("LuaRules/Utilities/globals.lua"          , nil, vfsGame)
vfsInclude("LuaRules/Utilities/tablefunctions.lua"   , nil, vfsGame)
vfsInclude("LuaRules/Utilities/debugFunctions.lua"   , nil, vfsGame)
vfsInclude("LuaRules/Utilities/versionCompare.lua"   , nil, vfsGame)
vfsInclude("LuaRules/Utilities/unitStates.lua"       , nil, vfsGame)
vfsInclude("LuaRules/Utilities/gametype.lua"         , nil, vfsGame)
vfsInclude("LuaRules/Utilities/vector.lua"           , nil, vfsGame)
vfsInclude("LuaRules/Utilities/unitTypeChecker.lua"  , nil, vfsGame)
vfsInclude("LuaRules/Utilities/function_override.lua", nil, vfsGame)
vfsInclude("LuaRules/Utilities/minimap.lua"          , nil, vfsGame)
vfsInclude("LuaRules/Utilities/lobbyStuff.lua"       , nil, vfsGame)
vfsInclude("LuaUI/Utilities/truncate.lua"            , nil, vfsGame)
vfsInclude("LuaUI/keysym.lua"                        , nil, vfsGame)
vfsInclude("LuaUI/system.lua"                        , nil, vfsGame)
vfsInclude("LuaUI/cache.lua"                         , nil, vfsGame)
vfsInclude("LuaUI/callins.lua"                       , nil, vfsGame)
vfsInclude("LuaUI/savetable.lua"                     , nil, vfsGame)

local CheckLUAFileAndBackup = vfsInclude("LuaUI/file_backups.lua", nil, vfsGame)
local MessageProcessor = vfsInclude("LuaUI/chat_preprocess.lua", nil, vfsGame)

local ORDER_FILENAME     = LUAUI_DIRNAME .. 'Config/ZK_order.lua'
local CONFIG_FILENAME    = LUAUI_DIRNAME .. 'Config/ZK_data.lua'
local WIDGET_DIRNAME     = LUAUI_DIRNAME .. 'Widgets/'

-- make/load backup config in case of corruption
CheckLUAFileAndBackup(ORDER_FILENAME)
CheckLUAFileAndBackup(CONFIG_FILENAME)

local HANDLER_BASENAME = "cawidgets.lua"
local SELECTOR_BASENAME = 'selector.lua'

local lastTime = PROFILE_INIT and Spring.GetTimer()
local function TimeLoad(name)
	if PROFILE_INIT then
		local timeDiff = Spring.DiffTimers(Spring.GetTimer(), lastTime)
		Spring.Echo(name, timeDiff)
		lastTime = Spring.GetTimer()
	end
end

do
	local isMission = Game.modDesc:find("Mission Mutator")
	if isMission then -- all missions will be forced to use a specific name
		if not VFS.FileExists(ORDER_FILENAME) or not VFS.FileExists(CONFIG_FILENAME) then
			ORDER_FILENAME     = LUAUI_DIRNAME .. 'Config/ZK_order.lua' --use "ZK" name when running any mission mod (provided that there's no existing config file)
			CONFIG_FILENAME    = LUAUI_DIRNAME .. 'Config/ZK_data.lua'
		end
	end
end

local SAFEWRAP = 1
-- 0: disabled
-- 1: enabled, but can be overriden by widget.GetInfo().unsafe
-- 2: always enabled

local SAFEDRAW = false  -- requires SAFEWRAP to work
local glPopAttrib  = gl.PopAttrib
local glPushAttrib = gl.PushAttrib
local pairs = pairs
local ipairs = ipairs

-- read local widgets config
local localWidgetsFirst = false
local localWidgets = false
local disableLocalWidgets = (
	Spring.GetModOptions().disable_local_widgets and
	Spring.GetModOptions().disable_local_widgets ~= "0" and
	Spring.GetModOptions().disable_local_widgets ~= 0 and
	not (Spring.GetSpectatingState() or Spring.IsReplay())
)

if VFS.FileExists(CONFIG_FILENAME) then --check config file whether user want to use localWidgetsFirst
	if not disableLocalWidgets then
		local cadata = VFS.Include(CONFIG_FILENAME)
		if cadata and cadata["Local Widgets Config"] then
			localWidgetsFirst = cadata["Local Widgets Config"].useLocalWidgetsFirst or true
			localWidgets = cadata["Local Widgets Config"].useLocalWidgets or true
		end
	end
end

Spring.Echo("localWidgets", disableLocalWidgets, localWidgets, localWidgetsFirst)
local VFSMODE
VFSMODE = localWidgetsFirst and VFS.RAW_FIRST
VFSMODE = VFSMODE or localWidgets and VFS.ZIP_FIRST
VFSMODE = VFSMODE or VFS.ZIP

local detailLevel = Spring.GetConfigInt("widgetDetailLevel", 3)

--------------------------------------------------------------------------------

-- install bindings for TweakMode and the Widget Selector

Spring.SendCommands({
	"unbindkeyset  Any+f11",
	"unbindkeyset Ctrl+f11",
	"bind    f11  luaui selector",
	"bind  C+f11  luaui tweakgui",
	"echo LuaUI: bound F11 to the widget selector",
	"echo LuaUI: bound CTRL+F11 to tweak mode"
})


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  the widgetHandler object
--

widgetHandler = {

	widgets = {},

	configData = {},
	orderList = {},

	knownWidgets = {},
	knownCount = 0,
	knownChanged = true,

	commands = {},
	customCommands = {},
	inCommandsChanged = false,

	autoModWidgets = false,

	actionHandler = include("actions.lua"),

	WG = WG, -- shared table for widgets

	globals = {}, -- global vars/funcs

	mouseOwner = nil,
	ownedButton = 0,

	tweakMode = false,
}

VFS.Include('LuaRules/engine_compat_post.lua', nil, vfsGame)

-- these call-ins are set to 'nil' if not used
-- they are setup in UpdateCallIns()
local flexCallIns = {
	'PlayerChangedTeam',
	'PlayerResigned',
	'GameOver',
	'GamePaused',
	'GameFrame',
	'GameSetup',
	'TeamDied',
	'TeamChanged',
	'PlayerAdded',
	'PlayerChanged',
	"PlayerRemoved",
	'ShockFront',
	'WorldTooltip',
	'MapDrawCmd',
	'DefaultCommand',
	'UnitCreated',
	'UnitFinished',
	'UnitResurrected',
	'UnitReverseBuilt',
	'UnitFromFactory',
	'UnitDestroyed',
	'UnitDestroyedByTeam',
	'RenderUnitDestroyed',
	'UnitExperience',
	'UnitTaken',
	'UnitGiven',
	'UnitIdle',
	'UnitCommand',
	'UnitCmdDone',
	'UnitDamaged',
	'UnitStunned',
	'UnitEnteredRadar',
	'UnitEnteredLos',
	'UnitLeftRadar',
	'UnitLeftLos',
	'UnitEnteredWater',
	'UnitEnteredAir',
	'UnitLeftWater',
	'UnitLeftAir',
	'UnitSeismicPing',
	'UnitLoaded',
	'UnitUnloaded',
	'UnitCloaked',
	'UnitDecloaked',
	'UnitMoveFailed',
	'RecvLuaMsg',
	'StockpileChanged',
	'DrawGenesis',
	'DrawWorld',
	'DrawWorldPreUnit',
	'DrawWorldPreParticles',
	'DrawWorldShadow',
	'DrawWorldReflection',
	'DrawWorldRefraction',
	'DrawUnitsPostDeferred',
	'DrawFeaturesPostDeferred',
	'DrawScreenEffects',
	'DrawScreenPost',
	'DrawInMiniMap',
	'DrawOpaqueUnitsLua',
	'DrawOpaqueFeaturesLua',
	'DrawAlphaUnitsLua',
	'DrawAlphaFeaturesLua',
	'DrawShadowUnitsLua',
	'DrawShadowFeaturesLua',
	'RecvSkirmishAIMessage',
	'SelectionChanged',
	'TeamColorsChanged',
	'AddConsoleMessage',
	'Save',
	'Load',
	'GameID',

	-- From gadgets
	"UnitStructureMoved",
	'MissileFired',
	'MissileDestroyed',
	"PreGameTimekeeping",
}
local flexCallInMap = {}
for _, ci in ipairs(flexCallIns) do
	flexCallInMap[ci] = true
end

local reverseCallIns = {
	'DrawScreen',
	'DrawGenesis',
	'DrawWorld',
	'DrawWorldPreUnit',
	'DrawWorldPreParticles',
	'DrawWorldShadow',
	'DrawWorldReflection',
	'DrawWorldRefraction',
	'DrawUnitsPostDeferred',
	'DrawFeaturesPostDeferred',
	'DrawScreenEffects',
	'DrawScreenPost',
	'DrawInMiniMap',
	'DefaultCommand',
}
local reverseCallInMap = {}
for _, ci in ipairs(reverseCallIns) do
	reverseCallInMap[ci] = true
end

local callInLists = {
	'PlayerChangedTeam',
	'PlayerResigned',
	'GamePreload',
	'GameStart',
	'Shutdown',
	'Update',
	'TextCommand',
	'CommandNotify',
	'UnitCommandNotify',
	'AddConsoleLine',
	'ReceiveUserInfo',
	-- widget:ReceiveUserInfo(info)
	-- info is a table with keys name, avatar, icon, badges, admin, clan, faction, country
	-- values are strings except:
	-- badges: comma separated string of badge names
	-- admin: boolean
	'ViewResize',
	'DrawScreen',
	'KeyPress',
	'KeyRelease',
	'TextInput',
	'MousePress',
	'MouseWheel',
	'JoyAxis',
	'JoyHat',
	'JoyButtonDown',
	'JoyButtonUp',
	'IsAbove',
	'GetTooltip',
	'GroupChanged',
	'CommandsChanged',
	'TweakMousePress',
	'TweakMouseWheel',
	'TweakIsAbove',
	'TweakGetTooltip',
	'GameProgress',
	'UnsyncedHeightMapUpdate',
	'VisibleUnitAdded',
	'VisibleUnitRemoved',
	'VisibleUnitsChanged',
	'AlliedUnitAdded',
	'AlliedUnitRemoved',
	'AlliedUnitsChanged',
-- these use mouseOwner instead of lists
--  'MouseMove',
--  'MouseRelease',
--  'TweakKeyPress',
--  'TweakKeyRelease',
--  'TweakMouseMove',
--  'TweakMouseRelease',

-- uses the DrawScreenList
--  'TweakDrawScreen',
}

-- append the flex call-ins
for _, uci in ipairs(flexCallIns) do
	table.insert(callInLists, uci)
end


-- initialize the call-in lists
do
	for _, listname in ipairs(callInLists) do
		widgetHandler[listname..'List'] = {}
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  array-table reverse iterator
--
--  all callin handlers use this so that widgets can
--  RemoveWidget() themselves (during iteration over
--  a callin list) without causing a miscount
--
--  Reverse iteration for drawing is achieved by adding
--  callins to the lists in the non-reverse order.
--
--  c.f. Array{Insert,Remove,InsertReverse}
--

local function r_iter(tbl, key)
	if (key <= 1) then
		return nil
	end
	-- next idx, next val
	return (key - 1), tbl[key - 1]
end

local function r_ipairs(tbl)
	return r_iter, tbl, (1 + #tbl)
end

-- String helper to split by delimiter (userinfo)

function string:split(delimiter)
	local result = { }
	local from  = 1
	local delim_from, delim_to = string.find( self, delimiter, from  )
	while delim_from do
		table.insert( result, string.sub( self, from , delim_from-1 ) )
		from  = delim_to + 1
		delim_from, delim_to = string.find( self, delimiter, from  )
	end
	table.insert( result, string.sub( self, from  ) )
	return result
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- helper functions
---include chat preprocess here

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widgetHandler:LoadOrderList()
	local chunk, err = loadfile(ORDER_FILENAME)
	if (chunk == nil) then
		self.orderList = {} -- safety
		return {}
	else
		local tmp = {}
		setfenv(chunk, tmp)
		self.orderList = chunk()
		if (not self.orderList) then
			self.orderList = {} -- safety
		end
		if (self.orderList.version or 0) < ORDER_VERSION then
			self.orderList = {}
			self.orderList.version = ORDER_VERSION
		end
		local detailLevel = Spring.GetConfigInt("widgetDetailLevel", 2)
		if (self.orderList.lastWidgetDetailLevel ~= detailLevel) then
			resetWidgetDetailLevel = true
			self.orderList.lastWidgetDetailLevel = detailLevel
		end
	end
end


function widgetHandler:SaveOrderList()
	-- update the current order
	for i, w in ipairs(self.widgets) do
		self.orderList[w.whInfo.name] = i
	end
	table.save(self.orderList, ORDER_FILENAME, '-- Widget Order List  (0 disables a widget)')
end


--------------------------------------------------------------------------------

function widgetHandler:LoadConfigData()
	local chunk, err = loadfile(CONFIG_FILENAME)
	if (chunk == nil) then
		return {}
	else
		local tmp = {}
		setfenv(chunk, tmp)
		self.configData = chunk()
		if (not self.configData) then
			self.configData = {} -- safety
		end
		if (self.configData.version or 0) < DATA_VERSION then
			self.configData = {}
			self.configData.version = DATA_VERSION
		end
	end
end


function widgetHandler:SaveConfigData()
	resetWidgetDetailLevel = false
	self:LoadConfigData()
	for _, w in ipairs(self.widgets) do
		if (w.GetConfigData) then
			local ok, err = pcall(function()
				self.configData[w.whInfo.name] = w:GetConfigData()
			end)
			if not ok then Spring.Log(HANDLER_BASENAME, LOG.ERROR, "Failed to GetConfigData from: " .. w.whInfo.name.." ("..err..")") end
		end
	end
	table.save(self.configData, CONFIG_FILENAME, '-- Widget Custom Data')
end


function widgetHandler:SendConfigData()
	self:LoadConfigData()
	for _, w in ipairs(self.widgets) do
		local data = self.configData[w.whInfo.name]
		if (w.SetConfigData and data) then
			w:SetConfigData(data)
		end
	end
end

--------------------------------------------------------------------------------

local function InitPlayerData(playerID)
	local _, _, spectator, teamID = Spring.GetPlayerInfo(playerID)
	return {team = teamID, spectator = spectator}
end

-- https://github.com/beyond-all-reason/spring/issues/1526
-- FIXME: poison VFS.DirList directly since the issue affects any call thereof
local function RemoveDuplicateFilenames(files)
	local commons = {}
	local i = 1
	while files[i] do
		local filename = files[i]:gsub('\\','/')
		if commons[filename] then
			table.remove(files,i)
		else
			commons[filename] = true
			i = i + 1
		end
	end
end

function widgetHandler:Initialize()
	TimeLoad("==== widgetHandler Begin ====")
	local gaia = Spring.GetGaiaTeamID()
	local playerList = Spring.GetPlayerList()
	for i = 1, #playerList do
		playerstate[playerList[i]] = InitPlayerData(playerList[i])
	end

	-- Add ignorelist --
	--Spring.Echo("Spring.GetMyPlayerID()", Spring.GetMyPlayerID())
	local customkeys = select(10, Spring.GetPlayerInfo(Spring.GetMyPlayerID(), true))
	--Spring.Echo("Spring.GetMyPlayerID() done", customkeys)
	if customkeys["ignored"] then
		if string.find(customkeys["ignored"], ",") then
			local newignorelist = string.gsub(customkeys["ignored"], ",", " ")
			Spring.Echo("Setting Serverside ignorelist: " .. newignorelist)
			for ignoree in string.gmatch(newignorelist, "%S+") do
				ignorelist.ignorees[ignoree] = true
				ignorelist.count = ignorelist.count + 1
			end
			newignorelist = nil
		elseif string.len(customkeys["ignored"]) > 1 then
			ignorelist.ignorees[customkeys["ignored"]] = true
			ignorelist.count = ignorelist.count + 1
		end
	end
	customkeys = nil
	TimeLoad("Add ignorelist")

	self:LoadOrderList()
	TimeLoad("LoadOrderList")
	self:LoadConfigData()
	TimeLoad("LoadConfigData")

	local autoModWidgets = Spring.GetConfigInt('LuaAutoModWidgets', 1)
	self.autoModWidgets = (autoModWidgets ~= 0)

	-- create the "LuaUI/Config" directory
	Spring.CreateDir(LUAUI_DIRNAME .. 'Config')

	local unsortedWidgets = {}

	TimeLoad("Start loading widget files")
	-- stuff the widgets into unsortedWidgets
	local widgetFiles = VFS.DirList(WIDGET_DIRNAME, "*.lua", VFSMODE)
	if VFSMODE == VFS.ZIP_FIRST or VFSMODE == VFS.RAW_FIRST then
		RemoveDuplicateFilenames(widgetFiles)
	end
	local wantYield = Spring.Yield and Spring.Yield()
	for k, wf in ipairs(widgetFiles) do
		local widget = self:LoadWidget(wf)
		TimeLoad("LoadWidget " .. wf)
		if (widget) then
			table.insert(unsortedWidgets, widget)
		end
		if wantYield then
			Spring.Yield()
		end
	end
	TimeLoad("End loading widget files")

	-- sort the widgets
	table.sort(unsortedWidgets, function(w1, w2)
		local l1 = w1.whInfo.layer
		local l2 = w2.whInfo.layer
		if (l1 ~= l2) then
			return (l1 < l2)
		end
		local n1 = w1.whInfo.name
		local n2 = w2.whInfo.name
		local o1 = self.orderList[n1]
		local o2 = self.orderList[n2]
		if (o1 ~= o2) then
			return (o1 < o2)
		else
			return (n1 < n2)
		end
	end)
	TimeLoad("sort the widgets")

	-- first add the api widgets
	for _, w in ipairs(unsortedWidgets) do
		if (w.whInfo.api) then
			widgetHandler:InsertWidget(w)

			local name = w.whInfo.name
			local basename = w.whInfo.basename
			TimeLoad("Add widget " .. name)
			Spring.Echo(string.format("Loaded API widget:  %-18s  <%s>", name, basename))
		end
	end

	-- add the widgets
	for _, w in ipairs(unsortedWidgets) do
		if (not w.whInfo.api) then
			widgetHandler:InsertWidget(w)

			local name = w.whInfo.name
			local basename = w.whInfo.basename
			TimeLoad("Add widget " .. name)
			Spring.Echo(string.format("Loaded widget:  %-18s  <%s>", name, basename))
		end
	end

	-- save the active widgets, and their ordering
	self:SaveOrderList()
	TimeLoad("SaveOrderList")
	self:SaveConfigData()
	TimeLoad("SaveConfigData")
end

local springRestricted = {}
local restrictedFunctions = {
	--[[ These are blocked for being unfair because of latency and performance.
	     Feel free to make a gadget instead though. See https://zero-k.info/Forum/Thread/34108 ]]
	"GetVisibleProjectiles",
	"GetProjectilesInRectangle",

	"GetTeamDamageStats", -- LoS hax
}
local restrictedWhitelist = {
	--[[ Other widgets have security holes and there is
	     no reason for them to have access anyway. ]]
	['LuaUI/Widgets/gfx_projectile_lights.lua'] = true,
	['LuaUI/Widgets/gfx_deferred_rendering_gl4.lua'] = true,
}

for i = 1, #restrictedFunctions do
	local funcName = restrictedFunctions[i]
	springRestricted[funcName] = Spring[funcName]
	Spring[funcName] = nil
end

function widgetHandler:LoadWidget(filename, _VFSMODE)
	local kbytes = 0
	if MEMORY_DEBUG then
		collectgarbage("collect") -- call it twice, mark
		collectgarbage("collect") -- sweep
		kbytes = gcinfo()
	end

	_VFSMODE = _VFSMODE or VFSMODE
	local basename = Basename(filename)

	local fromZip
	if _VFSMODE == VFS.ZIP then
		fromZip = true
	elseif _VFSMODE == VFS.RAW_FIRST then
		fromZip = not VFS.FileExists(filename, VFS.RAW_ONLY)
	else
		fromZip = VFS.FileExists(filename, VFS.ZIP_ONLY)
	end

	local text = VFS.LoadFile(filename, _VFSMODE)

	if (text == nil) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (missing file: ' .. filename ..')')
		return nil
	end
	local chunk, err = loadstring(text, filename)
	if (chunk == nil) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename, err)
		return nil
	end

	local exposeRestricted = fromZip and restrictedWhitelist[filename]
	local widget = widgetHandler:NewWidget(exposeRestricted)

	setfenv(chunk, widget)
	local success, err = pcall(chunk)
	if (not success) then
		Spring.Echo('Failed to load: ' .. basename, err)
		return nil
	end
	if (err == false) then
		return nil -- widget asked for a silent death
	end

	-- raw access to widgetHandler
	if (widget.GetInfo and widget:GetInfo().handler) then
		widget.widgetHandler = self
	end

	self:FinalizeWidget(widget, filename, basename)
	local name = widget.whInfo.name
	if (basename == SELECTOR_BASENAME) then
		self.orderList[name] = 1  --  always enabled
	end

	err = self:ValidateWidget(widget)
	if (err) then
		Spring.Echo('Failed to load: ' .. basename .. '  (' .. err .. ')')
		return nil
	end

	local knownInfo = self.knownWidgets[name]
	if (knownInfo) then
		if (knownInfo.active) then
			Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (duplicate name)')
			return nil
		end
	else
		-- create a knownInfo table
		knownInfo = {}
		knownInfo.desc     = widget.whInfo.desc
		knownInfo.author   = widget.whInfo.author
		knownInfo.basename = widget.whInfo.basename
		knownInfo.filename = widget.whInfo.filename
		knownInfo.alwaysStart = widget.whInfo.alwaysStart
		knownInfo.fromZip  = fromZip
		self.knownWidgets[name] = knownInfo
		self.knownCount = self.knownCount + 1
		self.knownChanged = true
	end
	knownInfo.active = true

	if (widget.GetInfo == nil) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (no GetInfo() call)')
		return nil
	end

	local info  = widget:GetInfo()
	local order = self.orderList[name]

	local enabled = ((order ~= nil) and (order > 0)) or ((order == nil) and  -- unknown widget
		(info.enabled and ((not knownInfo.fromZip) or self.autoModWidgets))) or info.alwaysStart
	if resetWidgetDetailLevel and info.detailsDefault ~= nil then
		if type(info.detailsDefault) == "table" then
			enabled = info.detailsDefault[detailLevel] and true
		elseif type(info.detailsDefault) == "number" then
			enabled = detailLevel >= info.detailsDefault
		elseif tonumber(info.detailsDefault) then
			enabled = detailLevel >= tonumber(info.detailsDefault)
		end
	end

	if (enabled) then
		-- this will be an active widget
		if (order == nil) then
			self.orderList[name] = 12345  -- back of the pack
		else
			self.orderList[name] = order
		end
	else
		self.orderList[name] = 0
		self.knownWidgets[name].active = false
		return nil
	end

	-- load the config data
	local config = self.configData[name]
	if (widget.SetConfigData and config) then
		widget:SetConfigData(config)
	end

	if kbytes > 0 then
		collectgarbage("collect") -- mark
		collectgarbage("collect") -- sweep
		Spring.Echo("LoadWidget\t" .. filename .. "\t" .. (gcinfo() - kbytes) .. "\t" .. gcinfo())
	end
	return widget
end

function widgetHandler:NewWidget(exposeRestricted)
	tracy.ZoneBeginN("W:NewWidget")

	local widget = {}

	-- copy the system calls into the widget table
	-- don't use metatable redirection to System so as not to pollute it
	for k, v in pairs(System) do
		widget[k] = v
	end

	if exposeRestricted then
		widget.SpringRestricted = springRestricted
	end

	widget.WG = self.WG    -- the shared table
	widget.widget = widget -- easy self referencing

	-- wrapped calls (closures)
	widget.widgetHandler = {}
	local wh = widget.widgetHandler
	local self = self
	widget.include  = function (f, _, MODE) return include(f, widget, MODE) end
	wh.ForceLayout  = function (_) self:ForceLayout() end
	wh.RaiseWidget  = function (_) self:RaiseWidget(widget) end
	wh.LowerWidget  = function (_) self:LowerWidget(widget) end
	wh.RemoveWidget = function (_) self:RemoveWidget(widget) end
	wh.GetCommands  = function (_) return self.commands end
	wh.InTweakMode  = function (_) return self.tweakMode end
	wh.GetViewSizes = function (_) return self:GetViewSizes() end
	wh.GetHourTimer = function (_) return self:GetHourTimer() end
	wh.IsMouseOwner = function (_) return (self.mouseOwner == widget) end
	wh.DisownMouse  = function (_)
		if (self.mouseOwner == widget) then
			self.mouseOwner = nil
		end
	end
	wh.Ignore = function (_, name)
		if not ignorelist.ignorees[name] then
			ignorelist.ignorees[name] = true
			ignorelist.count = ignorelist.count + 1
		end
	end
	wh.Unignore = function (_, name)
		ignorelist.ignorees[name] = nil
		ignorelist.count = ignorelist.count - 1
	end

	wh.GetIgnoreList = function (_)
		return ignorelist["ignorees"], ignorelist.count
	end

	wh.UpdateCallIn = function (_, name)
		self:UpdateWidgetCallIn(name, widget)
	end
	wh.RemoveCallIn = function (_, name)
		self:RemoveWidgetCallIn(name, widget)
	end

	wh.AddAction    = function (_, cmd, func, data, types)
		return self.actionHandler:AddAction(widget, cmd, func, data, types)
	end
	wh.RemoveAction = function (_, cmd, types)
		return self.actionHandler:RemoveAction(widget, cmd, types)
	end

	wh.AddLayoutCommand = function (_, cmd)
		if (self.inCommandsChanged) then
			table.insert(self.customCommands, cmd)
		else
			Spring.Log(HANDLER_BASENAME, LOG.ERROR, "AddLayoutCommand() can only be used in CommandsChanged()")
		end
	end

	wh.RegisterGlobal = function(_, name, value)
		return self:RegisterGlobal(widget, name, value)
	end
	wh.DeregisterGlobal = function(_, name)
		return self:DeregisterGlobal(widget, name)
	end
	wh.SetGlobal = function(_, name, value)
		return self:SetGlobal(widget, name, value)
	end

	wh.ConfigLayoutHandler = function(_, d) self:ConfigLayoutHandler(d) end

	----
	widget.ProcessConsoleBuffer = function(_, _, num)	-- FIXME: probably not the least hacky way to make ProcessConsoleBuffer accessible to widgets
		return MessageProcessor:ProcessConsoleBuffer(num) --chat_preprocess.lua
	end
	----

	tracy.ZoneEnd()
	return widget
end


function widgetHandler:FinalizeWidget(widget, filename, basename)
	local wi

	if (widget.GetInfo == nil) then
		wi = {}
		wi.filename = filename
		wi.basename = basename
		wi.name  = basename
		wi.layer = 0
	else
		local info = widget:GetInfo()
		wi = info
		wi.filename = filename
		wi.basename = basename
		wi.name     = wi.name    or basename
		wi.layer    = wi.layer   or 0
		wi.desc     = wi.desc    or ""
		wi.author   = wi.author  or ""
		wi.license  = wi.license or ""
		wi.enabled  = wi.enabled or false
		wi.api      = wi.api or false
	end

	widget.whInfo = {}  --  a proxy table
	local mt = {
		__index = wi,
		__newindex = function() error("whInfo tables are read-only") end,
		__metatable = "protected"
	}
	setmetatable(widget.whInfo, mt)
end


function widgetHandler:ValidateWidget(widget)
	if (widget.GetTooltip and not widget.IsAbove) then
		return "Widget has GetTooltip() but not IsAbove()"
	end
	if (widget.TweakGetTooltip and not widget.TweakIsAbove) then
		return "Widget has TweakGetTooltip() but not TweakIsAbove()"
	end
	return nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function HandleError(widget, funcName, status, ...)
	if (status) then
		return ...
	end

	if (funcName ~= 'Shutdown') then
		widgetHandler:RemoveWidget(widget)
	else
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Error in Shutdown()')
	end
	local name = widget.whInfo.name
	local error_message = select(1, ...)
	Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Error in ' .. funcName ..'(): ' .. tostring(error_message))
	Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Removed widget: ' .. name)
	return nil
end

local function SafeWrapFuncNoGL(func, funcName)
	return function(w, ...)
		return HandleError(w, funcName, pcall(func, w, ...))
	end
end

local function SafeWrapFuncGL(func, funcName)
	local wh = widgetHandler

	return function(w, ...)

		glPushAttrib(GL.ALL_ATTRIB_BITS)
		local r1, r2, r3 = pcall(func, w, ...)
		glPopAttrib()

		if r1 then
			return r2, r3
		else
			if (funcName ~= 'Shutdown') then
				widgetHandler:RemoveWidget(w)
			else
				Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Error in Shutdown()')
			end
			local name = w.whInfo.name
			Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Error in ' .. funcName ..'(): ' .. tostring(r[2]))
			Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Removed widget: ' .. name)
			return nil
		end
	end
end


local function SafeWrapFunc(func, funcName)
	if (not SAFEDRAW) then
		return SafeWrapFuncNoGL(func, funcName)
	else
		if (string.sub(funcName, 1, 4) ~= 'Draw') then
			return SafeWrapFuncNoGL(func, funcName)
		else
			return SafeWrapFuncGL(func, funcName)
		end
	end
end


local function SafeWrapWidget(widget)
	if (SAFEWRAP <= 0) then
		return
	elseif (SAFEWRAP == 1) then
		if (widget.GetInfo and widget.GetInfo().unsafe) then
			Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'LuaUI: loaded unsafe widget: ' .. widget.whInfo.name)
			return
		end
	end

	for _, ciName in ipairs(callInLists) do
		if (widget[ciName]) then
			widget[ciName] = SafeWrapFunc(widget[ciName], ciName)
		end
	end
	if (widget.Initialize) then
		widget.Initialize = SafeWrapFunc(widget.Initialize, 'Initialize')
	end
end


--------------------------------------------------------------------------------

local function ArrayInsert(t, f, w)
	if (f) then
		local layer = w.whInfo.layer
		local index = 1
		for i, v in ipairs(t) do
			if (v == w) then
				return -- already in the table
			end

			-- insert-sort the gadget based on its layer
			-- note: reversed value ordering, highest to lowest
			-- iteration over the callin lists is also reversed
			if (layer < v.whInfo.layer) then
				index = i + 1
			end
		end
		table.insert(t, index, w)
	end
end


-- This is the reverse insertion because arrays are iterated over backwards.
local function ArrayInsertReverse(t, f, w)
	if (f) then
		local layer = w.whInfo.layer
		local index = 1
		for i, v in ipairs(t) do
			if (v == w) then
				return -- already in the table
			end
			if (layer >= v.whInfo.layer) then
				index = i + 1
			end
		end
		table.insert(t, index, w)
	end
end


local function ArrayRemove(t, w)
	for k, v in ipairs(t) do
		if (v == w) then
			table.remove(t, k)
			-- break
		end
	end
end


function widgetHandler:InsertWidget(widget)
	if (widget == nil) then
		return
	end

	SafeWrapWidget(widget)

	ArrayInsert(self.widgets, true, widget)
	for _, listname in ipairs(callInLists) do
		local func = widget[listname]
		if (type(func) == 'function') then
			if reverseCallInMap[listname] then
				ArrayInsertReverse(self[listname..'List'], func, widget)
			else
				ArrayInsert(self[listname..'List'], func, widget)
			end
		end
	end
	self:UpdateCallIns()

	if (widget.Initialize) then
		widget:Initialize()
	end
end


function widgetHandler:RemoveWidget(widget)
	if (widget == nil) then
		return
	end

	local name = widget.whInfo.name
	if (widget.GetConfigData) then
		local ok, err = pcall(function()
			self.configData[name] = widget:GetConfigData()
		end)
		if not ok then Spring.Log(HANDLER_BASENAME, LOG.ERROR, "Failed to GetConfigData: " .. name.." ("..err..")") end
	end
	self.knownWidgets[name].active = false
	if (widget.Shutdown) then
		widget:Shutdown()
	end
	ArrayRemove(self.widgets, widget)
	self:RemoveWidgetGlobals(widget)
	self.actionHandler:RemoveWidgetActions(widget)
	for _, listname in ipairs(callInLists) do
		ArrayRemove(self[listname..'List'], widget)
	end
	self:UpdateCallIns()
end


--------------------------------------------------------------------------------

function widgetHandler:UpdateCallIn(name)
	local listName = name .. 'List'
	if ((name == 'Update') or (name == 'DrawScreen')) then
		return
	end

	if ((#self[listName] > 0) or (not flexCallInMap[name]) or ((name == 'GotChatMsg') and actionHandler.HaveChatAction()) or ((name == 'RecvFromSynced') and actionHandler.HaveSyncAction())) then
		-- always assign these call-ins
		local selffunc = self[name]
		_G[name] = function(...)
		return selffunc(self, ...)
		end
	else
		_G[name] = nil
	end
	Script.UpdateCallIn(name)
end


function widgetHandler:UpdateWidgetCallIn(name, w)
	local listName = name .. 'List'
	local ciList = self[listName]
	if (ciList) then
		local func = w[name]
		if (type(func) == 'function') then
			if reverseCallInMap[name] then
				ArrayInsertReverse(ciList, func, w)
			else
				ArrayInsert(ciList, func, w)
			end
		else
			ArrayRemove(ciList, w)
		end
		self:UpdateCallIn(name)
	else
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'UpdateWidgetCallIn: bad name: ' .. name)
	end
end


function widgetHandler:RemoveWidgetCallIn(name, w)
	local listName = name .. 'List'
	local ciList = self[listName]
	if (ciList) then
		ArrayRemove(ciList, w)
		self:UpdateCallIn(name)
	else
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'RemoveWidgetCallIn: bad name: ' .. name)
	end
end


function widgetHandler:UpdateCallIns()
	for _, name in ipairs(callInLists) do
		self:UpdateCallIn(name)
	end
end


--------------------------------------------------------------------------------

function widgetHandler:IsWidgetKnown(name)
	return self.knownWidgets[name] and true or false
end

function widgetHandler:EnableWidget(name)
	local ki = self.knownWidgets[name]
	if (not ki) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, "EnableWidget(), could not find widget: " .. tostring(name))
		return false
	end
	if (not ki.active) then
		Spring.Echo('Loading:  '..ki.filename)
		local order = widgetHandler.orderList[name]
		if (not order or (order <= 0)) then
			self.orderList[name] = 1
		end
		local w = self:LoadWidget(ki.filename)
		if (not w) then return false end
		self:InsertWidget(w)
		self:SaveOrderList()
	end
	return true
end


function widgetHandler:DisableWidget(name)
	local ki = self.knownWidgets[name]
	if (not ki) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, "DisableWidget(), could not find widget: " .. tostring(name))
		return false
	end
	if (ki.active) then
		local w = self:FindWidget(name)
		if (not w) then return false end
		Spring.Echo('Removed:  '..ki.filename)
		self:RemoveWidget(w)     -- deactivate
		self.orderList[name] = 0 -- disable
		self:SaveOrderList()
	end
	return true
end


function widgetHandler:ToggleWidget(name)
	local ki = self.knownWidgets[name]
	if (not ki) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, "ToggleWidget(), could not find widget: " .. tostring(name))
		return
	end
	if (ki.active) then
		return self:DisableWidget(name)
	elseif (self.orderList[name] <= 0) then
		return self:EnableWidget(name)
	else
		-- the widget is not active, but enabled; disable it
		self.orderList[name] = 0
		self:SaveOrderList()
	end
	return true
end


--------------------------------------------------------------------------------

local function FindWidgetIndex(t, w)
	for k, v in ipairs(t) do
		if (v == w) then
			return k
		end
	end
	return nil
end


local function FindLowestIndex(t, i, layer)
	for x = (i - 1), 1, -1 do
		if (t[x].whInfo.layer < layer) then
			return x + 1
		end
	end
	return 1
end


function widgetHandler:RaiseWidget(widget)
	if (widget == nil) then
		return
	end
	local function Raise(t, f, w)
	if (f == nil) then return end
		local i = FindWidgetIndex(t, w)
		if (i == nil) then return end
		local n = FindLowestIndex(t, i, w.whInfo.layer)
		if (n and (n < i)) then
			table.remove(t, i)
			table.insert(t, n, w)
		end
	end
	Raise(self.widgets, true, widget)
	for _, listname in ipairs(callInLists) do
		Raise(self[listname..'List'], widget[listname], widget)
	end
end


local function FindHighestIndex(t, i, layer)
	local ts = #t
	for x = (i + 1), ts do
		if (t[x].whInfo.layer > layer) then
			return (x - 1)
		end
	end
	return (ts + 1)
end


function widgetHandler:LowerWidget(widget)
	if (widget == nil) then
		return
	end
	local function Lower(t, f, w)
		if (f == nil) then return end
		local i = FindWidgetIndex(t, w)
		if (i == nil) then return end
		local n = FindHighestIndex(t, i, w.whInfo.layer)
		if (n and (n > i)) then
			table.insert(t, n, w)
			table.remove(t, i)
		end
	end
	Lower(self.widgets, true, widget)
	for _, listname in ipairs(callInLists) do
		Lower(self[listname..'List'], widget[listname], widget)
	end
end


function widgetHandler:FindWidget(name)
	if (type(name) ~= 'string') then
		return nil
	end
	for k, v in ipairs(self.widgets) do
		if (name == v.whInfo.name) then
			return v, k
		end
	end
	return nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Global var/func management
--

function widgetHandler:RegisterGlobal(owner, name, value)
	if ((name == nil) or (_G[name]) or (self.globals[name]) or (CallInsMap[name])) then
		return false
	end
	_G[name] = value
	self.globals[name] = owner
	return true
end


function widgetHandler:DeregisterGlobal(owner, name)
	if ((name == nil) or (self.globals[name] and (self.globals[name] ~= owner))) then
		return false
	end
	_G[name] = nil
	self.globals[name] = nil
	return true
end


function widgetHandler:SetGlobal(owner, name, value)
	if ((name == nil) or (self.globals[name] ~= owner)) then
		return false
	end
	_G[name] = value
	return true
end


function widgetHandler:RemoveWidgetGlobals(owner)
	local count = 0
	for name, o in pairs(self.globals) do
		if (o == owner) then
			_G[name] = nil
			self.globals[name] = nil
			count = count + 1
		end
	end
	return count
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Helper facilities
--

local hourTimer = 0


function widgetHandler:GetHourTimer()
	return hourTimer
end

function widgetHandler:GetViewSizes()
	--FIXME remove
	return gl.GetViewSizes()
end

function widgetHandler:ForceLayout()
	forceLayout = true  --  in main.lua
end


function widgetHandler:ConfigLayoutHandler(data)
	ConfigLayoutHandler(data)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in distribution routines
--

function widgetHandler:Shutdown()
	Spring.Echo("Start widgetHandler:Shutdown")
	self:SaveOrderList()
	Spring.Echo("Shutdown - SaveOrderList Complete")
	self:SaveConfigData()
	Spring.Echo("Shutdown - SaveConfigData Complete")
	for _, w in r_ipairs(self.ShutdownList) do
		local name = w.whInfo.name or "UNKNOWN NAME"
		Spring.Echo("Shutdown Widget - " .. name)
		w:Shutdown()
	end
	Spring.Echo("End widgetHandler:Shutdown")
end

function widgetHandler:Update()
	local deltaTime = Spring.GetLastUpdateSeconds()
	-- update the hour timer
	hourTimer = (hourTimer + deltaTime)%3600

	tracy.ZoneBeginN("W:Update")
	for _, w in r_ipairs(self.UpdateList) do
		tracy.ZoneBeginN("W:Update:" .. w.whInfo.name)
		w:Update(deltaTime)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:ConfigureLayout(command)
	if (command == 'tweakgui') then
		self.tweakMode = true
		Spring.Echo("LuaUI TweakMode: ON")
		return true
	elseif (command == 'reconf') then
		self:SendConfigData()
		return true
	elseif (command == 'selector') then
		for _, w in ipairs(self.widgets) do
			if (w.whInfo.basename == SELECTOR_BASENAME) then
				return true  -- there can only be one
			end
		end
		local sw = self:LoadWidget(LUAUI_DIRNAME .. SELECTOR_BASENAME, VFS.RAW_FIRST)
		self:InsertWidget(sw)
		self:RaiseWidget(sw)
		return true
	elseif (string.find(command, 'togglewidget') == 1) then
		self:ToggleWidget(string.sub(command, 14))
		return true
	elseif (string.find(command, 'enablewidget') == 1) then
		self:EnableWidget(string.sub(command, 14))
		return true
	elseif (string.find(command, 'disablewidget') == 1) then
		self:DisableWidget(string.sub(command, 15))
		return true
	end

	if (self.actionHandler:TextAction(command)) then
		return true
	end

	for _, w in r_ipairs(self.TextCommandList) do
		if (w:TextCommand(command)) then
			return true
		end
	end
	return false
end

function widgetHandler:CommandNotify(id, params, options)
	tracy.ZoneBeginN("W:CommandNotify")
	for _, w in r_ipairs(self.CommandNotifyList) do
		tracy.ZoneBeginN("W:CommandNotify:" .. w.whInfo.name)
		if (w:CommandNotify(id, params, options)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()

	return false
end

function widgetHandler:UnitCommandNotify(unitID, id, params, options)
	tracy.ZoneBeginN("W:UnitCommandNotify")
	for _, w in r_ipairs(self.UnitCommandNotifyList) do
		tracy.ZoneBeginN("W:UnitCommandNotify:" .. w.whInfo.name)
		if (w:UnitCommandNotify(unitID, id, params, options)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

local MUTE_SPECTATORS = Spring.GetModOptions().mutespec or 'autodetect'
local MUTE_LOBBY = Spring.GetModOptions().mutelobby or 'autodetect'
local playerNameToID

do
	local teams = Spring.GetTeamList();
	local humanAlly = {}
	local humanAllyCount = 0
	gaiaTeam = Spring.GetGaiaTeamID()
	for _, teamID in ipairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if ((teamLuaAI == nil or teamLuaAI == "") and teamID ~= gaiaTeam) then
			local _, _, _, ai, side, ally = Spring.GetTeamInfo(teamID, false)
			if (not ai) and (not humanAlly[ally]) then
				humanAlly[ally] = true
				humanAllyCount = humanAllyCount + 1
			end
		end
	end

	if MUTE_SPECTATORS == 'autodetect' then
		if humanAllyCount > 2 then
			MUTE_SPECTATORS = true
		else
			MUTE_SPECTATORS = false
		end
	else
		MUTE_SPECTATORS = (MUTE_SPECTATORS == 'mute')
	end

	if MUTE_LOBBY == 'autodetect' then
		if humanAllyCount > 2 then
			MUTE_LOBBY = true
		else
			MUTE_LOBBY = false
		end
	else
		MUTE_LOBBY = (MUTE_LOBBY == 'mute')
	end

	if MUTE_LOBBY then
		playerNameToID = {}
		local playerList = Spring.GetPlayerList()
		for i = 1, #playerList do
			local playerID = playerList[i]
			if playerID then
				local name, _, spectating = Spring.GetPlayerInfo(playerID, false)
				if not spectating then
					playerNameToID[name] = playerID
				end
			end
		end
	end
end


--NOTE: StringStarts() and MessageProcessor is included in "chat_preprocess.lua"
function widgetHandler:AddConsoleLine(msg, priority)

	if StringStarts(msg, "Error: Invalid command received") or StringStarts(msg, "Error: Dropped command ") then
		return
	else
		--censor message for muted player. This is mandatory, everyone is forced to close ears to muted players (ie: if it is optional, then everyone will opt to hear muted player for spec-cheat info. Thus it will defeat the purpose of mute)
		local newMsg = { text = msg, priority = priority }
		MessageProcessor:ProcessConsoleLine(newMsg) --chat_preprocess.lua
		if newMsg.msgtype ~= 'other' and newMsg.msgtype ~= 'autohost' and newMsg.msgtype ~= 'userinfo' and newMsg.msgtype ~= 'game_message' and newMsg.msgtype ~= 'game_priority_message' then
			if MUTE_SPECTATORS and newMsg.msgtype == 'spec_to_everyone' then
				local spectating = select(1, Spring.GetSpectatingState())
				if not spectating then
					return
				end
				newMsg.msgtype = 'spec_to_specs'
			end
			local playerID_msg = newMsg.player and newMsg.player.id --retrieve playerID from message.
			local customkeys = select(10, Spring.GetPlayerInfo(playerID_msg))
			if customkeys and (customkeys.muted or (newMsg.msgtype == 'spec_to_everyone' and ((customkeys.can_spec_chat or '1') == '0'))) then
				local myPlayerID = Spring.GetLocalPlayerID()
				if myPlayerID == playerID_msg then --if I am the muted, then:
					newMsg.argument = "<your message was blocked by mute>"	--remind myself that I am muted.
					msg = "<your message was blocked by mute>"
				else --if I am NOT the muted, then: delete this message
					return
				end
				--TODO: improve chili_chat2 spam-filter/dedupe-detection too.
			end
			-- IGNORE FEATURE--
			if ignorelist.ignorees[select(1, Spring.GetPlayerInfo(playerID_msg, false))] then
				return
			end
		end

		if MUTE_LOBBY and newMsg.msgtype == 'autohost' then
			local spectating = select(1, Spring.GetSpectatingState())
			if (not spectating) and newMsg.argument then
				-- Chat from lobby has format '<PlayerName>message'
				if string.sub(newMsg.argument, 1, 1) == "<" then
					local endChar = string.find(newMsg.argument, ">")
					if endChar then
						local name = string.sub(newMsg.argument, 2, endChar-1)
						if playerNameToID[name] then
							local spectating = select(3, Spring.GetPlayerInfo(playerNameToID[name], false))
							if spectating then
								playerNameToID[name] = nil
								return
							end
						else
							return
						end
					else
						return
					end
				end
			end
		end
		--Ignore's lobby blocker.--
		if newMsg.msgtype == 'autohost' and newMsg.argument and string.sub(newMsg.argument, 1, 1) == "<" then
			local endChar = string.find(newMsg.argument, ">")
			if endChar then
				local name = string.sub(newMsg.argument, 2, endChar-1)
				if ignorelist.ignorees[name] then
					return -- block chat
				end
			end
		end
		if newMsg.msgtype == 'userinfo' and newMsg.argument then

			local list = newMsg.argument:split("|")
			local info = {
				name = list[1],
				avatar = list[2],
				icon = list[3],
				badges = list[4],
				admin = list[5] and string.lower(list[5]) == 'true',
				clan = list[6],
				faction = list[7],
				country = list[8],
			}

			--send message to widget:ReceiveUserInfo
			for _, w in r_ipairs(self.ReceiveUserInfoList) do
				w:ReceiveUserInfo(info)
			end
			return
		end
		--send message to widget:AddConsoleLine
		for _, w in r_ipairs(self.AddConsoleLineList) do
			w:AddConsoleLine(msg, priority)
		end

		--send message to widget:AddConsoleMessage
		if newMsg.msgtype == 'point' or newMsg.msgtype == 'label' then
			return -- ignore all console messages about points... those come in through the MapDrawCmd callin
		end
		for _, w in r_ipairs(self.AddConsoleMessageList) do
			w:AddConsoleMessage(newMsg)
		end
	end
end


function widgetHandler:GroupChanged(groupID)
	tracy.ZoneBeginN("W:GroupChanged")
	for _, w in r_ipairs(self.GroupChangedList) do
		tracy.ZoneBeginN("W:GroupChanged:" .. w.whInfo.name)
		w:GroupChanged(groupID)
		tracy.ZoneEnd()

	end
	tracy.ZoneEnd()

end


function widgetHandler:CommandsChanged()
	tracy.ZoneBeginN("W:CommandsChanged")
	if widgetHandler:UpdateSelection() then -- for selectionchanged
		tracy.ZoneEnd()
		return -- selection updated, don't call commands changed.
	end
	self.inCommandsChanged = true
	self.customCommands = {}
	for _, w in r_ipairs(self.CommandsChangedList) do
		tracy.ZoneBeginN("W:CommandsChanged:" .. w.whInfo.name)
		w:CommandsChanged()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()

	self.inCommandsChanged = false
end


function widgetHandler:TeamColorsChanged()
	tracy.ZoneBeginN("W:TeamColorsChanged")
	for _, w in r_ipairs(self.TeamColorsChangedList) do
		tracy.ZoneBeginN("W:TeamColorsChanged:" .. w.whInfo.name)
		w:TeamColorsChanged();
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

--------------------------------------------------------------------------------
--
--  Drawing call-ins
--


function widgetHandler:ViewResize(viewGeometry)
	tracy.ZoneBeginN("W:ViewResize")

	local vsx = viewGeometry.viewSizeX
	local vsy = viewGeometry.viewSizeY

	for _, w in r_ipairs(self.ViewResizeList) do
		tracy.ZoneBeginN("W:ViewResize:" .. w.whInfo.name)
		w:ViewResize(vsx, vsy, viewGeometry)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawScreen()
	tracy.ZoneBeginN("W:DrawScreen")
	if (self.tweakMode) then
		gl.Color(0, 0, 0, 0.5)
		local sx, sy, px, py = Spring.GetViewGeometry()
		gl.Shape(GL.QUADS, {
			{v = { px,  py }}, {v = { px + sx, py }}, {v = { px + sx, py + sy }}, {v = { px, py + sy }}
		})
		gl.Color(1, 1, 1)
	end
	for _, w in r_ipairs(self.DrawScreenList) do
		tracy.ZoneBeginN("W:DrawScreen:" .. w.whInfo.name)
		w:DrawScreen()
		tracy.ZoneEnd()
		if (self.tweakMode and w.TweakDrawScreen) then
			tracy.ZoneBeginN("W:TweakDrawScreen:" .. w.whInfo.name)
			w:TweakDrawScreen()
			tracy.ZoneEnd()
		end
	end
	tracy.ZoneEnd()
end


function widgetHandler:DrawGenesis()
	tracy.ZoneBeginN("W:DrawGenesis")
	for _, w in r_ipairs(self.DrawGenesisList) do
		tracy.ZoneBeginN("W:DrawGenesis:" .. w.whInfo.name)
		w:DrawGenesis()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:DrawWorld()
	tracy.ZoneBeginN("W:DrawWorld")
	--local doEcho = math.random() > 0.01
	--if doEcho then
	--	local enabled, params = gl.GetFixedState("blending")
	--	Spring.Echo("enabled, params", enabled, params, "Initial")
	--	Spring.Utilities.TableEcho(params, "params")
	--end
	for _, w in r_ipairs(self.DrawWorldList) do
		gl.Fog(true)
		tracy.ZoneBeginN("W:DrawWorld:" .. w.whInfo.name)
		w:DrawWorld()
		--if doEcho then
		--	local enabled, params = gl.GetFixedState("blending")
		--	Spring.Echo("enabled, params", enabled, params, w:GetInfo().name)
		--	Spring.Utilities.TableEcho(params, "params")
		--end
		tracy.ZoneEnd()
	end
	gl.Fog(false)
	tracy.ZoneEnd()
end


function widgetHandler:DrawWorldPreUnit()
	tracy.ZoneBeginN("W:DrawWorldPreUnit")
	for _, w in r_ipairs(self.DrawWorldPreUnitList) do
		gl.Fog(true)
		tracy.ZoneBeginN("W:DrawWorldPreUnit:" .. w.whInfo.name)
		w:DrawWorldPreUnit()
		tracy.ZoneEnd()
	end
	gl.Fog(false)
	tracy.ZoneEnd()
end

function widgetHandler:DrawWorldPreParticles()
	tracy.ZoneBeginN("W:DrawWorldPreParticles")
	for _, w in r_ipairs(self.DrawWorldPreParticlesList) do
		gl.Fog(true)
		tracy.ZoneBeginN("W:DrawWorldPreParticles:" .. w.whInfo.name)
		w:DrawWorldPreParticles()
		tracy.ZoneEnd()
	end
	gl.Fog(false)
	tracy.ZoneEnd()
end


function widgetHandler:DrawWorldShadow()
	tracy.ZoneBeginN("W:DrawWorldShadow")
	for _, w in r_ipairs(self.DrawWorldShadowList) do
		gl.Fog(true)
		tracy.ZoneBeginN("W:DrawWorldShadow:" .. w.whInfo.name)
		w:DrawWorldShadow()
		tracy.ZoneEnd()
	end
	gl.Fog(false)
	tracy.ZoneEnd()
end


function widgetHandler:DrawWorldReflection()
	tracy.ZoneBeginN("W:DrawWorldReflection")
	for _, w in r_ipairs(self.DrawWorldReflectionList) do
		gl.Fog(true)
		tracy.ZoneBeginN("W:DrawWorldReflection:" .. w.whInfo.name)
		w:DrawWorldReflection()
		tracy.ZoneEnd()
	end
	gl.Fog(false)
	tracy.ZoneEnd()
end


function widgetHandler:DrawWorldRefraction()
	tracy.ZoneBeginN("W:DrawWorldRefraction")
	for _, w in r_ipairs(self.DrawWorldRefractionList) do
		gl.Fog(true)
		tracy.ZoneBeginN("W:DrawWorldRefraction:" .. w.whInfo.name)
		w:DrawWorldRefraction()
		tracy.ZoneEnd()
	end
	gl.Fog(false)
	tracy.ZoneEnd()
end


function widgetHandler:DrawUnitsPostDeferred()
	tracy.ZoneBeginN("W:DrawUnitsPostDeferred")
	for _, w in r_ipairs(self.DrawUnitsPostDeferredList) do
		tracy.ZoneBeginN("W:DrawUnitsPostDeferred:" .. w.whInfo.name)
		w:DrawUnitsPostDeferred()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:DrawFeaturesPostDeferred()
	tracy.ZoneBeginN("W:DrawFeaturesPostDeferred")
	for _, w in r_ipairs(self.DrawFeaturesPostDeferredList) do
		tracy.ZoneBeginN("W:DrawFeaturesPostDeferred:" .. w.whInfo.name)
		w:DrawFeaturesPostDeferred()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:DrawScreenEffects(vsx, vsy)
	tracy.ZoneBeginN("W:DrawScreenEffects")
	for _, w in r_ipairs(self.DrawScreenEffectsList) do
		tracy.ZoneBeginN("W:DrawScreenEffects:" .. w.whInfo.name)
		w:DrawScreenEffects(vsx, vsy)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawScreenPost(vsx, vsy)
	tracy.ZoneBeginN("W:DrawScreenPost")
	for _, w in r_ipairs(self.DrawScreenPostList) do
		tracy.ZoneBeginN("W:DrawScreenPost:" .. w.whInfo.name)
		w:DrawScreenPost(vsx, vsy)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawInMiniMap(xSize, ySize)
	tracy.ZoneBeginN("W:DrawInMiniMap")
	for _, w in r_ipairs(self.DrawInMiniMapList) do
		tracy.ZoneBeginN("W:DrawInMiniMap:" .. w.whInfo.name)
		w:DrawInMiniMap(xSize, ySize)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawOpaqueUnitsLua(deferredPass, drawReflection, drawRefraction)
	tracy.ZoneBeginN("W:DrawOpaqueUnitsLua")
	for _, w in r_ipairs(self.DrawOpaqueUnitsLuaList) do
		tracy.ZoneBeginN("W:DrawOpaqueUnitsLua:" .. w.whInfo.name)
		w:DrawOpaqueUnitsLua(deferredPass, drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawOpaqueFeaturesLua(deferredPass, drawReflection, drawRefraction)
	tracy.ZoneBeginN("W:DrawOpaqueFeaturesLua")
	for _, w in r_ipairs(self.DrawOpaqueFeaturesLuaList) do
		tracy.ZoneBeginN("W:DrawOpaqueFeaturesLua:" .. w.whInfo.name)
		w:DrawOpaqueFeaturesLua(deferredPass, drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawAlphaUnitsLua(drawReflection, drawRefraction)
	tracy.ZoneBeginN("W:DrawAlphaUnitsLua")
	for _, w in r_ipairs(self.DrawAlphaUnitsLuaList) do
		tracy.ZoneBeginN("W:DrawAlphaUnitsLua:" .. w.whInfo.name)
		w:DrawAlphaUnitsLua(drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawAlphaFeaturesLua(drawReflection, drawRefraction)
	tracy.ZoneBeginN("W:DrawAlphaFeaturesLua")
	for _, w in r_ipairs(self.DrawAlphaFeaturesLuaList) do
		tracy.ZoneBeginN("W:DrawAlphaFeaturesLua:" .. w.whInfo.name)
		w:DrawAlphaFeaturesLua(drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawShadowUnitsLua()
	tracy.ZoneBeginN("W:DrawShadowUnitsLua")
	for _, w in r_ipairs(self.DrawShadowUnitsLuaList) do
		tracy.ZoneBeginN("W:DrawShadowUnitsLua:" .. w.whInfo.name)
		w:DrawShadowUnitsLua()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:DrawShadowFeaturesLua()
	tracy.ZoneBeginN("W:DrawShadowFeaturesLua")
	for _, w in r_ipairs(self.DrawShadowFeaturesLuaList) do
		tracy.ZoneBeginN("W:DrawShadowFeaturesLua:" .. w.whInfo.name)
		w:DrawShadowFeaturesLua()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


--------------------------------------------------------------------------------
--
--  Keyboard call-ins
--

function widgetHandler:KeyPress(key, mods, isRepeat, label, unicode, scanCode, actions)
	tracy.ZoneBeginN("W:KeyPress")
	if (self.tweakMode) then
		local mo = self.mouseOwner
		if (mo and mo.TweakKeyPress) then
			mo:TweakKeyPress(key, mods, isRepeat, label, unicode, scanCode, actions)
		end
		tracy.ZoneEnd()
		return true
	end

	if (self.actionHandler:KeyAction(true, key, mods, isRepeat, scanCode, actions)) then
		tracy.ZoneEnd()
		return true
	end

	for _, w in r_ipairs(self.KeyPressList) do
		tracy.ZoneBeginN("W:KeyPress:" .. w.whInfo.name)
		if (w:KeyPress(key, mods, isRepeat, label, unicode, scanCode, actions)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end


function widgetHandler:KeyRelease(key, mods, label, unicode, scanCode, actions)
	tracy.ZoneBeginN("W:KeyRelease")

	if (self.tweakMode) then
		local mo = self.mouseOwner
		if (mo and mo.TweakKeyRelease) then
			mo:TweakKeyRelease(key, mods, label, unicode, scanCode, actions)
		elseif (key == KEYSYMS.ESCAPE) then
			Spring.Echo("LuaUI TweakMode: OFF")
			self.tweakMode = false
		end
		tracy.ZoneEnd()
		return true
	end

	if (self.actionHandler:KeyAction(false, key, mods, false, scanCode, actions)) then
		tracy.ZoneEnd()
		return true
	end

	for _, w in r_ipairs(self.KeyReleaseList) do
		tracy.ZoneBeginN("W:KeyRelease:" .. w.whInfo.name)
		if (w:KeyRelease(key, mods, label, unicode, scanCode, actions)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function widgetHandler:TextInput(utf8, ...)
	tracy.ZoneBeginN("W:TextInput")

	if (self.tweakMode) then
		tracy.ZoneEnd()
		return true
	end

	for _, w in r_ipairs(self.TextInputList) do
		tracy.ZoneBeginN("W:TextInput:" .. w.whInfo.name)
		if (w:TextInput(utf8, ...)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end


--------------------------------------------------------------------------------
--
--  Mouse call-ins
--

do
	local lastDrawFrame = 0
	local lastx, lasty = 0, 0
	local lastWidget

	local spGetDrawFrame = Spring.GetDrawFrame

	-- local helper (not a real call-in)
	function widgetHandler:WidgetAt(x, y)
		tracy.ZoneBeginN("W:WidgetAt")
		local drawframe = spGetDrawFrame()
		if (lastDrawFrame == drawframe)and(lastx == x)and(lasty == y) then
			tracy.ZoneEnd()
			return lastWidget
		end

		lastDrawFrame = drawframe
		lastx = x
		lasty = y

		if (not self.tweakMode) then
			for _, w in r_ipairs(self.IsAboveList) do
				tracy.ZoneBeginN("W:IsAbove:" .. w.whInfo.name)
				if (w:IsAbove(x, y)) then
					lastWidget = w
					tracy.ZoneEnd()
					tracy.ZoneEnd()
					return w
				end
				tracy.ZoneEnd()
			end
		else
			for _, w in r_ipairs(self.TweakIsAboveList) do
				tracy.ZoneBeginN("W:TweakIsAbove:" .. w.whInfo.name)
				if (w:TweakIsAbove(x, y)) then
					lastWidget = w
					tracy.ZoneEnd()
					tracy.ZoneEnd()
					return w
				end
				tracy.ZoneEnd()
			end
		end
		lastWidget = nil
		tracy.ZoneEnd()
		return nil
	end
end


function widgetHandler:MousePress(x, y, button)
	tracy.ZoneBeginN("W:MousePress")
	local mo = self.mouseOwner
	if (not self.tweakMode) then
		if (mo) then
			mo:MousePress(x, y, button)
			tracy.ZoneEnd()
			return true  --  already have an active press
		end
		for _, w in r_ipairs(self.MousePressList) do
			tracy.ZoneBeginN("W:MousePress:" .. w.whInfo.name)
			if (w:MousePress(x, y, button)) then
				self.mouseOwner = w
				tracy.ZoneEnd()
				tracy.ZoneEnd()
				return true
			end
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
		return false
	else
		if (mo) then
			mo:TweakMousePress(x, y, button)
			tracy.ZoneEnd()
			return true  --  already have an active press
		end
		for _, w in r_ipairs(self.TweakMousePressList) do
			tracy.ZoneBeginN("W:TweakMousePress:" .. w.whInfo.name)
			if (w:TweakMousePress(x, y, button)) then
				self.mouseOwner = w
				tracy.ZoneEnd()
				tracy.ZoneEnd()
				return true
			end
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
		return true  --  always grab the mouse
	end
end


function widgetHandler:MouseMove(x, y, dx, dy, button)
	tracy.ZoneBeginN("W:MouseMove")
	local mo = self.mouseOwner
	if (not self.tweakMode) then
		if (mo and mo.MouseMove) then
			tracy.ZoneEnd()
			return mo:MouseMove(x, y, dx, dy, button)
		end
	else
		if (mo and mo.TweakMouseMove) then
			mo:TweakMouseMove(x, y, dx, dy, button)
		end
		tracy.ZoneEnd()
		return true
	end
	tracy.ZoneEnd()
end


function widgetHandler:MouseRelease(x, y, button)
	tracy.ZoneBeginN("W:MouseRelease")
	local mo = self.mouseOwner
	local mx, my, lmb, mmb, rmb = Spring.GetMouseState()
	if (not (lmb or mmb or rmb)) then
		self.mouseOwner = nil
	end

	if (not self.tweakMode) then
		if (mo and mo.MouseRelease) then
			tracy.ZoneEnd()
			return mo:MouseRelease(x, y, button)
		end
	else
		if (mo and mo.TweakMouseRelease) then
			mo:TweakMouseRelease(x, y, button)
		end
	end
	tracy.ZoneEnd()
	return -1
end


function widgetHandler:MouseWheel(up, value)
	tracy.ZoneBeginN("W:MouseWheel")
	if (not self.tweakMode) then
		for _, w in r_ipairs(self.MouseWheelList) do
			tracy.ZoneBeginN("W:MouseWheel:" .. w.whInfo.name)
			if (w:MouseWheel(up, value)) then
				tracy.ZoneEnd()
				tracy.ZoneEnd()
				return true
			end
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
		return false
	else
		for _, w in r_ipairs(self.TweakMouseWheelList) do
			tracy.ZoneBeginN("W:TweakMouseWheel:" .. w.whInfo.name)
			if (w:TweakMouseWheel(up, value)) then
				tracy.ZoneEnd()
				tracy.ZoneEnd()
				return true
			end
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
		return false -- FIXME: always grab in tweakmode?
	end
end

function widgetHandler:JoyAxis(axis, value)
	tracy.ZoneBeginN("W:JoyAxis")
	for _, w in r_ipairs(self.JoyAxisList) do
		tracy.ZoneBeginN("W:JoyAxis:" .. w.whInfo.name)
		if (w:JoyAxis(axis, value)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function widgetHandler:JoyHat(hat, value)
	tracy.ZoneBeginN("W:JoyHat")
	for _, w in r_ipairs(self.JoyHatList) do
		tracy.ZoneBeginN("W:JoyHat:" .. w.whInfo.name)
		if (w:JoyHat(hat, value)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function widgetHandler:JoyButtonDown(button, state)
	tracy.ZoneBeginN("W:JoyButtonDown")
	for _, w in r_ipairs(self.JoyButtonDownList) do
		tracy.ZoneBeginN("W:JoyButtonDown:" .. w.whInfo.name)
		if (w:JoyButtonDown(button, state)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function widgetHandler:JoyButtonUp(button, state)
	tracy.ZoneBeginN("W:JoyButtonUpJoyButtonUp")
	for _, w in r_ipairs(self.JoyButtonUpList) do
		tracy.ZoneBeginN("W:JoyButtonUpJoyButtonUp:" .. w.whInfo.name)
		if (w:JoyButtonUp(button, state)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function widgetHandler:IsAbove(x, y)
	tracy.ZoneBeginN("W:IsAbove")
	if (self.tweakMode) then
		tracy.ZoneEnd()
		return true
	end
	tracy.ZoneEnd()
	return (widgetHandler:WidgetAt(x, y) ~= nil)
end


function widgetHandler:GetTooltip(x, y)
	tracy.ZoneBeginN("W:GetTooltip")
	if (not self.tweakMode) then
		for _, w in r_ipairs(self.GetTooltipList) do
			tracy.ZoneBeginN("W:IsAbove:" .. w.whInfo.name)
			if (w:IsAbove(x, y)) then
				tracy.ZoneEnd()
				tracy.ZoneBeginN("W:GetTooltip:" .. w.whInfo.name)
				local tip = w:GetTooltip(x, y)
				tracy.ZoneEnd()
				if ((type(tip) == 'string') and (#tip > 0)) then
					tracy.ZoneEnd()
					return tip
				end
			else
				tracy.ZoneEnd()
			end
		end
		tracy.ZoneEnd()
		return ""
	else
		for _, w in r_ipairs(self.TweakGetTooltipList) do
			tracy.ZoneBeginN("W:TweakIsAbove:" .. w.whInfo.name)
			if (w:TweakIsAbove(x, y)) then
				tracy.ZoneEnd()
				tracy.ZoneBeginN("W:TweakGetTooltip:" .. w.whInfo.name)
				local tip = w:TweakGetTooltip(x, y) or ''
				tracy.ZoneEnd()
				if ((type(tip) == 'string') and (#tip > 0)) then
					tracy.ZoneEnd()
					return tip
				end
			else
				tracy.ZoneEnd()
			end
		end
		tracy.ZoneEnd()
		return "Tweak Mode  --  hit ESCAPE to cancel"
	end
end


--------------------------------------------------------------------------------
--
--  Game call-ins
--

function widgetHandler:GamePreload()
	tracy.ZoneBeginN("W:GamePreload")
	for _, w in r_ipairs(self.GamePreloadList) do
		tracy.ZoneBeginN("W:GamePreload:" .. w.whInfo.name)
		w:GamePreload()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:GameStart()
	tracy.ZoneBeginN("W:GameStart")
	for _, w in r_ipairs(self.GameStartList) do
		tracy.ZoneBeginN("W:GameStart:" .. w.whInfo.name)
		-- If snd_music stops starting in chobby try doing this.
		--local info = w:GetInfo()
		w:GameStart()
		tracy.ZoneEnd()
	end

	local plist = ""
	gaiaTeam = Spring.GetGaiaTeamID()
	for _, teamID in ipairs(Spring.GetTeamList()) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if ((teamLuaAI == nil or teamLuaAI == "") and teamID ~= gaiaTeam) then
			local _, _, _, ai, side, ally = Spring.GetTeamInfo(teamID, false)
			if (not ai) then
				for _, pid in ipairs(Spring.GetPlayerList(teamID)) do
					local name, active, spec = Spring.GetPlayerInfo(pid, false)
					if active and not spec then plist = plist .. "," .. name end
				end
			end
		end
	end
	Spring.SendCommands("wbynum 255 SPRINGIE:stats,plist".. plist)
	tracy.ZoneEnd()
end

function widgetHandler:GameOver(winners)
	tracy.ZoneBeginN("W:GameOver")
	for _, w in r_ipairs(self.GameOverList) do
		tracy.ZoneBeginN("W:GameOver:" .. w.whInfo.name)
		w:GameOver(winners)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:GamePaused(playerID, paused)
	tracy.ZoneBeginN("W:GamePaused")
	for _, w in r_ipairs(self.GamePausedList) do
		tracy.ZoneBeginN("W:GamePaused:" .. w.whInfo.name)
		w:GamePaused(playerID, paused)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:TeamDied(teamID)
	tracy.ZoneBeginN("W:TeamDied")
	for _, w in r_ipairs(self.TeamDiedList) do
		tracy.ZoneBeginN("W:TeamDied:" .. w.whInfo.name)
		w:TeamDied(teamID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:TeamChanged(teamID)
	tracy.ZoneBeginN("W:TeamChanged")
	for _, w in r_ipairs(self.TeamChangedList) do
		tracy.ZoneBeginN("W:TeamChanged:" .. w.whInfo.name)
		w:TeamChanged(teamID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:PlayerAdded(playerID, reason) --when player Join Lobby
	tracy.ZoneBeginN("W:PlayerAdded")
	MessageProcessor:AddPlayer(playerID)
	--ListMutedPlayers()
	for _, w in r_ipairs(self.PlayerAddedList) do
		tracy.ZoneBeginN("W:PlayerAdded:" .. w.whInfo.name)
		w:PlayerAdded(playerID, reason)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:PlayerChanged(playerID) --when player Change from Spectator to Player or Player to Spectator.
	tracy.ZoneBeginN("W:PlayerChanged")
	MessageProcessor:UpdatePlayer(playerID)
	local _, _, spectator, teamID, _ = Spring.GetPlayerInfo(playerID)
	playerstate[playerID] = playerstate[playerID] or InitPlayerData(playerID)
	if spectator ~= playerstate[playerID].spectator and spectator then
		for _, w in r_ipairs(self.PlayerResignedList) do
			tracy.ZoneBeginN("W:PlayerResigned:" .. w.whInfo.name)
			w:PlayerResigned(playerID)
			tracy.ZoneEnd()
		end
	end
	if teamID ~= playerstate[playerID].team and not spectator then
		for _, w in r_ipairs(self.PlayerChangedTeamList) do
			tracy.ZoneBeginN("W:PlayerChangedTeam:" .. w.whInfo.name)
			w:PlayerChangedTeam(playerID,playerstate[playerID].team,teamID)
			tracy.ZoneEnd()
		end
	end
	playerstate[playerID].spectator = spectator
	playerstate[playerID].team = teamID
	for _, w in r_ipairs(self.PlayerChangedList) do
		tracy.ZoneBeginN("W:PlayerChanged:" .. w.whInfo.name)
		w:PlayerChanged(playerID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:PlayerRemoved(playerID, reason) --when player Left a Running Game.
	tracy.ZoneBeginN("W:PlayerRemoved")
	for _, w in r_ipairs(self.PlayerRemovedList) do
		tracy.ZoneBeginN("W:PlayerRemoved:" .. w.whInfo.name)
		w:PlayerRemoved(playerID, reason)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:GameFrame(frameNum)
	tracy.ZoneBeginN("W:GameFrame")
	for _, w in r_ipairs(self.GameFrameList) do
		tracy.ZoneBeginN("W:GameFrame:" .. w.whInfo.name)
		w:GameFrame(frameNum)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:ShockFront(power, dx, dy, dz)
	tracy.ZoneBeginN("W:ShockFront")
	for _, w in r_ipairs(self.ShockFrontList) do
		tracy.ZoneBeginN("W:ShockFront:" .. w.whInfo.name)
		w:ShockFront(power, dx, dy, dz)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:RecvSkirmishAIMessage(aiTeam, dataStr)
	tracy.ZoneBeginN("W:RecvSkirmishAIMessage")
	for _, w in r_ipairs(self.RecvSkirmishAIMessageList) do
		tracy.ZoneBeginN("W:RecvSkirmishAIMessage:" .. w.whInfo.name)
		local dataRet = w:RecvSkirmishAIMessage(aiTeam, dataStr)
		tracy.ZoneEnd()
		if (dataRet) then
			tracy.ZoneEnd()
			return dataRet
		end
	end
	tracy.ZoneEnd()
end

function widgetHandler:WorldTooltip(ttType, ...)
	tracy.ZoneBeginN("W:WorldTooltip")
	for _, w in r_ipairs(self.WorldTooltipList) do
		tracy.ZoneBeginN("W:WorldTooltip:" .. w.whInfo.name)
		local tt = w:WorldTooltip(ttType, ...)
		tracy.ZoneEnd()
		if ((type(tt) == 'string') and (#tt > 0)) then
			tracy.ZoneEnd()
			return tt
		end
	end
	tracy.ZoneEnd()
end

function widgetHandler:MapDrawCmd(playerID, cmdType, px, py, pz, ...)
	tracy.ZoneBeginN("W:MapDrawCmd")
	local playerName, _, _, _, _, _, _, _, _, customkeys = Spring.GetPlayerInfo(playerID)
	if ignorelist.ignorees[playerName] or (customkeys and customkeys.muted) then
		tracy.ZoneEnd()
		return true
	end

	local retval = false
	for _, w in r_ipairs(self.MapDrawCmdList) do
		tracy.ZoneBeginN("W:MapDrawCmd:" .. w.whInfo.name)
		local takeEvent = w:MapDrawCmd(playerID, cmdType, px, py, pz, ...)
		tracy.ZoneEnd()
		if (takeEvent) then
			retval = true
		end
	end
	tracy.ZoneEnd()
	return retval
end


function widgetHandler:GameSetup(state, ready, playerStates)
	tracy.ZoneBeginN("W:GameSetup")
	for _, w in r_ipairs(self.GameSetupList) do
		tracy.ZoneBeginN("W:GameSetup:" .. w.whInfo.name)
		local success, newReady = w:GameSetup(state, ready, playerStates)
		tracy.ZoneEnd()
		if (success) then
		tracy.ZoneEnd()
			return true, newReady
		end
	end
	tracy.ZoneEnd()
	return false
end


function widgetHandler:DefaultCommand(...)
	tracy.ZoneBeginN("W:DefaultCommand")
	for _, w in r_ipairs(self.DefaultCommandList) do
		tracy.ZoneBeginN("W:DefaultCommand:" .. w.whInfo.name)
		local result = w:DefaultCommand(...)
		tracy.ZoneEnd()
		if (type(result) == 'number') then
			tracy.ZoneEnd()
			return result
		end
	end
	tracy.ZoneEnd()
	return nil  --  not a number, use the default engine command
end


--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function widgetHandler:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	tracy.ZoneBeginN("W:UnitCreated")
	for _, w in r_ipairs(self.UnitCreatedList) do
		tracy.ZoneBeginN("W:UnitCreated:" .. w.whInfo.name)
		w:UnitCreated(unitID, unitDefID, unitTeam, builderID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

-- NB: called via Lua at the moment, not engine
function widgetHandler:UnitResurrected(unitID, unitDefID, unitTeam, builderID)
	tracy.ZoneBeginN("W:UnitResurrected")
	for _, w in r_ipairs(self.UnitResurrectedList) do
		tracy.ZoneBeginN("W:UnitResurrected:" .. w.whInfo.name)
		w:UnitResurrected(unitID, unitDefID, unitTeam, builderID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:UnitFinished(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitFinished")
	for _, w in r_ipairs(self.UnitFinishedList) do
		tracy.ZoneBeginN("W:UnitFinished:" .. w.whInfo.name)
		w:UnitFinished(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:UnitReverseBuilt(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitReverseBuilt")
	for _, w in r_ipairs(self.UnitReverseBuiltList) do
		tracy.ZoneBeginN("W:UnitReverseBuilt:" .. w.whInfo.name)
		w:UnitReverseBuilt(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	tracy.ZoneBeginN("W:UnitFromFactory")
	for _, w in r_ipairs(self.UnitFromFactoryList) do
		tracy.ZoneBeginN("W:UnitFromFactory:" .. w.whInfo.name)
		w:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitDestroyed(unitID, unitDefID, unitTeam, attackerUnitID, attackerDefID, attackerTeam)
	tracy.ZoneBeginN("W:UnitDestroyed")
	for _, w in r_ipairs(self.UnitDestroyedList) do
		tracy.ZoneBeginN("W:UnitDestroyed:" .. w.whInfo.name)
		w:UnitDestroyed(unitID, unitDefID, unitTeam, attackerUnitID, attackerDefID, attackerTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:RenderUnitDestroyed")
	for _, w in r_ipairs(self.RenderUnitDestroyedList) do
		tracy.ZoneBeginN("W:RenderUnitDestroyed:" .. w.whInfo.name)
		w:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitDestroyedByTeam(unitID, unitDefID, unitTeam, attTeamID)
	tracy.ZoneBeginN("W:UnitDestroyedByTeam")
	for _, w in r_ipairs(self.UnitDestroyedByTeamList) do
		tracy.ZoneBeginN("W:UnitDestroyedByTeam:" .. w.whInfo.name)
		w:UnitDestroyedByTeam(unitID, unitDefID, unitTeam, attTeamID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitExperience(unitID, unitDefID, unitTeam, experience, oldExperience)
	tracy.ZoneBeginN("W:UnitExperience")
	for _, w in r_ipairs(self.UnitExperienceList) do
		tracy.ZoneBeginN("W:UnitExperience:" .. w.whInfo.name)
		w:UnitExperience(unitID, unitDefID, unitTeam, experience, oldExperience)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	tracy.ZoneBeginN("W:UnitTaken")
	for _, w in r_ipairs(self.UnitTakenList) do
		tracy.ZoneBeginN("W::UnitTaken" .. w.whInfo.name)
		w:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	tracy.ZoneBeginN("W:UnitGiven")
	for _, w in r_ipairs(self.UnitGivenList) do
		tracy.ZoneBeginN("W:UnitGiven:" .. w.whInfo.name)
		w:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitIdle(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitIdle")
	for _, w in r_ipairs(self.UnitIdleList) do
		tracy.ZoneBeginN("W:UnitIdle:" .. w.whInfo.name)
		w:UnitIdle(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


if Script.IsEngineMinVersion(104, 0, 1431) then

	function widgetHandler:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag, playerID, fromSynced, fromLua) -- cmdOpts is a bitmask -- Is it? Seems to be a table.
		tracy.ZoneBeginN("W:UnitCommand")
		for _, w in r_ipairs(self.UnitCommandList) do
			tracy.ZoneBeginN("W:UnitCommand:" .. w.whInfo.name)
			w:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag, playerID, fromSynced, fromLua)
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
	end
else
	function widgetHandler:UnitCommand(unitID, unitDefID, unitTeam, cmdId, cmdParams, cmdOpts, cmdTag) --cmdTag available in Spring 95
		tracy.ZoneBeginN("W:UnitCommand")
		for _, w in r_ipairs(self.UnitCommandList) do
			tracy.ZoneBeginN("W:UnitCommand:" .. w.whInfo.name)
			w:UnitCommand(unitID, unitDefID, unitTeam, cmdId, cmdParams, cmdOpts, cmdTag)
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
	end
end

function widgetHandler:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag) --cmdParams & cmdOptions available in Spring 95
	tracy.ZoneBeginN("W:UnitCmdDone")
	for _, w in r_ipairs(self.UnitCmdDoneList) do
		tracy.ZoneBeginN("W:UnitCmdDone:" .. w.whInfo.name)
		w:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	tracy.ZoneBeginN("W:UnitDamaged")
	local spectating = playerstate[myPlayerID].spectator
	for _, w in r_ipairs(self.UnitDamagedList) do
		tracy.ZoneBeginN("W:UnitDamaged:" .. w.whInfo.name)
		-- The engine only provides attackerID etc if the attacker is visible.
		-- OTOH weaponDefID and projectileID are always provided - elide projectileID so that widgets can't aquire projectile vector and locate the attacker.
		if spectating then
			w:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		else
			w:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, attackerID and weaponDefID, nil, attackerID, attackerDefID, attackerTeam)
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end
function widgetHandler:UnitStunned(unitID, unitDefID, unitTeam, stunned)
	tracy.ZoneBeginN("W:UnitStunned")
	for _, w in r_ipairs(self.UnitStunnedList) do
		tracy.ZoneBeginN("W:UnitStunned:" .. w.whInfo.name)
		w:UnitStunned(unitID, unitDefID, unitTeam, stunned)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitEnteredRadar(unitID, unitTeam, forAllyTeamID, unitDefID)
	tracy.ZoneBeginN("W:UnitEnteredRadar")
	for _, w in r_ipairs(self.UnitEnteredRadarList) do
		tracy.ZoneBeginN("W:UnitEnteredRadar:" .. w.whInfo.name)
		w:UnitEnteredRadar(unitID, unitTeam, forAllyTeamID, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitEnteredLos(unitID, unitTeam, forAllyTeamID, unitDefID)
	tracy.ZoneBeginN("W:UnitEnteredLos")
	for _, w in r_ipairs(self.UnitEnteredLosList) do
		tracy.ZoneBeginN("W:UnitEnteredLos:" .. w.whInfo.name)
		w:UnitEnteredLos(unitID, unitTeam, forAllyTeamID, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitLeftRadar(unitID, unitTeam, forAllyTeamID, unitDefID)
	tracy.ZoneBeginN("W:UnitLeftRadar")
	for _, w in r_ipairs(self.UnitLeftRadarList) do
		tracy.ZoneBeginN("W:UnitLeftRadar:" .. w.whInfo.name)
		w:UnitLeftRadar(unitID, unitTeam, forAllyTeamID, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitLeftLos(unitID, unitTeam, forAllyTeamID, unitDefID)
	tracy.ZoneBeginN("WUnitLeftLos:")
	for _, w in r_ipairs(self.UnitLeftLosList) do
		tracy.ZoneBeginN("W:UnitLeftLos:" .. w.whInfo.name)
		w:UnitLeftLos(unitID, unitTeam, forAllyTeamID, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitEnteredWater(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitEnteredWater")
	for _, w in r_ipairs(self.UnitEnteredWaterList) do
		tracy.ZoneBeginN("W:UnitEnteredWater:" .. w.whInfo.name)
		w:UnitEnteredWater(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitEnteredAir(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitEnteredAir")
	for _, w in r_ipairs(self.UnitEnteredAirList) do
		tracy.ZoneBeginN("W:UnitEnteredAir:" .. w.whInfo.name)
		w:UnitEnteredAir(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitLeftWater(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitLeftWater")
	for _, w in r_ipairs(self.UnitLeftWaterList) do
		tracy.ZoneBeginN("W:UnitLeftWater:" .. w.whInfo.name)
		w:UnitLeftWater(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitLeftAir(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitLeftAir")
	for _, w in r_ipairs(self.UnitLeftAirList) do
		tracy.ZoneBeginN("W:UnitLeftAir:" .. w.whInfo.name)
		w:UnitLeftAir(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitSeismicPing(x, y, z, strength, allyTeamID, unitID, unitDefID)
	tracy.ZoneBeginN("W:UnitSeismicPing")
	for _, w in r_ipairs(self.UnitSeismicPingList) do
		tracy.ZoneBeginN("W:UnitSeismicPing:" .. w.whInfo.name)
		w:UnitSeismicPing(x, y, z, strength, allyTeamID, unitID, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	tracy.ZoneBeginN("W:UnitLoaded")
	for _, w in r_ipairs(self.UnitLoadedList) do
		tracy.ZoneBeginN("W:UnitLoaded:" .. w.whInfo.name)
		w:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	tracy.ZoneBeginN("W:UnitUnloaded")
	for _, w in r_ipairs(self.UnitUnloadedList) do
		tracy.ZoneBeginN("W:UnitUnloaded:" .. w.whInfo.name)
		w:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitCloaked(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitCloaked")
	for _, w in r_ipairs(self.UnitCloakedList) do
		tracy.ZoneBeginN("W:UnitCloaked:" .. w.whInfo.name)
		w:UnitCloaked(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitDecloaked(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitDecloaked")
	for _, w in r_ipairs(self.UnitDecloakedList) do
		tracy.ZoneBeginN("W:UnitDecloaked:" .. w.whInfo.name)
		w:UnitDecloaked(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:UnitMoveFailed(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:UnitMoveFailed")
	for _, w in r_ipairs(self.UnitMoveFailedList) do
		tracy.ZoneBeginN("W:UnitMoveFailed:" .. w.whInfo.name)
		w:UnitMoveFailed(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:RecvLuaMsg(msg, playerID)
	tracy.ZoneBeginN("W:RecvLuaMsg")
	local retval = false
	for _, w in r_ipairs(self.RecvLuaMsgList) do
		tracy.ZoneBeginN("W:RecvLuaMsg:" .. w.whInfo.name)
		if (w:RecvLuaMsg(msg, playerID)) then
			retval = true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return retval  --  FIXME  --  another actionHandler type?
end


function widgetHandler:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
	tracy.ZoneBeginN("W:StockpileChanged")
	for _, w in r_ipairs(self.StockpileChangedList) do
		tracy.ZoneBeginN("W:StockpileChanged:" .. w.whInfo.name)
		w:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:VisibleUnitAdded(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:VisibleUnitAdded")
	for _, w in ipairs(self.VisibleUnitAddedList) do
		tracy.ZoneBeginN("W:VisibleUnitAdded:" .. w.whInfo.name)
		w:VisibleUnitAdded(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:VisibleUnitRemoved(unitID)
	tracy.ZoneBeginN("W:VisibleUnitRemoved")
	for _, w in ipairs(self.VisibleUnitRemovedList) do
		tracy.ZoneBeginN("W:VisibleUnitRemoved:" .. w.whInfo.name)
		w:VisibleUnitRemoved(unitID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:VisibleUnitsChanged(visibleUnits, numVisibleUnits)
	tracy.ZoneBeginN("W:VisibleUnitsChanged")
	for _, w in ipairs(self.VisibleUnitsChangedList) do
		tracy.ZoneBeginN("W:VisibleUnitsChanged:" .. w.whInfo.name)
		w:VisibleUnitsChanged(visibleUnits, numVisibleUnits)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:AlliedUnitAdded(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("W:AlliedUnitAdded")
	for _, w in ipairs(self.AlliedUnitAddedList) do
		tracy.ZoneBeginN("W:AlliedUnitAdded:" .. w.whInfo.name)
		w:AlliedUnitAdded(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:AlliedUnitRemoved(unitID)
	tracy.ZoneBeginN("W:AlliedUnitRemoved")
	for _, w in ipairs(self.AlliedUnitRemovedList) do
		tracy.ZoneBeginN("W:AlliedUnitRemoved:" .. w.whInfo.name)
		w:AlliedUnitRemoved(unitID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:AlliedUnitsChanged(visibleUnits, numVisibleUnits)
	tracy.ZoneBeginN("W:AlliedUnitsChanged")
	for _, w in ipairs(self.AlliedUnitsChangedList) do
		tracy.ZoneBeginN("W:AlliedUnitsChanged:" .. w.whInfo.name)
		w:AlliedUnitsChanged(alliedUnits, numAlliedUnits)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:GameID(gameID)
	tracy.ZoneBeginN("W:GameID")
	for _, w in ipairs(self.GameIDList) do
		tracy.ZoneBeginN("W:GameID:" .. w.whInfo.name)
		w:GameID(gameID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:UnitStructureMoved(unitID, unitDefID, newX, newZ)
	tracy.ZoneBeginN("W:UnitStructureMoved")
	for _, w in r_ipairs(self.UnitStructureMovedList) do
		tracy.ZoneBeginN("W:UnitStructureMoved:" .. w.whInfo.name)
		w:UnitStructureMoved(unitID, unitDefID, newX, newZ)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

--------------------------------------------------------------------------------
--
-- Projectile call-ins
--

function widgetHandler:MissileFired(proID, proOwnerID, weaponDefID, rx, ry, rz, rt, targetID)
	tracy.ZoneBeginN("W:MissileFired")
	for _,w in r_ipairs(self.MissileFiredList) do
		tracy.ZoneBeginN("W:MissileFired:" .. w.whInfo.name)
		w:MissileFired(proID, proOwnerID, weaponDefID, rx, ry, rz, rt, targetID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:MissileDestroyed(proID, proOwnerID, weaponDefID)
	tracy.ZoneBeginN("W:MissileDestroyed")
	for _,w in r_ipairs(self.MissileDestroyedList) do
		tracy.ZoneBeginN("W:MissileDestroyed:" .. w.whInfo.name)
		w:MissileDestroyed(proID, proOwnerID, weaponDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

-- local helper (not a real call-in)
local oldSelection = {}
function widgetHandler:UpdateSelection()
	tracy.ZoneBeginN("W:UpdateSelection")
	local changed
	local newSelection = Spring.GetSelectedUnits()
	if (#newSelection == #oldSelection) then
		for i = 1, #oldSelection do
			if (newSelection[i] ~= oldSelection[i]) then -- it seems the order stays
				changed = true
				break
			end
		end
	else
		changed = true
	end
	if (changed) then
		local subselection = true
		if #newSelection > #oldSelection then
			subselection = false
		else
			local newSeen = 0
			local oldSelectionMap = {}
			for i = 1, #oldSelection do
				oldSelectionMap[oldSelection[i]] = true
			end
			for i = 1, #newSelection do
				if not oldSelectionMap[newSelection[i]] then
					subselection = false
					break
				end
			end
		end
		if widgetHandler:SelectionChanged(newSelection, subselection) then
			-- selection changed, don't set old selection to new selection as it is soon to change.
			tracy.ZoneEnd()
			return true
		end
	end
	oldSelection = newSelection
	tracy.ZoneEnd()
	return false
end


function widgetHandler:SelectionChanged(selectedUnits, subselection)
	tracy.ZoneBeginN("W:SelectionChanged")
	for _, w in r_ipairs(self.SelectionChangedList) do
		tracy.ZoneBeginN("W:SelectionChanged:" .. w.whInfo.name)
		local unitArray = w:SelectionChanged(selectedUnits, subselection)
		tracy.ZoneEnd()
		if (unitArray) then
			Spring.SelectUnitArray(unitArray)
			tracy.ZoneEnd()
			return true
		end
	end
	tracy.ZoneEnd()
	return false
end


function widgetHandler:GameProgress(frame)
	tracy.ZoneBeginN("W:GameProgress")
	for _, w in r_ipairs(self.GameProgressList) do
		tracy.ZoneBeginN("W:GameProgress:" .. w.whInfo.name)
		w:GameProgress(frame)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
	tracy.ZoneBeginN("W:UnsyncedHeightMapUpdate")
	for _, w in r_ipairs(self.UnsyncedHeightMapUpdateList) do
		tracy.ZoneBeginN("W:UnsyncedHeightMapUpdate:" .. w.whInfo.name)
		w:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:Save(zip)
	tracy.ZoneBeginN("W:Save")
	for _, w in r_ipairs(self.SaveList) do
		tracy.ZoneBeginN("W:Save:" .. w.whInfo.name)
		w:Save(zip)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function widgetHandler:Load(zip)
	tracy.ZoneBeginN("W:Load")
	for _, w in r_ipairs(self.LoadList) do
		tracy.ZoneBeginN("W:Load:" .. w.whInfo.name)
		w:Load(zip)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end


function widgetHandler:PreGameTimekeeping(secondsUntilStart)
	tracy.ZoneBeginN("W:PreGameTimekeeping")
	for _,w in r_ipairs(self.PreGameTimekeepingList) do
		tracy.ZoneBeginN("W:PreGameTimekeeping:" .. w.whInfo.name)
		w:PreGameTimekeeping(secondsUntilStart)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

widgetHandler:Initialize()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
