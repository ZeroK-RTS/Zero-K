-- NOTE overrides section at bottom!
-- ALSO look for comments	-- FIXME: not in base

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gadgets.lua
--  brief:   the gadget manager, a call-in router
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  TODO:  - get rid of the ':'/self referencing, it's a waste of cycles
--         - (De)RegisterCOBCallback(data)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local HANDLER_BASENAME = "gadgets.lua"
local isMission = VFS.FileExists("mission.lua")	-- or Game.gameName:find("Scenario Editor")

local HANDLER_DIR = 'LuaGadgets/'
local GADGETS_DIR = Script.GetName():gsub('US$', '') .. '/Gadgets/'
local SCRIPT_DIR = Script.GetName() .. '/'

local ECHO_DESCRIPTIONS = false
local SYNC_MEMORY_DEBUG = false --(gcinfo or false)

local VFSMODE = VFS.ZIP_ONLY
if (Spring.IsDevLuaEnabled()) then
  VFSMODE = VFS.RAW_ONLY
end

VFS.Include('LuaRules/engine_compat.lua',   nil, VFSMODE)
VFS.Include(HANDLER_DIR .. 'setupdefs.lua', nil, VFSMODE)
VFS.Include(HANDLER_DIR .. 'system.lua',    nil, VFSMODE)
VFS.Include(HANDLER_DIR .. 'callins.lua',   nil, VFSMODE)
VFS.Include(SCRIPT_DIR .. 'utilities.lua', nil, VFSMODE)

local actionHandler = VFS.Include(HANDLER_DIR .. 'actions.lua', nil, VFSMODE)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  the gadgetHandler object
--

gadgetHandler = {

	gadgets = {},

	orderList = {},

	knownGadgets = {},
	knownCount = 0,
	knownChanged = true,

	GG = {}, -- shared table for gadgets

	globals = {}, -- global vars/funcs

	CMDIDs = {},

	xViewSize    = 1,
	yViewSize    = 1,
	xViewSizeOld = 1,
	yViewSizeOld = 1,

	mouseOwner = nil,

	actionHandler = actionHandler,	-- FIXME: not in base
}

VFS.Include('LuaRules/engine_compat_post.lua', nil, VFSMODE)

-- these call-ins are set to 'nil' if not used
-- they are setup in UpdateCallIns()
local callInLists = {
	"Shutdown",

	"GamePreload",
	"GameStart",
	"GameOver",
	"GameID",
	"TeamDied",

	"GamePaused",

	"PlayerAdded",
	"PlayerChanged",
	"PlayerRemoved",

	"GameFrame",

	"ViewResize",  -- FIXME ?

	"TextCommand",  -- FIXME ?
	"GotChatMsg",
	"RecvLuaMsg",

	-- Custom from gadgets themselves
	"UnitCreatedByMechanic",
	
	-- Unit CallIns
	"UnitCreated",
	"UnitFinished",
	"UnitReverseBuilt",
	"UnitFromFactory",
	"UnitDestroyed",
	"RenderUnitDestroyed",
	"UnitExperience",
	"UnitIdle",
	"UnitCmdDone",
	"UnitPreDamaged",
	"UnitDamaged",
	"UnitStunned",
	"UnitTaken",
	"UnitGiven",
	"UnitEnteredRadar",
	"UnitEnteredLos",
	"UnitLeftRadar",
	"UnitLeftLos",
	"UnitSeismicPing",
	"UnitLoaded",
	"UnitUnloaded",
	"UnitCloaked",
	"UnitDecloaked",
	-- optional
	-- "UnitUnitCollision",
	-- "UnitFeatureCollision",
	-- "UnitMoveFailed",
	"UnitArrivedAtGoal",
	"StockpileChanged",

	-- Feature CallIns
	"FeatureCreated",
	"FeatureDestroyed",
	--[[ FeatureDamaged and FeaturePreDamaged missing on purpose. Basic damage control
	     can be achieved via armordefs (use the "default" class, make sure to populate
	     the others including "else" explicitly) so this way we avoid the perf cost. ]]

	-- Projectile CallIns
	"ProjectileCreated",
	"ProjectileDestroyed",

	-- Shield CallIns
	"ShieldPreDamaged",

	-- Misc Synced CallIns
	"Explosion",

	-- LUS callins
	"ScriptFireWeapon",
	"ScriptEndBurst",

	-- LuaRules CallIns (note: the *PreDamaged calls belong here too)
	"CommandFallback",
	"AllowCommand",
	"AllowStartPosition",
	"AllowUnitCreation",
	"AllowUnitTransfer",
	"AllowUnitBuildStep",
	"AllowUnitTransport",
	"AllowUnitTransportLoad",
	"AllowUnitTransportUnload",
	"AllowUnitCloak",
	"AllowUnitDecloak",
	"AllowUnitTargetRange",
	"AllowFeatureBuildStep",
	"AllowFeatureCreation",
	"AllowResourceLevel",
	"AllowResourceTransfer",
	"AllowDirectUnitControl",
	"AllowBuilderHoldFire",
	"MoveCtrlNotify",
	"TerraformComplete",
	"AllowWeaponTargetCheck",
	"AllowWeaponTarget",
	"AllowWeaponInterceptTarget",
	-- unsynced
	"DrawUnit",
	"DrawFeature",
	"DrawShield",
	"DrawProjectile",
	"RecvSkirmishAIMessage",

	"SunChanged",

	-- COB CallIn  (FIXME?)
	"CobCallback",

	-- Unsynced CallIns
	"Update",
	"DefaultCommand",
	"DrawGenesis",
	"DrawWorld",
	"DrawWorldPreUnit",
	"DrawWorldShadow",
	"DrawWorldReflection",
	"DrawWorldRefraction",
	"DrawScreenEffects",
	"DrawScreenPost",
	"DrawScreen",
	"DrawInMiniMap",
	'DrawOpaqueUnitsLua',
	'DrawOpaqueFeaturesLua',
	'DrawAlphaUnitsLua',
	'DrawAlphaFeaturesLua',
	'DrawShadowUnitsLua',
	'DrawShadowFeaturesLua',

	"RecvFromSynced",

	-- moved from LuaUI
	"KeyPress",
	"KeyRelease",
	"MousePress",
	"MouseRelease",
	"MouseMove",
	"MouseWheel",
	"IsAbove",
	"GetTooltip",

	-- FIXME -- not implemented  (more of these?)
	"WorldTooltip",
	"MapDrawCmd",
	"GameSetup",
	"DefaultCommand",

	-- FIXME: NOT IN BASE
	"UnitCommand",
	"UnitEnteredWater",
	"UnitEnteredAir",
	"UnitLeftWater",
	"UnitLeftAir",

	"UnsyncedHeightMapUpdate"
}


-- initialize the call-in lists
do
	for _,listname in ipairs(callInLists) do
		gadgetHandler[listname .. 'List'] = {}
	end
end


-- Utility call
local isSyncedCode = (SendToUnsynced ~= nil)
local function IsSyncedCode()
	return isSyncedCode
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  array-table reverse iterator
--
--  all callin handlers use this so that gadgets can
--  RemoveGadget() themselves (during iteration over
--  a callin list) without causing a miscount
--
--  c.f. Array{Insert,Remove}
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


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  returns:  basename, dirname
--

local function Basename(fullpath)
	local _,_,base = string.find(fullpath, "([^\\/:]*)$")
	local _,_,path = string.find(fullpath, "(.*[\\/:])[^\\/:]*$")
	if (path == nil) then path = "" end
	return base, path
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadgetHandler:Initialize()
local unsortedGadgets = {}

-- get the gadget names
local gadgetFiles = VFS.DirList(GADGETS_DIR, "*.lua", VFSMODE)
	--  table.sort(gadgetFiles)

	--  for k,gf in ipairs(gadgetFiles) do
	--    Spring.Echo('gf1 = ' .. gf) -- FIXME
	--  end

	if ECHO_DESCRIPTIONS then
		Spring.Echo("=== Start Gadgets ===")
	end

	-- stuff the gadgets into unsortedGadgets
	local wantYield = Spring.Yield and Spring.Yield()
	for k,gf in ipairs(gadgetFiles) do
		--    Spring.Echo('gf2 = ' .. gf) -- FIXME
		local gadget = self:LoadGadget(gf)
		if (gadget) then
			table.insert(unsortedGadgets, gadget)
		end
		if wantYield then
			Spring.Yield()
		end
	end

	if ECHO_DESCRIPTIONS then
		Spring.Echo("=== End Gadgets ===")
	end

	-- sort the gadgets
	table.sort(unsortedGadgets, function(g1, g2)
		local l1 = g1.ghInfo.layer
		local l2 = g2.ghInfo.layer
		if (l1 ~= l2) then
			return (l1 < l2)
		end
		local n1 = g1.ghInfo.name
		local n2 = g2.ghInfo.name
		local o1 = self.orderList[n1]
		local o2 = self.orderList[n2]
		if (o1 ~= o2) then
			return (o1 < o2)
		else
			return (n1 < n2)
		end
	end)

	-- add the gadgets
	for _,g in ipairs(unsortedGadgets) do
		gadgetHandler:InsertGadget(g)

		local name = g.ghInfo.name
		local basename = g.ghInfo.basename
		print(string.format("Loaded gadget:  %-18s  <%s>", name, basename))
	end
end


function gadgetHandler:LoadGadget(filename)
	local kbytes = 0
	if SYNC_MEMORY_DEBUG then-- only present in special debug builds, otherwise gcinfo is not preset in synced context!
		collectgarbage("collect") -- call it twice, mark
		collectgarbage("collect") -- sweep
		kbytes = gcinfo()
	end
	local basename = Basename(filename)
	local text = VFS.LoadFile(filename, VFSMODE)
	if (text == nil) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. filename)
		return nil
	end
	local chunk, err = loadstring(text, filename)
	if (chunk == nil) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (' .. err .. ')')
		return nil
	end

	local gadget = gadgetHandler:NewGadget()

	setfenv(chunk, gadget)
	local success
	success, err = pcall(chunk)
	if (not success) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (' .. err .. ')')
		return nil
	end
	if (err == false) then -- note that all "normal" gadgets return `nil` implicitly at EOF, so don't do "if not err"
		return nil -- gadget asked for a quiet death
	end

	-- raw access to gadgetHandler
	if (gadget.GetInfo and gadget:GetInfo().script) then
		gadget.scriptCallins = {
			ScriptFireWeapon = function (_, unitID, unitDefID, weaponNum)
				self:ScriptFireWeapon(unitID, unitDefID, weaponNum)
			end,
			ScriptEndBurst = function (_, unitID, unitDefID, weaponNum)
				self:ScriptEndBurst(unitID, unitDefID, weaponNum)
			end,
		}
	end

	-- raw access to gadgetHandler
	if (gadget.GetInfo and gadget:GetInfo().handler) then
		gadget.gadgetHandler = self
	end

	self:FinalizeGadget(gadget, filename, basename)
	local name = gadget.ghInfo.name

	err = self:ValidateGadget(gadget)
	if (err) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (' .. err .. ')')
		return nil
	end

	local knownInfo = self.knownGadgets[name]
	if (knownInfo) then
		if (knownInfo.active) then
			Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (duplicate name)')
		return nil
		end
	else
		-- create a knownInfo table
		knownInfo = {}
		knownInfo.desc     = gadget.ghInfo.desc
		knownInfo.author   = gadget.ghInfo.author
		knownInfo.basename = gadget.ghInfo.basename
		knownInfo.filename = gadget.ghInfo.filename
		self.knownGadgets[name] = knownInfo
		self.knownCount = self.knownCount + 1
		self.knownChanged = true
	end
	knownInfo.active = true

	local info  = gadget.GetInfo and gadget:GetInfo()
	local order = self.orderList[name]
	if (((order ~= nil) and (order > 0)) or ((order == nil) and ((info == nil) or info.enabled))) then
		-- this will be an active gadget
		if (order == nil) then
			self.orderList[name] = 12345  -- back of the pack
		else
			self.orderList[name] = order
		end
	else
		self.orderList[name] = 0
		self.knownGadgets[name].active = false
		return nil
	end

	if info and ECHO_DESCRIPTIONS then
		Spring.Echo(filename, info.name, info.desc)
	end

	if SYNC_MEMORY_DEBUG and kbytes > 0 then
		collectgarbage("collect") -- mark
		collectgarbage("collect") -- sweep
		Spring.Echo("LoadGadget\t" .. filename .. "\t" .. (gcinfo() - kbytes) .. "\t" .. gcinfo() .. "\t" .. (IsSyncedCode() and 1 or 0))
	end
	return gadget
end


function gadgetHandler:NewGadget()
	local gadget = {}
	-- load the system calls into the gadget table
	for k,v in pairs(System) do
		gadget[k] = v
	end
	gadget._G = _G         -- the global table
	gadget.GG = self.GG    -- the shared table
	gadget.gadget = gadget -- easy self referencing

	-- wrapped calls (closures)
	gadget.gadgetHandler = {}
	local gh = gadget.gadgetHandler

	gh.gadgetHandler = self	-- NOT IN BASE (required for api_subdir_gadgets)

	gadget.include  = function (f)
		return VFS.Include(f, gadget, VFSMODE)
	end

	gh.RaiseGadget  = function (_) self:RaiseGadget(gadget)      end
	gh.LowerGadget  = function (_) self:LowerGadget(gadget)      end
	gh.RemoveGadget = function (_) self:RemoveGadget(gadget)     end
	gh.GetViewSizes = function (_) return self:GetViewSizes()    end
	gh.GetHourTimer = function (_) return self:GetHourTimer()    end
	gh.IsSyncedCode = function (_) return IsSyncedCode()         end

	gh.UpdateCallIn = function (_, name)
		self:UpdateGadgetCallIn(name, gadget)
	end
	gh.RemoveCallIn = function (_, name)
		self:RemoveGadgetCallIn(name, gadget)
	end

	gh.RegisterCMDID = function(_, id)
		self:RegisterCMDID(gadget, id)
	end

	gh.RegisterGlobal = function(_, name, value)
		return self:RegisterGlobal(gadget, name, value)
	end
	gh.DeregisterGlobal = function(_, name)
		return self:DeregisterGlobal(gadget, name)
	end
	gh.SetGlobal = function(_, name, value)
		return self:SetGlobal(gadget, name, value)
	end

	gh.AddChatAction = function (_, cmd, func, help)
		return actionHandler.AddChatAction(gadget, cmd, func, help)
	end
	gh.RemoveChatAction = function (_, cmd)
		return actionHandler.RemoveChatAction(gadget, cmd)
	end

	if (not IsSyncedCode()) then
		gh.AddSyncAction = function(_, cmd, func, help)
			return actionHandler.AddSyncAction(gadget, cmd, func, help)
		end
		gh.RemoveSyncAction = function(_, cmd)
			return actionHandler.RemoveSyncAction(gadget, cmd)
		end
	end

	if IsSyncedCode() then
		gh.NotifyUnitCreatedByMechanic = function(_, unitID, parentID, mechanicName, extraData)
			self:UnitCreatedByMechanic(unitID, parentID, mechanicName, extraData)
		end
	end

	-- for proxied call-ins
	gh.IsMouseOwner = function (_)
		return (self.mouseOwner == gadget)
	end
	gh.DisownMouse  = function (_)
		if (self.mouseOwner == gadget) then
			self.mouseOwner = nil
		end
	end

	return gadget
end


function gadgetHandler:FinalizeGadget(gadget, filename, basename)
	local gi = {}

	gi.filename = filename
	gi.basename = basename
	if (gadget.GetInfo == nil) then
		gi.name  = basename
		gi.layer = 0
	else
		local info = gadget:GetInfo()
		gi.name      = info.name    or basename
		gi.layer     = info.layer   or 0
		gi.desc      = info.desc    or ""
		gi.author    = info.author  or ""
		gi.license   = info.license or ""
		gi.enabled   = info.enabled or false
	end

	gadget.ghInfo = {}  --  a proxy table
	local mt = {
		__index = gi,
		__newindex = function() error("ghInfo tables are read-only") end,
		__metatable = "protected"
	}
	setmetatable(gadget.ghInfo, mt)
end


function gadgetHandler:ValidateGadget(gadget)
	if (gadget.GetTooltip and not gadget.IsAbove) then
		return "Gadget has GetTooltip() but not IsAbove()"
	end
	if (gadget.TweakGetTooltip and not gadget.TweakIsAbove) then
		return "Gadget has TweakGetTooltip() but not TweakIsAbove()"
	end
	return nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ArrayInsert(t, f, g)
	if (f) then
		local layer = g.ghInfo.layer
		local index = 1
		for i,v in ipairs(t) do
			if (v == g) then
				return -- already in the table
			end

			-- insert-sort the gadget based on its layer
			-- note: reversed value ordering, highest to lowest
			-- iteration over the callin lists is also reversed
			if (layer < v.ghInfo.layer) then
				index = i + 1
			end
		end
		table.insert(t, index, g)
	end
end


local function ArrayRemove(t, g)
	for k,v in ipairs(t) do
		if (v == g) then
			table.remove(t, k)
			-- break
		end
	end
end


function gadgetHandler:InsertGadget(gadget)
	if (gadget == nil) then
		return
	end

	ArrayInsert(self.gadgets, true, gadget)
	for _,listname in ipairs(callInLists) do
		local func = gadget[listname]
		if (type(func) == 'function') then
			ArrayInsert(self[listname..'List'], func, gadget)
		end
	end

	self:UpdateCallIns()
	if (gadget.Initialize) then
		gadget:Initialize()
	end
	self:UpdateCallIns()
end


function gadgetHandler:RemoveGadget(gadget)
	if (gadget == nil) then
		return
	end

	local name = gadget.ghInfo.name
	self.knownGadgets[name].active = false
	--Spring.Echo(name)
	if (gadget.Shutdown) then
		gadget:Shutdown()
	end

	ArrayRemove(self.gadgets, gadget)
	self:RemoveGadgetGlobals(gadget)
	actionHandler.RemoveGadgetActions(gadget)
	for _,listname in ipairs(callInLists) do
		ArrayRemove(self[listname..'List'], gadget)
	end

	for id,g in pairs(self.CMDIDs) do
		if (g == gadget) then
			self.CMDIDs[id] = nil
		end
	end

	self:UpdateCallIns()
end


--------------------------------------------------------------------------------

function gadgetHandler:UpdateCallIn(name)
	local listName = name .. 'List'
	if ((#self[listName] > 0) or (name == 'GotChatMsg') or (name == 'RecvFromSynced')) then
		local selffunc = self[name]
		_G[name] = function(...)
			return selffunc(self, ...)
		end
	else
		_G[name] = nil
	end
	Script.UpdateCallIn(name)
end


function gadgetHandler:UpdateGadgetCallIn(name, g)
	local listName = name .. 'List'
	local ciList = self[listName]
	if (ciList) then
		local func = g[name]
		if (type(func) == 'function') then
			ArrayInsert(ciList, func, g)
		else
			ArrayRemove(ciList, g)
		end
		self:UpdateCallIn(name)
	else
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'UpdateGadgetCallIn: bad name: ' .. name)
	end
end


function gadgetHandler:RemoveGadgetCallIn(name, g)
	local listName = name .. 'List'
	local ciList = self[listName]
	if (ciList) then
		ArrayRemove(ciList, g)
		self:UpdateCallIn(name)
	else
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'RemoveGadgetCallIn: bad name: ' .. name)
	end
end


function gadgetHandler:UpdateCallIns()
	for _,name in ipairs(callInLists) do
		self:UpdateCallIn(name)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadgetHandler:EnableGadget(name)
	local ki = self.knownGadgets[name]
	if (not ki) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, "EnableGadget(), could not find gadget: " .. tostring(name))
		return false
	end
	if (not ki.active) then
		Spring.Echo('Loading:  '..ki.filename)
	local order = gadgetHandler.orderList[name]
	if (not order or (order <= 0)) then
		self.orderList[name] = 1
	end
	local w = self:LoadGadget(ki.filename)
	if (not w) then return false end
		self:InsertGadget(w)
	end
	return true
end


function gadgetHandler:DisableGadget(name)
	local ki = self.knownGadgets[name]
	if (not ki) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, "DisableGadget(), could not find gadget: " .. tostring(name))
		return false
	end
	if (ki.active) then
		local w = self:FindGadget(name)
		if (not w) then return false end
		Spring.Echo('Removed:  '..ki.filename)
		self:RemoveGadget(w)     -- deactivate
		self.orderList[name] = 0 -- disable
	end
	return true
end


function gadgetHandler:ToggleGadget(name)
	local ki = self.knownGadgets[name]
	if (not ki) then
		Spring.Echo("ToggleGadget(), could not find gadget: " .. tostring(name))
		return
	end
	if (ki.active) then
		return self:DisableGadget(name)
	elseif (self.orderList[name] <= 0) then
		return self:EnableGadget(name)
	else
		-- the gadget is not active, but enabled; disable it
		self.orderList[name] = 0
	end
	return true
end


--------------------------------------------------------------------------------

local function FindGadgetIndex(t, w)
	for k,v in ipairs(t) do
		if (v == w) then
			return k
		end
	end
	return nil
end


local function FindLowestIndex(t, i, layer)
	for x = (i - 1), 1, -1 do
		if (t[x].ghInfo.layer < layer) then
			return x + 1
		end
	end
	return 1
end


function gadgetHandler:RaiseGadget(gadget)
	if (gadget == nil) then
		return
	end
	local function Raise(t, f, w)
		if (f == nil) then return end
		local i = FindGadgetIndex(t, w)
		if (i == nil) then return end
		local n = FindLowestIndex(t, i, w.ghInfo.layer)
		if (n and (n < i)) then
			table.remove(t, i)
			table.insert(t, n, w)
		end
	end
	Raise(self.gadgets, true, gadget)
	for _,listname in ipairs(callInLists) do
		Raise(self[listname..'List'], gadget[listname], gadget)
	end
end


local function FindHighestIndex(t, i, layer)
	local ts = #t
	for x = (i + 1),ts do
		if (t[x].ghInfo.layer > layer) then
			return (x - 1)
		end
	end
	return (ts + 1)
end


function gadgetHandler:LowerGadget(gadget)
	if (gadget == nil) then
		return
	end
	local function Lower(t, f, w)
		if (f == nil) then return end
		local i = FindGadgetIndex(t, w)
		if (i == nil) then return end
		local n = FindHighestIndex(t, i, w.ghInfo.layer)
		if (n and (n > i)) then
			table.insert(t, n, w)
			table.remove(t, i)
		end
	end
	Lower(self.gadgets, true, gadget)
	for _,listname in ipairs(callInLists) do
		Lower(self[listname..'List'], gadget[listname], gadget)
	end
end


function gadgetHandler:FindGadget(name)
	if (type(name) ~= 'string') then
		return nil
	end
	for k,v in ipairs(self.gadgets) do
		if (name == v.ghInfo.name) then
			return v,k
		end
	end
	return nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Global var/func management
--

function gadgetHandler:RegisterGlobal(owner, name, value)
	if ((name == nil) or (_G[name]) or (self.globals[name]) or (CallInsMap and CallInsMap[name]) or (CALLIN_MAP and CALLIN_MAP[name])) then
		return false
	end
	_G[name] = value
	self.globals[name] = owner
	return true
end


function gadgetHandler:DeregisterGlobal(owner, name)
	if (name == nil) then
		return false
	end
	_G[name] = nil
	self.globals[name] = nil
	return true
end


function gadgetHandler:SetGlobal(owner, name, value)
	if ((name == nil) or (self.globals[name] ~= owner)) then
		return false
	end
	_G[name] = value
	return true
end


function gadgetHandler:RemoveGadgetGlobals(owner)
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


function gadgetHandler:GetHourTimer()
	return hourTimer
end

function gadgetHandler:RegisterCMDID(gadget, id)
	if not id then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Gadget (' .. gadget.ghInfo.name .. ') ' ..
			'tried to register a NIL CMD_ID')
	else
		if (id < 1000) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Gadget (' .. gadget.ghInfo.name .. ') ' ..
			'tried to register a reserved CMD_ID')
		Script.Kill('Reserved CMD_ID code: ' .. id)
	end

	if (self.CMDIDs[id] ~= nil) then
		Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Gadget (' .. gadget.ghInfo.name .. ') ' ..
			'tried to register a duplicated CMD_ID')
		Script.Kill('Duplicate CMD_ID code: ' .. id)
	end

	self.CMDIDs[id] = gadget
end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in distribution routines
--

function gadgetHandler:GamePreload()
	tracy.ZoneBeginN("G:GameFrame")
	for _,g in r_ipairs(self.GamePreloadList) do
		tracy.ZoneBeginN("G:GameFrame:" .. g.ghInfo.name)
		g:GamePreload()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:GameStart()
	tracy.ZoneBeginN("G:GameStart")
	for _,g in r_ipairs(self.GameStartList) do
		tracy.ZoneBeginN("G:GameStart:" .. g.ghInfo.name)
		g:GameStart()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:GamePaused(playerID, paused)
	tracy.ZoneBeginN("G:GamePaused")
	for _,g in r_ipairs(self.GamePausedList) do
		tracy.ZoneBeginN("G:GamePaused:" .. g.ghInfo.name)
		g:GamePaused(playerID, paused)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:Shutdown()
	tracy.ZoneBeginN("G:Shutdown")
	Spring.Echo("Start gadgetHandler:Shutdown")
	for _,g in r_ipairs(self.ShutdownList) do
		local name = g.ghInfo.name or "UNKNOWN NAME"
		Spring.Echo("Shutdown - " .. name)
		tracy.ZoneBeginN("G:Shutdown:" .. g.ghInfo.name)
		g:Shutdown()
		tracy.ZoneEnd()
	end
	Spring.Echo("End gadgetHandler:Shutdown")
	tracy.ZoneEnd()
	return
end

function gadgetHandler:GameFrame(frameNum)
	tracy.ZoneBeginN("G:GameFrame")
	for _,g in r_ipairs(self.GameFrameList) do
		tracy.ZoneBeginN("G:GameFrame:" .. g.ghInfo.name)
		g:GameFrame(frameNum)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:RecvLuaMsg(msg, player)
	tracy.ZoneBeginN("G:RecvLuaMsg")
	for _,g in r_ipairs(self.RecvLuaMsgList) do
		tracy.ZoneBeginN("G:RecvLuaMsg:" .. g.ghInfo.name)
		if (g:RecvLuaMsg(msg, player)) then
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
--  Game call-ins
--

function gadgetHandler:GameOver(winners)
	tracy.ZoneBeginN("G:GameOver")
	for _,g in r_ipairs(self.GameOverList) do
		tracy.ZoneBeginN("G:GameOver:" .. g.ghInfo.name)
		g:GameOver(winners)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:GameID(gameID)
	tracy.ZoneBeginN("G:GameID")
	for _,g in r_ipairs(self.GameIDList) do
		tracy.ZoneBeginN("G:GameID:" .. g.ghInfo.name)
		g:GameID(gameID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:TeamDied(teamID)
	tracy.ZoneBeginN("G:TeamDied")
	for _,g in r_ipairs(self.TeamDiedList) do
		tracy.ZoneBeginN("G:TeamDied:" .. g.ghInfo.name)
		g:TeamDied(teamID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:PlayerAdded(playerID)
	tracy.ZoneBeginN("G:PlayerAdded")
	for _,g in r_ipairs(self.PlayerAddedList) do
		tracy.ZoneBeginN("G:PlayerAdded:" .. g.ghInfo.name)
		g:PlayerAdded(playerID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:PlayerChanged(playerID)
	tracy.ZoneBeginN("G:PlayerChanged")
	for _,g in r_ipairs(self.PlayerChangedList) do
		tracy.ZoneBeginN("G:PlayerChanged:" .. g.ghInfo.name)
		g:PlayerChanged(playerID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:PlayerRemoved(playerID, reason)
	tracy.ZoneBeginN("G:PlayerRemoved")
	for _,g in r_ipairs(self.PlayerRemovedList) do
		tracy.ZoneBeginN("G:PlayerRemoved:" .. g.ghInfo.name)
		g:PlayerRemoved(playerID, reason)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


--------------------------------------------------------------------------------
--
--  LuaRules Game call-ins
--

function gadgetHandler:DrawUnit(unitID, drawMode)
	tracy.ZoneBeginN("G:DrawUnit")
	for _,g in r_ipairs(self.DrawUnitList) do
		tracy.ZoneBeginN("G:DrawUnit:" .. g.ghInfo.name)
		if (g:DrawUnit(unitID, drawMode)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function gadgetHandler:DrawFeature(featureID, drawMode)
	tracy.ZoneBeginN("G:DrawFeature")
	for _,g in r_ipairs(self.DrawFeatureList) do
		tracy.ZoneBeginN("G:DrawFeature:" .. g.ghInfo.name)
		if (g:DrawFeature(featureID, drawMode)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function gadgetHandler:DrawShield(unitID, weaponID, drawMode)
	tracy.ZoneBeginN("G:DrawShield")
	for _,g in r_ipairs(self.DrawShieldList) do
		tracy.ZoneBeginN("G:DrawShield:" .. g.ghInfo.name)
		if (g:DrawShield(unitID, weaponID, drawMode)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function gadgetHandler:DrawProjectile(projectileID, drawMode)
	tracy.ZoneBeginN("G:DrawProjectile")
	for _,g in r_ipairs(self.DrawProjectileList) do
		tracy.ZoneBeginN("G:DrawProjectile:" .. g.ghInfo.name)
		if (g:DrawProjectile(projectileID, drawMode)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end

function gadgetHandler:RecvSkirmishAIMessage(aiTeam, dataStr)
	tracy.ZoneBeginN("G:RecvSkirmishAIMessage")
	for _,g in r_ipairs(self.RecvSkirmishAIMessageList) do
		tracy.ZoneBeginN("G:RecvSkirmishAIMessage:" .. g.ghInfo.name)
		local dataRet = g:RecvSkirmishAIMessage(aiTeam, dataStr)
		tracy.ZoneEnd()
		if (dataRet) then
			tracy.ZoneEnd()
			return dataRet
		end
	end
	tracy.ZoneEnd()
end

function gadgetHandler:ScriptFireWeapon(unitID, unitDefID, weaponNum)
	tracy.ZoneBeginN("G:ScriptFireWeapon")
	for _,g in r_ipairs(self.ScriptFireWeaponList) do
		tracy.ZoneBeginN("G:ScriptFireWeapon:" .. g.ghInfo.name)
		g:ScriptFireWeapon(unitID, unitDefID, weaponNum)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function gadgetHandler:ScriptEndBurst(unitID, unitDefID, weaponNum)
	tracy.ZoneBeginN("G:ScriptEndBurst")
	for _,g in r_ipairs(self.ScriptEndBurstList) do
		tracy.ZoneBeginN("G:ScriptEndBurst:" .. g.ghInfo.name)
		g:ScriptEndBurst(unitID, unitDefID, weaponNum)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function gadgetHandler:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
	tracy.ZoneBeginN("G:CommandFallback")
	for _,g in r_ipairs(self.CommandFallbackList) do
		tracy.ZoneBeginN("G:CommandFallback:" .. g.ghInfo.name)
		local used, remove = g:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
		tracy.ZoneEnd()
		if (used) then
			tracy.ZoneEnd()
			return remove
		end
	end
	tracy.ZoneEnd()
	return true  -- remove the command
end

function gadgetHandler:AllowStartPosition(playerID, teamID, readyState, cx, cy, cz, rx, ry, rz)
	tracy.ZoneBeginN("G:AllowStartPosition")
	for _,g in r_ipairs(self.AllowStartPositionList) do
		tracy.ZoneBeginN("G:AllowStartPosition:" .. g.ghInfo.name)
		if (not g:AllowStartPosition(playerID, teamID, readyState, cx, cy, cz, rx, ry, rz)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end

function gadgetHandler:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
	tracy.ZoneBeginN("G:AllowUnitCreation")
	for _,g in r_ipairs(self.AllowUnitCreationList) do
		tracy.ZoneBeginN("G:AllowUnitCreation:" .. g.ghInfo.name)
		local allow, drop = g:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
		tracy.ZoneEnd()
		if not allow then
			tracy.ZoneEnd()
			return false, drop
		end
	end
	tracy.ZoneEnd()
	return true, true
end


function gadgetHandler:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	tracy.ZoneBeginN("G:AllowUnitTransfer")
	for _,g in r_ipairs(self.AllowUnitTransferList) do
		tracy.ZoneBeginN("G:AllowUnitTransfer:" .. g.ghInfo.name)
		if (not g:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end


function gadgetHandler:AllowUnitBuildStep(builderID, builderTeam, unitID, unitDefID, part)
	tracy.ZoneBeginN("G:AllowUnitBuildStep")
	for _,g in r_ipairs(self.AllowUnitBuildStepList) do
		tracy.ZoneBeginN("G:AllowUnitBuildStep:" .. g.ghInfo.name)
		if (not g:AllowUnitBuildStep(builderID, builderTeam, unitID, unitDefID, part)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end

function gadgetHandler:AllowUnitTransport(
	transporterID, transporterUnitDefID, transporterTeam,
	transporteeID, transporteeUnitDefID, transporteeTeam)
	tracy.ZoneBeginN("G:AllowUnitTransport")
	for _,g in r_ipairs(self.AllowUnitTransportList) do
		tracy.ZoneBeginN("G:AllowUnitTransport:" .. g.ghInfo.name)
		if (not g:AllowUnitTransport(
			transporterID, transporterUnitDefID, transporterTeam,
			transporteeID, transporteeUnitDefID, transporteeTeam
		)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end

function gadgetHandler:AllowUnitTransportLoad(
	transporterID, transporterUnitDefID, transporterTeam,
	transporteeID, transporteeUnitDefID, transporteeTeam,
	loadPosX, loadPosY, loadPosZ)
	tracy.ZoneBeginN("G:AllowUnitTransportLoad")
	for _,g in r_ipairs(self.AllowUnitTransportLoadList) do
		tracy.ZoneBeginN("G:AllowUnitTransportLoad:" .. g.ghInfo.name)
		if (not g:AllowUnitTransportLoad(
			transporterID, transporterUnitDefID, transporterTeam,
			transporteeID, transporteeUnitDefID, transporteeTeam,
			loadPosX, loadPosY, loadPosZ
		)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end

function gadgetHandler:AllowUnitTransportUnload(
	transporterID, transporterUnitDefID, transporterTeam,
	transporteeID, transporteeUnitDefID, transporteeTeam,
	unloadPosX, unloadPosY, unloadPosZ)
	tracy.ZoneBeginN("G:AllowUnitTransportUnload")
	for _,g in r_ipairs(self.AllowUnitTransportUnloadList) do
		tracy.ZoneBeginN("G:AllowUnitTransportUnload:" .. g.ghInfo.name)
		if (not g:AllowUnitTransportUnload(
			transporterID, transporterUnitDefID, transporterTeam,
			transporteeID, transporteeUnitDefID, transporteeTeam,
			unloadPosX, unloadPosY, unloadPosZ
		)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
		return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end

function gadgetHandler:AllowUnitCloak(unitID, enemyID)
	tracy.ZoneBeginN("G:AllowUnitCloak")
-- The case can be that unitID == enemyID. This is for engine stunned unitID, they are their own enemies.
	for _,g in r_ipairs(self.AllowUnitCloakList) do
		tracy.ZoneBeginN("G:AllowUnitCloak:" .. g.ghInfo.name)
		if (not g:AllowUnitCloak(unitID, enemyID)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()

	return true
end


function gadgetHandler:AllowUnitDecloak(unitID, objectID, weaponID)
	tracy.ZoneBeginN("G:AllowUnitDecloak")
	for _,g in r_ipairs(self.AllowUnitDecloakList) do
		tracy.ZoneBeginN("G:AllowUnitDecloak:" .. g.ghInfo.name)
		if (not g:AllowUnitDecloak(unitID, objectID, weaponID)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end

	tracy.ZoneEnd()
	return true
end


function gadgetHandler:AllowFeatureBuildStep(builderID, builderTeam,
	featureID, featureDefID, part)
	tracy.ZoneBeginN("G:AllowFeatureBuildStep")
	for _,g in r_ipairs(self.AllowFeatureBuildStepList) do
		tracy.ZoneBeginN("G:AllowFeatureBuildStep:" .. g.ghInfo.name)
		if (not g:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end


function gadgetHandler:AllowFeatureCreation(featureDefID, teamID, x, y, z)
	tracy.ZoneBeginN("G:AllowFeatureCreation")
	for _,g in r_ipairs(self.AllowFeatureCreationList) do
		tracy.ZoneBeginN("G:AllowFeatureCreation:" .. g.ghInfo.name)
		if (not g:AllowFeatureCreation(featureDefID, teamID, x, y, z)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end


function gadgetHandler:AllowResourceLevel(teamID, res, level)
	tracy.ZoneBeginN("G:AllowResourceLevel")
	for _,g in r_ipairs(self.AllowResourceLevelList) do
		tracy.ZoneBeginN("G:AllowResourceLevel:" .. g.ghInfo.name)
		if (not g:AllowResourceLevel(teamID, res, level)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end


function gadgetHandler:AllowResourceTransfer(oldTeamID, newTeamID, res, amount)
	tracy.ZoneBeginN("G:AllowResourceTransfer")
	for _,g in r_ipairs(self.AllowResourceTransferList) do
		tracy.ZoneBeginN("G:AllowResourceTransfer:" .. g.ghInfo.name)
		if (not g:AllowResourceTransfer(oldTeamID, newTeamID, res, amount)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end


function gadgetHandler:AllowDirectUnitControl(unitID, unitDefID, unitTeam, playerID)
	tracy.ZoneBeginN("G:AllowDirectUnitControl")
	for _,g in r_ipairs(self.AllowDirectUnitControlList) do
		tracy.ZoneBeginN("G:AllowDirectUnitControl:" .. g.ghInfo.name)
		if (not g:AllowDirectUnitControl(unitID, unitDefID, unitTeam,
			playerID)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end

function gadgetHandler:AllowBuilderHoldFire(unitID, unitDefID, action)
	tracy.ZoneBeginN("G:AllowBuilderHoldFire")
	for _,g in r_ipairs(self.AllowBuilderHoldFireList) do
		tracy.ZoneBeginN("G:AllowBuilderHoldFire:" .. g.ghInfo.name)
		if (not g:AllowBuilderHoldFire(unitID, unitDefID, action)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end


function gadgetHandler:MoveCtrlNotify(unitID, unitDefID, unitTeam, data)
	tracy.ZoneBeginN("G:MoveCtrlNotify")
	local state = false
	for _,g in r_ipairs(self.MoveCtrlNotifyList) do
		tracy.ZoneBeginN("G:MoveCtrlNotify:" .. g.ghInfo.name)
		if (g:MoveCtrlNotify(unitID, unitDefID, unitTeam, data)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			state = true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return state
end


function gadgetHandler:TerraformComplete(unitID, unitDefID, unitTeam, buildUnitID, buildUnitDefID, buildUnitTeam)
	tracy.ZoneBeginN("G:TerraformComplete")
	for _,g in r_ipairs(self.TerraformCompleteList) do
		tracy.ZoneBeginN("G:TerraformComplete:" .. g.ghInfo.name)
		local stop = g:TerraformComplete(unitID, unitDefID, unitTeam, buildUnitID, buildUnitDefID, buildUnitTeam)
		tracy.ZoneEnd()
		if (stop) then
			tracy.ZoneEnd()
			return true
		end
	end
	tracy.ZoneEnd()
	return false
end


function gadgetHandler:AllowWeaponTargetCheck(attackerID, attackerWeaponNum, attackerWeaponDefID)
	tracy.ZoneBeginN("G:AllowWeaponTargetCheck")
	local ignore = true
	for _, g in r_ipairs(self.AllowWeaponTargetCheckList) do
		tracy.ZoneBeginN("G:AllowWeaponTargetCheck:" .. g.ghInfo.name)
		local allowCheck, ignoreCheck = g:AllowWeaponTargetCheck(attackerID, attackerWeaponNum, attackerWeaponDefID)
		tracy.ZoneEnd()
		if not ignoreCheck then
			ignore = false
			if not allowCheck then
				tracy.ZoneEnd()
				return 0
			end
		end
	end
	tracy.ZoneEnd()

	return ((ignore and -1) or 1)
end

-- AllowWeaponTarget is also called when auto-generating CAI attack commands.
-- When targetID=-1 and weaponNum=-1 targetPriority determines the target search
-- radius; targetPriority=nil accompanies any actual

function gadgetHandler:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	tracy.ZoneBeginN("G:AllowWeaponTarget")
	local allowed = true
	local returnValue

	if targetID == -1 then
		local unitID = attackerID
		local aquireRange = defPriority
		for _, g in r_ipairs(self.AllowUnitTargetRangeList) do
			-- Send priority to each successive gadget.
			tracy.ZoneBeginN("G:AllowUnitTargetRange:" .. g.ghInfo.name)
			local targetAllowed, newRange = g:AllowUnitTargetRange(unitID, aquireRange)
			tracy.ZoneEnd()

			if (not targetAllowed) then
				allowed = false
				break
			end

			aquireRange = newRange
		end
		tracy.ZoneEnd()
		return true, aquireRange
	end

	local priority = defPriority
	for _, g in r_ipairs(self.AllowWeaponTargetList) do
		-- Send priority to each successive gadget.
		tracy.ZoneBeginN("G:AllowWeaponTarget:" .. g.ghInfo.name)
		local targetAllowed, targetPriority = g:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, priority)
		tracy.ZoneEnd()

		if (not targetAllowed) then
			allowed = false
			break
		end

		priority = targetPriority
	end
	tracy.ZoneEnd()
	return allowed, priority
end

function gadgetHandler:AllowWeaponInterceptTarget(interceptorUnitID, interceptorWeaponNum, targetProjectileID)
	tracy.ZoneBeginN("G:AllowWeaponInterceptTarget")
	for _, g in r_ipairs(self.AllowWeaponInterceptTargetList) do
		tracy.ZoneBeginN("G:AllowWeaponInterceptTarget:" .. g.ghInfo.name)
		if (not g:AllowWeaponInterceptTarget(interceptorUnitID, interceptorWeaponNum, targetProjectileID)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()

	return true
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function gadgetHandler:UnitCreatedByMechanic(unitID, parentID, mechanicName, extraData)
	tracy.ZoneBeginN("G:UnitCreatedByMechanic")
	for _,g in r_ipairs(self.UnitCreatedByMechanicList) do
		tracy.ZoneBeginN("G:UnitCreatedByMechanic:" .. g.ghInfo.name)
		g:UnitCreatedByMechanic(unitID, parentID, mechanicName, extraData)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

local inCreated = false
local finishedDuringCreated = false -- assumes non-recursive create
function gadgetHandler:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	tracy.ZoneBeginN("G:UnitCreated")

	finishedDuringCreated = false
	inCreated = true
	for _,g in r_ipairs(self.UnitCreatedList) do
		tracy.ZoneBeginN("G:UnitCreated:" .. g.ghInfo.name)
		g:UnitCreated(unitID, unitDefID, unitTeam, builderID)
		tracy.ZoneEnd()
	end
	inCreated = false

	if finishedDuringCreated then
		finishedDuringCreated = false
		gadgetHandler:UnitFinished(unitID, unitDefID, unitTeam)
	end
	tracy.ZoneEnd()
end

function gadgetHandler:UnitFinished(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitFinished")
	if inCreated then
		finishedDuringCreated = true
		tracy.ZoneEnd()
		return
	end

	for _,g in r_ipairs(self.UnitFinishedList) do
		tracy.ZoneBeginN("G:UnitFinished:" .. g.ghInfo.name)
		g:UnitFinished(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:UnitReverseBuilt(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitReverseBuilt")
	for _,g in r_ipairs(self.UnitReverseBuiltList) do
		tracy.ZoneBeginN("G:UnitReverseBuilt:" .. g.ghInfo.name)
		g:UnitReverseBuilt(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:UnitStunned(unitID, unitDefID, unitTeam, stunned)
	tracy.ZoneBeginN("G:UnitStunned")
	for _,g in r_ipairs(self.UnitStunnedList) do
		tracy.ZoneBeginN("G:UnitStunned:" .. g.ghInfo.name)
		g:UnitStunned(unitID, unitDefID, unitTeam, stunned)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	tracy.ZoneBeginN("G:UnitFromFactory")
	for _,g in r_ipairs(self.UnitFromFactoryList) do
		tracy.ZoneBeginN("G:UnitFromFactory:" .. g.ghInfo.name)
		g:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam, weaponDefID)
	tracy.ZoneBeginN("G:UnitDestroyed")
	if gadgetHandler.GG._AddUnitDamage_teamID then
		attackerTeam = gadgetHandler.GG._AddUnitDamage_teamID
	end
	for _,g in r_ipairs(self.UnitDestroyedList) do
		tracy.ZoneBeginN("G:UnitDestroyed:" .. g.ghInfo.name)
		g:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam, weaponDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:RenderUnitDestroyed")
	for _,g in r_ipairs(self.RenderUnitDestroyedList) do
		tracy.ZoneBeginN("G:RenderUnitDestroyed:" .. g.ghInfo.name)
		g:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitExperience(unitID, unitDefID, unitTeam, experience, oldExperience)
	tracy.ZoneBeginN("G:UnitExperience")
	for _,g in r_ipairs(self.UnitExperienceList) do
		tracy.ZoneBeginN("G:UnitExperience:" .. g.ghInfo.name)
		g:UnitExperience(unitID, unitDefID, unitTeam, experience, oldExperience)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitIdle(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitIdle")
	for _,g in r_ipairs(self.UnitIdleList) do
		tracy.ZoneBeginN("G:UnitIdle:" .. g.ghInfo.name)
		g:UnitIdle(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
	tracy.ZoneBeginN("G:UnitCmdDone")
	for _,g in r_ipairs(self.UnitCmdDoneList) do
		tracy.ZoneBeginN("G:UnitCmdDone:" .. g.ghInfo.name)
		g:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

local UnitPreDamaged_GadgetMap = {}
local UnitPreDamaged_first = true
local allWeaponDefs = {}

do
	for i=-7,#WeaponDefs do
		allWeaponDefs[#allWeaponDefs+1] = i
	end
end

function gadgetHandler:UnitPreDamaged(unitID, unitDefID, unitTeam,
	damage, paralyzer, weaponDefID,
	projectileID, attackerID, attackerDefID, attackerTeam)
	tracy.ZoneBeginN("G:UnitPreDamaged")

	if UnitPreDamaged_first then
		for _,g in r_ipairs(self.UnitPreDamagedList) do
			tracy.ZoneBeginN("G:UnitPreDamaged_GetWantedWeaponDef :" .. g.ghInfo.name)
			local weaponDefs = (g.UnitPreDamaged_GetWantedWeaponDef and g:UnitPreDamaged_GetWantedWeaponDef()) or allWeaponDefs
			tracy.ZoneEnd()
			for _,wdid in ipairs(weaponDefs) do
				if UnitPreDamaged_GadgetMap[wdid] then
					UnitPreDamaged_GadgetMap[wdid].count = UnitPreDamaged_GadgetMap[wdid].count + 1
					UnitPreDamaged_GadgetMap[wdid].data[UnitPreDamaged_GadgetMap[wdid].count] = g
				else
					UnitPreDamaged_GadgetMap[wdid] = {
						count = 1,
						data = {g}
					}
				end
			end
		end
		UnitPreDamaged_first = false
	end

	local rDam = damage
	local rImp = 1.0

	local gadgets = UnitPreDamaged_GadgetMap[weaponDefID]
	if gadgets then
		if gadgetHandler.GG._AddUnitDamage_teamID then
			attackerTeam = gadgetHandler.GG._AddUnitDamage_teamID
		end
		local data = gadgets.data
		local g
		for i = 1, gadgets.count do
			g = data[i]
			tracy.ZoneBeginN("G:UnitPreDamaged:" .. g.ghInfo.name)
			local dam, imp = g:UnitPreDamaged(unitID, unitDefID, unitTeam,
				rDam, paralyzer, weaponDefID,
				attackerID, attackerDefID, attackerTeam,
				projectileID)
			tracy.ZoneEnd()
			if (dam ~= nil) then
				rDam = dam
			end
			if (imp ~= nil) then
				rImp = math.min(imp, rImp)
			end
		end
	end

	tracy.ZoneEnd()
	return rDam, rImp
end


local UnitDamaged_first = true
local UnitDamaged_count = 0
local UnitDamaged_gadgets = {}

function gadgetHandler:UnitDamaged(unitID, unitDefID, unitTeam,
	damage, paralyzer, weaponID, projectileID,
	attackerID, attackerDefID, attackerTeam)
	tracy.ZoneBeginN("G:UnitDamaged")

	if UnitDamaged_first then
		for _,g in r_ipairs(self.UnitDamagedList) do
			UnitDamaged_count = UnitDamaged_count + 1
			UnitDamaged_gadgets[UnitDamaged_count] = g
		end
		UnitDamaged_first = false
	end

	if gadgetHandler.GG._AddUnitDamage_teamID then
		attackerTeam = gadgetHandler.GG._AddUnitDamage_teamID
	end

	local g
	for i = 1, UnitDamaged_count do
		g = UnitDamaged_gadgets[i]
		tracy.ZoneBeginN("G:UnitDamaged:" .. g.ghInfo.name)
		g:UnitDamaged(unitID, unitDefID, unitTeam,
		damage, paralyzer, weaponID,
		attackerID, attackerDefID, attackerTeam, projectileID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	tracy.ZoneBeginN("G:UnitTaken")
	for _,g in r_ipairs(self.UnitTakenList) do
		tracy.ZoneBeginN("G:UnitTaken:" .. g.ghInfo.name)
		g:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	tracy.ZoneBeginN("G:UnitGiven")
	for _,g in r_ipairs(self.UnitGivenList) do
		tracy.ZoneBeginN("G:UnitGiven:" .. g.ghInfo.name)
		g:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitEnteredRadar(unitID, unitTeam, allyTeam, unitDefID)
	tracy.ZoneBeginN("G:UnitEnteredRadar")
	for _,g in r_ipairs(self.UnitEnteredRadarList) do
		tracy.ZoneBeginN("G:UnitEnteredRadar:" .. g.ghInfo.name)
		g:UnitEnteredRadar(unitID, unitTeam, allyTeam, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	tracy.ZoneBeginN("G:UnitEnteredLos")
	for _,g in r_ipairs(self.UnitEnteredLosList) do
		tracy.ZoneBeginN("G:UnitEnteredLos:" .. g.ghInfo.name)
		g:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitLeftRadar(unitID, unitTeam, allyTeam, unitDefID)
	tracy.ZoneBeginN("G:UnitLeftRadar")
	for _,g in r_ipairs(self.UnitLeftRadarList) do
		tracy.ZoneBeginN("G:UnitLeftRadar:" .. g.ghInfo.name)
		g:UnitLeftRadar(unitID, unitTeam, allyTeam, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
	tracy.ZoneBeginN("G:UnitLeftLos")
	for _,g in r_ipairs(self.UnitLeftLosList) do
		tracy.ZoneBeginN("G:UnitLeftLos:" .. g.ghInfo.name)
		g:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitSeismicPing(x, y, z, strength,
	allyTeam, unitID, unitDefID)
	tracy.ZoneBeginN("G:UnitSeismicPing")
	for _,g in r_ipairs(self.UnitSeismicPingList) do
		tracy.ZoneBeginN("G:UnitSeismicPing:" .. g.ghInfo.name)
		g:UnitSeismicPing(x, y, z, strength, allyTeam, unitID, unitDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	tracy.ZoneBeginN("G:UnitLoaded")
	for _,g in r_ipairs(self.UnitLoadedList) do
		tracy.ZoneBeginN("G:UnitLoaded:" .. g.ghInfo.name)
		g:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	tracy.ZoneBeginN("G:UnitUnloaded")
	for _,g in r_ipairs(self.UnitUnloadedList) do
		tracy.ZoneBeginN("G:UnitUnloaded:" .. g.ghInfo.name)
		g:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitCloaked(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitCloaked")
	for _,g in r_ipairs(self.UnitCloakedList) do
		tracy.ZoneBeginN("G:UnitCloaked:" .. g.ghInfo.name)
		g:UnitCloaked(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitDecloaked(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitDecloaked")
	for _,g in r_ipairs(self.UnitDecloakedList) do
		tracy.ZoneBeginN("G:UnitDecloaked:" .. g.ghInfo.name)
		g:UnitDecloaked(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitUnitCollision(colliderID, collideeID)
	tracy.ZoneBeginN("G:UnitUnitCollision")
	for _,g in r_ipairs(self.UnitUnitCollisionList) do
		tracy.ZoneBeginN("G:UnitUnitCollision:" .. g.ghInfo.name)
		g:UnitUnitCollision(colliderID, collideeID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function gadgetHandler:UnitFeatureCollision(colliderID, collideeID)
	tracy.ZoneBeginN("G:UnitArrivedAtGoal")
	for _,g in r_ipairs(self.UnitFeatureCollisionList) do
		tracy.ZoneBeginN("G:UnitArrivedAtGoal:" .. g.ghInfo.name)
		g:UnitFeatureCollision(colliderID, collideeID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function gadgetHandler:UnitArrivedAtGoal(unitID, unitDefID, teamID)
	tracy.ZoneBeginN("G:UnitArrivedAtGoal")
	for _,g in r_ipairs(self.UnitArrivedAtGoalList) do
		tracy.ZoneBeginN("G:UnitArrivedAtGoal:" .. g.ghInfo.name)
		g:UnitArrivedAtGoal(unitID, unitDefID, teamID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
end

function gadgetHandler:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
	tracy.ZoneBeginN("G:StockpileChanged")
	for _,g in r_ipairs(self.StockpileChangedList) do
		tracy.ZoneBeginN("G:StockpileChanged:" .. g.ghInfo.name)
		g:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


--------------------------------------------------------------------------------
--
--  Feature call-ins
--

function gadgetHandler:FeatureCreated(featureID, allyTeam)
	tracy.ZoneBeginN("G:FeatureCreated")
	for _,g in r_ipairs(self.FeatureCreatedList) do
		tracy.ZoneBeginN("G:FeatureCreated:" .. g.ghInfo.name)
		g:FeatureCreated(featureID, allyTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:FeatureDestroyed(featureID, allyTeam)
	tracy.ZoneBeginN("G:FeatureDestroyed")
	for _,g in r_ipairs(self.FeatureDestroyedList) do
		tracy.ZoneBeginN("G:FeatureDestroyed:" .. g.ghInfo.name)
		g:FeatureDestroyed(featureID, allyTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


--------------------------------------------------------------------------------
--
--  Projectile call-ins
--

function gadgetHandler:ProjectileCreated(proID, proOwnerID, proWeaponDefID)
	tracy.ZoneBeginN("G:ProjectileCreated")
	for _,g in r_ipairs(self.ProjectileCreatedList) do
		tracy.ZoneBeginN("G:ProjectileCreated:" .. g.ghInfo.name)
		g:ProjectileCreated(proID, proOwnerID, proWeaponDefID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:ProjectileDestroyed(proID)
	tracy.ZoneBeginN("G:ProjectileDestroyed")
	for _,g in r_ipairs(self.ProjectileDestroyedList) do
		tracy.ZoneBeginN("G:ProjectileDestroyed:" .. g.ghInfo.name)
		g:ProjectileDestroyed(proID)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


--------------------------------------------------------------------------------
--
--  Shield call-ins
--

function gadgetHandler:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID, startX, startY, startZ, hitX, hitY, hitZ)
	tracy.ZoneBeginN("G:ShieldPreDamaged")

	for _,g in r_ipairs(self.ShieldPreDamagedList) do
		-- first gadget to handle this consumes the event
		tracy.ZoneBeginN("G:ShieldPreDamaged:" .. g.ghInfo.name)
		if (g:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID, startX, startY, startZ, hitX, hitY, hitZ)) then
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
--  Misc call-ins
--

local Explosion_GadgetMap = {}
local Explosion_GadgetSingle = {}

local Explosion_first = true

function gadgetHandler:Explosion(weaponID, px, py, pz, ownerID, proID)
	tracy.ZoneBeginN("G:Explosion")
	if Explosion_first then
		for _,g in r_ipairs(self.ExplosionList) do
			tracy.ZoneBeginN("G:Explosion_GetWantedWeaponDef:" .. g.ghInfo.name)
			local weaponDefs = (g.Explosion_GetWantedWeaponDef and g:Explosion_GetWantedWeaponDef()) or allWeaponDefs
			tracy.ZoneEnd()
			for _,wdid in ipairs(weaponDefs) do
				if Explosion_GadgetSingle[wdid] or Explosion_GadgetMap[wdid] then
					if Explosion_GadgetMap[wdid] then
						Explosion_GadgetMap[wdid].count = Explosion_GadgetMap[wdid].count + 1
						Explosion_GadgetMap[wdid].data[Explosion_GadgetMap[wdid].count] = g
					else
						Explosion_GadgetMap[wdid] = {
							count = 2,
							data = {Explosion_GadgetSingle[wdid], g}
						}
						Explosion_GadgetSingle[wdid] = nil
					end
				else
					Explosion_GadgetSingle[wdid] = g
				end
			end
		end
		Explosion_first = false
	end

	local noGfx = false
	local single = Explosion_GadgetSingle[weaponID]
	local map = Explosion_GadgetMap[weaponID]
	if single then
		noGfx = single:Explosion(weaponID, px, py, pz, ownerID, proID)
	elseif map then
		local gadgets = map
		local data = gadgets.data
		local g
		for i = 1, gadgets.count do
			g = data[i]
			tracy.ZoneBeginN("G::" .. g.ghInfo.name)
			noGfx = noGfx or g:Explosion(weaponID, px, py, pz, ownerID, proID)
			tracy.ZoneEnd()
		end
	end
	tracy.ZoneEnd()
	return noGfx or false
end

--------------------------------------------------------------------------------
--
--  Draw call-ins
--

function gadgetHandler:SunChanged()
	tracy.ZoneBeginN("G:SunChanged")
	for _,g in r_ipairs(self.SunChangedList) do
		tracy.ZoneBeginN("G:SunChanged:" .. g.ghInfo.name)
		g:SunChanged()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:Update(deltaTime)
	tracy.ZoneBeginN("G:Update")
	for _,g in r_ipairs(self.UpdateList) do
		tracy.ZoneBeginN("G:Update:" .. g.ghInfo.name)
		g:Update(deltaTime)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DefaultCommand(type, id, engineCmd)
	tracy.ZoneBeginN("G:DefaultCommand")
	for _,g in r_ipairs(self.DefaultCommandList) do
		tracy.ZoneBeginN("G:DefaultCommand:" .. g.ghInfo.name)
		local defCmd = g:DefaultCommand(type, id, engineCmd)
		tracy.ZoneEnd()
		if defCmd then
			tracy.ZoneEnd()
			return defCmd
		end
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawGenesis()
	tracy.ZoneBeginN("G:DrawGenesis")
	for _,g in r_ipairs(self.DrawGenesisList) do
		tracy.ZoneBeginN("G:DrawGenesis:" .. g.ghInfo.name)
		g:DrawGenesis()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawWorld()
	tracy.ZoneBeginN("G:DrawWorld")
	for _,g in r_ipairs(self.DrawWorldList) do
		tracy.ZoneBeginN("G:DrawWorld:" .. g.ghInfo.name)
		g:DrawWorld()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawWorldPreUnit()
	tracy.ZoneBeginN("G:DrawWorldPreUnit")
	for _,g in r_ipairs(self.DrawWorldPreUnitList) do
		tracy.ZoneBeginN("G:DrawWorldPreUnit:" .. g.ghInfo.name)
		g:DrawWorldPreUnit()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawWorldShadow()
	tracy.ZoneBeginN("G:DrawWorldShadow")
	for _,g in r_ipairs(self.DrawWorldShadowList) do
		tracy.ZoneBeginN("G:DrawWorldShadow:" .. g.ghInfo.name)
		g:DrawWorldShadow()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawWorldReflection()
	tracy.ZoneBeginN("G:DrawWorldReflection")
	for _,g in r_ipairs(self.DrawWorldReflectionList) do
		tracy.ZoneBeginN("G:DrawWorldReflection:" .. g.ghInfo.name)
		g:DrawWorldReflection()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
return
end


function gadgetHandler:DrawWorldRefraction()
	tracy.ZoneBeginN("G:DrawWorldRefraction")
	for _,g in r_ipairs(self.DrawWorldRefractionList) do
		tracy.ZoneBeginN("G:DrawWorldRefraction:" .. g.ghInfo.name)
		g:DrawWorldRefraction()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawScreenEffects(vsx, vsy)
	tracy.ZoneBeginN("G:DrawScreenEffects")
	for _,g in r_ipairs(self.DrawScreenEffectsList) do
		tracy.ZoneBeginN("G:DrawScreenEffects:" .. g.ghInfo.name)
		g:DrawScreenEffects(vsx, vsy)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:DrawScreenPost(vsx, vsy)
	tracy.ZoneBeginN("G:DrawScreenPost")
	for _,g in r_ipairs(self.DrawScreenPostList) do
		tracy.ZoneBeginN("G:DrawScreenPost:" .. g.ghInfo.name)
		g:DrawScreenPost(vsx, vsy)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawScreen(vsx, vsy)
	tracy.ZoneBeginN("G:DrawScreen")
	for _,g in r_ipairs(self.DrawScreenList) do
		tracy.ZoneBeginN("G:DrawScreen:" .. g.ghInfo.name)
		g:DrawScreen(vsx, vsy)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:DrawInMiniMap(mmsx, mmsy)
	tracy.ZoneBeginN("G:DrawInMiniMap")
	for _,g in r_ipairs(self.DrawInMiniMapList) do
		tracy.ZoneBeginN("G:DrawInMiniMap:" .. g.ghInfo.name)
		g:DrawInMiniMap(mmsx, mmsy)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:DrawOpaqueUnitsLua(deferredPass, drawReflection, drawRefraction)
	tracy.ZoneBeginN("G:DrawOpaqueUnitsLua")
	for _, g in r_ipairs(self.DrawOpaqueUnitsLuaList) do
		tracy.ZoneBeginN("G:DrawOpaqueUnitsLua:" .. g.ghInfo.name)
		g:DrawOpaqueUnitsLua(deferredPass, drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:DrawOpaqueFeaturesLua(deferredPass, drawReflection, drawRefraction)
	tracy.ZoneBeginN("G:DrawOpaqueFeaturesLua")
	for _, g in r_ipairs(self.DrawOpaqueFeaturesLuaList) do
		tracy.ZoneBeginN("G:DrawOpaqueFeaturesLua:" .. g.ghInfo.name)
		g:DrawOpaqueFeaturesLua(deferredPass, drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:DrawAlphaUnitsLua(drawReflection, drawRefraction)
	tracy.ZoneBeginN("G:DrawAlphaUnitsLua")
	for _, g in r_ipairs(self.DrawAlphaUnitsLuaList) do
		tracy.ZoneBeginN("G:DrawAlphaUnitsLua:" .. g.ghInfo.name)
		g:DrawAlphaUnitsLua(drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:DrawAlphaFeaturesLua(drawReflection, drawRefraction)
	tracy.ZoneBeginN("G:DrawAlphaFeaturesLua")
	for _, g in r_ipairs(self.DrawAlphaFeaturesLuaList) do
		tracy.ZoneBeginN("G:DrawAlphaFeaturesLua:" .. g.ghInfo.name)
		g:DrawAlphaFeaturesLua(drawReflection, drawRefraction)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:DrawShadowUnitsLua()
	tracy.ZoneBeginN("G:DrawShadowUnitsLua")
	for _, g in r_ipairs(self.DrawShadowUnitsLuaList) do
		tracy.ZoneBeginN("G:DrawShadowUnitsLua:" .. g.ghInfo.name)
		g:DrawShadowUnitsLua()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:DrawShadowFeaturesLua()
	tracy.ZoneBeginN("G:DrawShadowFeaturesLua")
	for _, g in r_ipairs(self.DrawShadowFeaturesLuaList) do
		tracy.ZoneBeginN("G:DrawShadowFeaturesLua:" .. g.ghInfo.name)
		g:DrawShadowFeaturesLua()
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadgetHandler:KeyPress(key, mods, isRepeat, label, unicode, scanCode)
	tracy.ZoneBeginN("G:KeyPress")
	for _,g in r_ipairs(self.KeyPressList) do
		tracy.ZoneBeginN("G:KeyPress:" .. g.ghInfo.name)
		if (g:KeyPress(key, mods, isRepeat, label, unicode, scanCode)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end


function gadgetHandler:KeyRelease(key, mods, label, unicode, scanCode)
	tracy.ZoneBeginN("G:KeyRelease")
	for _,g in r_ipairs(self.KeyReleaseList) do
		tracy.ZoneBeginN("G:KeyRelease:" .. g.ghInfo.name)
		if (g:KeyRelease(key, mods, label, unicode, scanCode)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
return false
end


function gadgetHandler:MousePress(x, y, button)
	tracy.ZoneBeginN("G:MousePress")
	local mo = self.mouseOwner
	if (mo) then
		mo:MousePress(x, y, button)
		tracy.ZoneEnd()
		return true  --  already have an active press
	end
	for _,g in r_ipairs(self.MousePressList) do
		tracy.ZoneBeginN("G:MousePress:" .. g.ghInfo.name)
		if (g:MousePress(x, y, button)) then
			self.mouseOwner = g
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end


function gadgetHandler:MouseMove(x, y, dx, dy, button)
	tracy.ZoneBeginN("G:MouseMove")
	local mo = self.mouseOwner
	if (mo and mo.MouseMove) then
		tracy.ZoneEnd()
		return mo:MouseMove(x, y, dx, dy, button)
	end
	tracy.ZoneEnd()
end


function gadgetHandler:MouseRelease(x, y, button)
	tracy.ZoneBeginN("G:MouseRelease")
	local mo = self.mouseOwner
	local mx, my, lmb, mmb, rmb = Spring.GetMouseState()
	if (not (lmb or mmb or rmb)) then
		self.mouseOwner = nil
	end
	if (mo and mo.MouseRelease) then
		tracy.ZoneEnd()
		return mo:MouseRelease(x, y, button)
	end
	tracy.ZoneEnd()
	return -1
end


function gadgetHandler:MouseWheel(up, value)
	tracy.ZoneBeginN("G:MouseWheel")
	for _,g in r_ipairs(self.MouseWheelList) do
		tracy.ZoneBeginN("G:MouseWheel:" .. g.ghInfo.name)
		if (g:MouseWheel(up, value)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end


function gadgetHandler:IsAbove(x, y)
	tracy.ZoneBeginN("G:IsAbove")
	for _,g in r_ipairs(self.IsAboveList) do
		tracy.ZoneBeginN("G:IsAbove:" .. g.ghInfo.name)
		if (g:IsAbove(x, y)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return false
end


function gadgetHandler:GetTooltip(x, y)
	tracy.ZoneBeginN("G:GetTooltip")
	for _,g in r_ipairs(self.GetTooltipList) do
		tracy.ZoneBeginN("G:IsAbove:" .. g.ghInfo.name)
		if (g:IsAbove(x, y)) then
			tracy.ZoneEnd()
			tracy.ZoneBeginN("G:GetTooltip:" .. g.ghInfo.name)
			local tip = g:GetTooltip(x, y)
			tracy.ZoneEnd()
			if (string.len(tip) > 0) then
				tracy.ZoneEnd()
				return tip
			end
		else
			tracy.ZoneEnd()
		end
	end
	tracy.ZoneEnd()
	return ''
end


function gadgetHandler:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
	tracy.ZoneBeginN("G:UnsyncedHeightMapUpdate")
	for _,g in r_ipairs(self.UnsyncedHeightMapUpdateList) do
		tracy.ZoneBeginN("G:UnsyncedHeightMapUpdate:" .. g.ghInfo.name)
		g:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- OVERRIDES
--

function gadgetHandler:GetViewSizes()
--FIXME remove
return gl.GetViewSizes()	-- ours
--return self.xViewSize, self.yViewSize	-- base
end

local AllowCommand_WantedCommand = {}
local AllowCommand_WantedUnitDefID = {}


local SIZE_LIMIT = 10^8
local function AllowCommandParams(cmdParams, playerID)
	for i = 1, #cmdParams do
	-- NaN has the property that NaN ~= NaN
		if (not cmdParams[i]) or cmdParams[i] ~= cmdParams[i] or cmdParams[i] < -SIZE_LIMIT or cmdParams[i] > SIZE_LIMIT then
			Spring.Echo("Bad command from", (playerID and Spring.GetPlayerInfo(playerID)) or "unknown")
			return false
		end
	end
	return true
end

function gadgetHandler:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua)
	tracy.ZoneBeginN("G:AllowCommand")
	if not AllowCommandParams(cmdParams, playerID) then
		return false
	end

	if not Script.IsEngineMinVersion(104, 0, 1431) then
		fromSynced = playerID
		playerID = nil
	end

	for _,g in r_ipairs(self.AllowCommandList) do
		if not AllowCommand_WantedCommand[g] then
			tracy.ZoneBeginN("G:AllowCommand_WantedCommand:" .. g.ghInfo.name)
			AllowCommand_WantedCommand[g] = (g.AllowCommand_GetWantedCommand and g:AllowCommand_GetWantedCommand()) or true
			tracy.ZoneEnd()
		end
		if not AllowCommand_WantedUnitDefID[g] then
			tracy.ZoneBeginN("G:AllowCommand_WantedUnitDefID:" .. g.ghInfo.name)
			AllowCommand_WantedUnitDefID[g] = (g.AllowCommand_GetWantedUnitDefID and g:AllowCommand_GetWantedUnitDefID()) or true
			tracy.ZoneEnd()
		end
		local wantedCommand = AllowCommand_WantedCommand[g]
		local wantedUnitDefID = AllowCommand_WantedUnitDefID[g]

		tracy.ZoneBeginN("G:AllowCommand:" .. g.ghInfo.name)
		if ((wantedCommand == true) or wantedCommand[cmdID]) and
			((wantedUnitDefID == true) or wantedUnitDefID[unitDefID]) and
			(not g:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return false
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return true
end

-- ours
function gadgetHandler:RecvFromSynced(cmd,...)
	tracy.ZoneBeginN("G:RecvFromSynced")
	if (cmd == "proxy_ChatMsg") then
		gadgetHandler:GotChatMsg(...)
		tracy.ZoneEnd()
		return
	end

	if (actionHandler.RecvFromSynced(cmd, ...)) then
		tracy.ZoneEnd()
		return
	end
	for _,g in r_ipairs(self.RecvFromSyncedList) do
		tracy.ZoneBeginN("G:RecvFromSynced:" .. g.ghInfo.name)
		if (g:RecvFromSynced(cmd, ...)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return
		end
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:GotChatMsg(msg, player)
	tracy.ZoneBeginN("G:GotChatMsg")

	if (((player == 0) or (player == 255)) and Spring.IsCheatingEnabled()) then	-- ours
		--if ((player == 0) and Spring.IsCheatingEnabled()) then		-- base
		local sp = '^%s*'    -- start pattern
		local ep = '%s+(.*)' -- end pattern
		local s, e, match
		s, e, match = string.find(msg, sp..'togglegadget'..ep)
		if (match) then
			self:ToggleGadget(match)
			tracy.ZoneEnd()
			return true
		end
		s, e, match = string.find(msg, sp..'enablegadget'..ep)
		if (match) then
			self:EnableGadget(match)
			tracy.ZoneEnd()
			return true
		end
		s, e, match = string.find(msg, sp..'disablegadget'..ep)
		if (match) then
			self:DisableGadget(match)
			tracy.ZoneEnd()
			return false
		end
	end

	if (actionHandler.GotChatMsg(msg, player)) then
		tracy.ZoneEnd()
		return true
	end

	for _,g in r_ipairs(self.GotChatMsgList) do
		tracy.ZoneBeginN("G:GotChatMsg:" .. g.ghInfo.name)
		if (g:GotChatMsg(msg, player)) then
			tracy.ZoneEnd()
			tracy.ZoneEnd()
			return true
		end
		tracy.ZoneEnd()
	end

	tracy.ZoneEnd()
	return false
end


-- ours
function gadgetHandler:ViewResize(viewGeometry)
	tracy.ZoneBeginN("G:ViewResize")
	local vsx = viewGeometry.viewSizeX
	local vsy = viewGeometry.viewSizeY

	for _,g in r_ipairs(self.ViewResizeList) do
		tracy.ZoneBeginN("G:ViewResize:" .. g.ghInfo.name)
		g:ViewResize(vsx, vsy, viewGeometry)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- FIXME: NOT IN BASE VERSION
--

if Script.IsEngineMinVersion(104, 0, 1431) then

	-- opts is a bitmask
	function gadgetHandler:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams, cmdTag, playerID, fromSynced, fromLua)
		tracy.ZoneBeginN("G:UnitCommand")
		for _,g in r_ipairs(self.UnitCommandList) do
			tracy.ZoneBeginN("G:UnitCommand:" .. g.ghInfo.name)
			g:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams, cmdTag, playerID, fromSynced, fromLua)
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
		return
	end

else

	-- opts is a bitmask
	function gadgetHandler:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams)
		tracy.ZoneBeginN("G:UnitCommand")
		for _,g in r_ipairs(self.UnitCommandList) do
			tracy.ZoneBeginN("G:UnitCommand:" .. g.ghInfo.name)
			g:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams)
			tracy.ZoneEnd()
		end
		tracy.ZoneEnd()
		return
	end

end

function gadgetHandler:UnitEnteredWater(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitEnteredWater")
	for _,g in r_ipairs(self.UnitEnteredWaterList) do
		tracy.ZoneBeginN("G:UnitEnteredWater:" .. g.ghInfo.name)
		g:UnitEnteredWater(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitEnteredAir(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitEnteredAir")
	for _,g in r_ipairs(self.UnitEnteredAirList) do
		tracy.ZoneBeginN("G:UnitEnteredAir:" .. g.ghInfo.name)
		g:UnitEnteredAir(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitLeftWater(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitLeftWater")
	for _,g in r_ipairs(self.UnitLeftWaterList) do
		tracy.ZoneBeginN("G:UnitLeftWater:" .. g.ghInfo.name)
		g:UnitLeftWater(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end


function gadgetHandler:UnitLeftAir(unitID, unitDefID, unitTeam)
	tracy.ZoneBeginN("G:UnitLeftAir")
	for _,g in r_ipairs(self.UnitLeftAirList) do
		tracy.ZoneBeginN("G:UnitLeftAir:" .. g.ghInfo.name)
		g:UnitLeftAir(unitID, unitDefID, unitTeam)
		tracy.ZoneEnd()
	end
	tracy.ZoneEnd()
	return
end

function gadgetHandler:GameSetup(state, ready, playerStates)
	tracy.ZoneBeginN("G:GameSetup")
	for _,g in r_ipairs(self.GameSetupList) do
		tracy.ZoneBeginN("G:GameSetup:" .. g.ghInfo.name)
		local success, newReady = g:GameSetup(state, ready, playerStates)
		tracy.ZoneEnd()
		if (success) then
			tracy.ZoneEnd()
			return true, newReady
		end
	end
	tracy.ZoneEnd()
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

gadgetHandler:Initialize()

