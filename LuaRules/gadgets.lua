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

local DepthMod = 10
local DepthValue = -1

origPairs = pairs
local whiteList = {['string'] = true, ['number'] = true, ['boolean'] = true, ['nil'] = true, ['thread'] = true}
local function mynext(...)
	local i,v = next(...)
	local t = type(i)
	if not whiteList[t] then
		Spring.Log(HANDLER_BASENAME, "error", '*** A gadget is misusing pairs! Report this with full infolog.txt! ***')
		Spring.Log(HANDLER_BASENAME, "error", t)
		Spring.Log(HANDLER_BASENAME, "error", i)
		Spring.Log(HANDLER_BASENAME, "error", v)
		DepthValue = DepthValue + 1
		if isMission then
			Spring.Log(HANDLER_BASENAME, "error", "Error depth: " .. DepthValue%DepthMod + 1, DepthValue%DepthMod + 1)
		else
			error("Error depth: " .. DepthValue%DepthMod + 1, DepthValue%DepthMod + 1)	-- breaks mission_runner
		end
	end
	return i,v
end

pairs = function(...) 
	if SendToUnsynced then
		local n,s,i = origPairs(...)
		return mynext,s,i
	else
		local n,s,i = origPairs(...)
		return next,s,i
	end
end


local HANDLER_DIR = 'LuaGadgets/'
local GADGETS_DIR = Script.GetName():gsub('US$', '') .. '/Gadgets/'
local SCRIPT_DIR = Script.GetName() .. '/'


local VFSMODE = VFS.ZIP_ONLY
if (Spring.IsDevLuaEnabled()) then
  VFSMODE = VFS.RAW_ONLY
end

VFS.Include(HANDLER_DIR .. 'setupdefs.lua', nil, VFSMODE)
VFS.Include(HANDLER_DIR .. 'system.lua',    nil, VFSMODE)
VFS.Include(HANDLER_DIR .. 'callins.lua',   nil, VFSMODE)
VFS.Include(SCRIPT_DIR .. 'utilities.lua', nil, VFSMODE)

local actionHandler = VFS.Include(HANDLER_DIR .. 'actions.lua', nil, VFSMODE)

local reverseCompatAllowStartPosition = not Spring.Utilities.IsCurrentVersionNewerThan(103, 629)

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


-- these call-ins are set to 'nil' if not used
-- they are setup in UpdateCallIns()
local callInLists = {
	"Shutdown",

	"GamePreload",
	"GameStart",
	"GameOver",
	"GameID",
	"TeamDied",

	"PlayerAdded",
	"PlayerChanged",
	"PlayerRemoved",

	"GameFrame",

	"ViewResize",  -- FIXME ?

	"TextCommand",  -- FIXME ?
	"GotChatMsg",
	"RecvLuaMsg",

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
	"StockpileChanged",

	-- Feature CallIns
	"FeatureCreated",
	"FeatureDestroyed",

	-- Projectile CallIns
	"ProjectileCreated",
	"ProjectileDestroyed",

	-- Shield CallIns
	"ShieldPreDamaged",

	-- Misc Synced CallIns
	"Explosion",

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

	-- Save/Load
	"Save",
	"Load",

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

  -- stuff the gadgets into unsortedGadgets
  for k,gf in ipairs(gadgetFiles) do
--    Spring.Echo('gf2 = ' .. gf) -- FIXME
    local gadget = self:LoadGadget(gf)
    if (gadget) then
      table.insert(unsortedGadgets, gadget)
    end
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
  if (err == false) then
    return nil -- gadget asked for a quiet death
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
  if (((order ~= nil) and (order > 0)) or
      ((order == nil) and ((info == nil) or info.enabled))) then
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
      if (layer >= v.ghInfo.layer) then
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
  if ((#self[listName] > 0)       or
      (name == 'GotChatMsg')      or
      (name == 'RecvFromSynced')) then
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
  if ((name == nil)        or
      (_G[name])           or
      (self.globals[name]) or
      ((CallInsMap and CallInsMap[name]) or (CALLIN_MAP and CALLIN_MAP[name]))) then
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


function gadgetHandler:GetViewSizes()
  return self.xViewSize, self.yViewSize
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
  for _,g in ipairs(self.GamePreloadList) do
    g:GamePreload()
  end
  return
end

function gadgetHandler:GameStart()
  for _,g in ipairs(self.GameStartList) do
    g:GameStart()
  end
  return
end

function gadgetHandler:Shutdown()
  Spring.Echo("Start gadgetHandler:Shutdown")
  for _,g in ipairs(self.ShutdownList) do
    local name = g.ghInfo.name or "UNKNOWN NAME"
	Spring.Echo("Shutdown - " .. name)
	g:Shutdown()
  end
  Spring.Echo("End gadgetHandler:Shutdown")
  return
end

function gadgetHandler:GameFrame(frameNum)
  for _,g in ipairs(self.GameFrameList) do
    g:GameFrame(frameNum)
  end
  return
end


function gadgetHandler:RecvFromSynced(...)
  if (actionHandler.RecvFromSynced(...)) then
    return
  end
  for _,g in ipairs(self.RecvFromSyncedList) do
    if (g:RecvFromSynced(...)) then
      return
    end
  end
  return
end


--function gadgetHandler:GotChatMsg(msg, player)
--  if ((player == 0) and Spring.IsCheatingEnabled()) then
--    local sp = '^%s*'    -- start pattern
--    local ep = '%s+(.*)' -- end pattern
--    local s, e, match
--    s, e, match = string.find(msg, sp..'togglegadget'..ep)
--    if (match) then
--      self:ToggleGadget(match)
--      return true
--    end
--    s, e, match = string.find(msg, sp..'enablegadget'..ep)
--    if (match) then
--      self:EnableGadget(match)
--      return true
--    end
--    s, e, match = string.find(msg, sp..'disablegadget'..ep)
--	if (match) then
--      self:DisableGadget(match)
--      return true
--    end
--  end
--
--  if (actionHandler.GotChatMsg(msg, player)) then
--    return true
--  end
--
--  for _,g in ipairs(self.GotChatMsgList) do
--    if (g:GotChatMsg(msg, player)) then
--      return true
--    end
--  end
--
--  return false
--end


function gadgetHandler:RecvLuaMsg(msg, player)
  for _,g in ipairs(self.RecvLuaMsgList) do
    if (g:RecvLuaMsg(msg, player)) then
      return true
    end
  end
  return false
end


--------------------------------------------------------------------------------
--
--  Drawing call-ins
--

-- generates ViewResize() calls for the gadgets
function gadgetHandler:SetViewSize(vsx, vsy)
  self.xViewSize = vsx
  self.yViewSize = vsy
  if ((self.xViewSizeOld ~= vsx) or
      (self.yViewSizeOld ~= vsy)) then
    gadgetHandler:ViewResize(vsx, vsy)
    self.xViewSizeOld = vsx
    self.yViewSizeOld = vsy
  end
end


function gadgetHandler:ViewResize(vsx, vsy)
  for _,g in ipairs(self.ViewResizeList) do
    g:ViewResize(vsx, vsy)
  end
  return
end


--------------------------------------------------------------------------------
--
--  Game call-ins
--

function gadgetHandler:GameOver(winners)
  for _,g in ipairs(self.GameOverList) do
    g:GameOver(winners)
  end
  return
end

function gadgetHandler:GameID(gameID)
  for _,g in ipairs(self.GameIDList) do
    g:GameID(gameID)
  end
  return
end


function gadgetHandler:TeamDied(teamID)
  for _,g in ipairs(self.TeamDiedList) do
    g:TeamDied(teamID)
  end
  return
end

function gadgetHandler:PlayerAdded(playerID)
  for _,g in ipairs(self.PlayerAddedList) do
    g:PlayerAdded(playerID)
  end
  return
end

function gadgetHandler:PlayerChanged(playerID)
  for _,g in ipairs(self.PlayerChangedList) do
    g:PlayerChanged(playerID)
  end
  return
end

function gadgetHandler:PlayerRemoved(playerID, reason)
  for _,g in ipairs(self.PlayerRemovedList) do
    g:PlayerRemoved(playerID, reason)
  end
  return
end


--------------------------------------------------------------------------------
--
--  LuaRules Game call-ins
--

function gadgetHandler:DrawUnit(unitID, drawMode)
  for _,g in ipairs(self.DrawUnitList) do
    if (g:DrawUnit(unitID, drawMode)) then
      return true
    end
  end
  return false
end

function gadgetHandler:DrawFeature(featureID, drawMode)
  for _,g in ipairs(self.DrawFeatureList) do
    if (g:DrawFeature(featureID, drawMode)) then
      return true
    end
  end
  return false
end

function gadgetHandler:DrawShield(unitID, weaponID, drawMode)
  for _,g in ipairs(self.DrawShieldList) do
    if (g:DrawShield(unitID, weaponID, drawMode)) then
      return true
    end
  end
  return false
end

function gadgetHandler:DrawProjectile(projectileID, drawMode)
  for _,g in ipairs(self.DrawProjectileList) do
    if (g:DrawProjectile(projectileID, drawMode)) then
      return true
    end
  end
  return false
end

function gadgetHandler:RecvSkirmishAIMessage(aiTeam, dataStr)
  for _,g in ipairs(self.RecvSkirmishAIMessageList) do
    local dataRet = g:RecvSkirmishAIMessage(aiTeam, dataStr)
    if (dataRet) then
      return dataRet
    end
  end
end


function gadgetHandler:CommandFallback(unitID, unitDefID, unitTeam,
                                       cmdID, cmdParams, cmdOptions, cmdTag)
  for _,g in ipairs(self.CommandFallbackList) do
    local used, remove = g:CommandFallback(unitID, unitDefID, unitTeam,
                                           cmdID, cmdParams, cmdOptions, cmdTag)
    if (used) then
      return remove
    end
  end
  return true  -- remove the command
end


function gadgetHandler:AllowCommand(unitID, unitDefID, unitTeam,
                                    cmdID, cmdParams, cmdOptions, cmdTag, synced)
  for _,g in ipairs(self.AllowCommandList) do

	if (not g:AllowCommand(unitID, unitDefID, unitTeam,
                           cmdID, cmdParams, cmdOptions, cmdTag, synced)) then
      return false
    end
  end
  return true
end

function gadgetHandler:AllowStartPosition(playerID, teamID, readyState, cx, cy, cz, rx, ry, rz)
  if reverseCompatAllowStartPosition then
    cx, cy, cz, playerID, readyState, rx, ry, rz = playerID, teamID, readyState, cx, cy, cz, rx, ry
  end
  for _,g in ipairs(self.AllowStartPositionList) do
    if (not g:AllowStartPosition(playerID, teamID, readyState, cx, cy, cz, rx, ry, rz)) then
      return false
    end
  end
  return true
end

function gadgetHandler:AllowUnitCreation(unitDefID, builderID,
                                         builderTeam, x, y, z, facing)
  for _,g in ipairs(self.AllowUnitCreationList) do
    if (not g:AllowUnitCreation(unitDefID, builderID,
                                builderTeam, x, y, z, facing)) then
      return false
    end
  end
  return true
end


function gadgetHandler:AllowUnitTransfer(unitID, unitDefID,
                                         oldTeam, newTeam, capture)
  for _,g in ipairs(self.AllowUnitTransferList) do
    if (not g:AllowUnitTransfer(unitID, unitDefID,
                                oldTeam, newTeam, capture)) then
      return false
    end
  end
  return true
end


function gadgetHandler:AllowUnitBuildStep(builderID, builderTeam,
                                          unitID, unitDefID, part)
  for _,g in ipairs(self.AllowUnitBuildStepList) do
    if (not g:AllowUnitBuildStep(builderID, builderTeam,
                                 unitID, unitDefID, part)) then
      return false
    end
  end
  return true
end

function gadgetHandler:AllowUnitTransport(
  transporterID, transporterUnitDefID, transporterTeam,
  transporteeID, transporteeUnitDefID, transporteeTeam
)
  for _,g in ipairs(self.AllowUnitTransportList) do
    if (not g:AllowUnitTransport(
      transporterID, transporterUnitDefID, transporterTeam,
      transporteeID, transporteeUnitDefID, transporteeTeam
    )) then
      return false
    end
  end
  return true
end

function gadgetHandler:AllowUnitTransportLoad(
  transporterID, transporterUnitDefID, transporterTeam,
  transporteeID, transporteeUnitDefID, transporteeTeam,
  loadPosX, loadPosY, loadPosZ
)
  for _,g in ipairs(self.AllowUnitTransportLoadList) do
    if (not g:AllowUnitTransportLoad(
      transporterID, transporterUnitDefID, transporterTeam,
      transporteeID, transporteeUnitDefID, transporteeTeam,
      loadPosX, loadPosY, loadPosZ
    )) then
      return false
    end
  end
  return true
end

function gadgetHandler:AllowUnitTransportUnload(
  transporterID, transporterUnitDefID, transporterTeam,
  transporteeID, transporteeUnitDefID, transporteeTeam,
  unloadPosX, unloadPosY, unloadPosZ
)
  for _,g in ipairs(self.AllowUnitTransportUnloadList) do
    if (not g:AllowUnitTransportUnload(
      transporterID, transporterUnitDefID, transporterTeam,
      transporteeID, transporteeUnitDefID, transporteeTeam,
      unloadPosX, unloadPosY, unloadPosZ
    )) then
      return false
    end
  end
  return true
end

function gadgetHandler:AllowUnitCloak(unitID, enemyID)
  -- The case can be that unitID == enemyID. This is for engine stunned unitID, they are their own enemies.
  for _,g in ipairs(self.AllowUnitCloakList) do
    if (not g:AllowUnitCloak(unitID, enemyID)) then
      return false
    end
  end

  return true
end


function gadgetHandler:AllowUnitDecloak(unitID, objectID, weaponID)
  for _,g in ipairs(self.AllowUnitDecloakList) do
    if (not g:AllowUnitDecloak(unitID, objectID, weaponID)) then
      return false
    end
  end

  return true
end


function gadgetHandler:AllowFeatureBuildStep(builderID, builderTeam,
                                             featureID, featureDefID, part)
  for _,g in ipairs(self.AllowFeatureBuildStepList) do
    if (not g:AllowFeatureBuildStep(builderID, builderTeam,
                                    featureID, featureDefID, part)) then
      return false
    end
  end
  return true
end


function gadgetHandler:AllowFeatureCreation(featureDefID, teamID, x, y, z)
  for _,g in ipairs(self.AllowFeatureCreationList) do
    if (not g:AllowFeatureCreation(featureDefID, teamID, x, y, z)) then
      return false
    end
  end
  return true
end


function gadgetHandler:AllowResourceLevel(teamID, res, level)
  for _,g in ipairs(self.AllowResourceLevelList) do
    if (not g:AllowResourceLevel(teamID, res, level)) then
      return false
    end
  end
  return true
end


function gadgetHandler:AllowResourceTransfer(oldTeamID, newTeamID, res, amount)
  for _,g in ipairs(self.AllowResourceTransferList) do
    if (not g:AllowResourceTransfer(oldTeamID, newTeamID, res, amount)) then
      return false
    end
  end
  return true
end


function gadgetHandler:AllowDirectUnitControl(unitID, unitDefID, unitTeam,
                                              playerID)
  for _,g in ipairs(self.AllowDirectUnitControlList) do
    if (not g:AllowDirectUnitControl(unitID, unitDefID, unitTeam,
                                     playerID)) then
      return false
    end
  end
  return true
end

function gadgetHandler:AllowBuilderHoldFire(unitID, unitDefID, action)
	for _,g in ipairs(self.AllowBuilderHoldFireList) do
		if (not g:AllowBuilderHoldFire(unitID, unitDefID, action)) then
			return false
		end
	end
	return true
end


function gadgetHandler:MoveCtrlNotify(unitID, unitDefID, unitTeam, data)
  local state = false
  for _,g in ipairs(self.MoveCtrlNotifyList) do
    if (g:MoveCtrlNotify(unitID, unitDefID, unitTeam, data)) then
      state = true
    end
  end
  return state
end


function gadgetHandler:TerraformComplete(unitID, unitDefID, unitTeam,
                                       buildUnitID, buildUnitDefID, buildUnitTeam)
  for _,g in ipairs(self.TerraformCompleteList) do
    local stop = g:TerraformComplete(unitID, unitDefID, unitTeam,
                                       buildUnitID, buildUnitDefID, buildUnitTeam)
    if (stop) then
      return true
    end
  end
  return false
end


function gadgetHandler:AllowWeaponTargetCheck(attackerID, attackerWeaponNum, attackerWeaponDefID)
	for _, g in ipairs(self.AllowWeaponTargetCheckList) do
		if (not g:AllowWeaponTargetCheck(attackerID, attackerWeaponNum, attackerWeaponDefID)) then
			return false
		end
	end
	return true
end

-- AllowWeaponTarget is also called when auto-generating CAI attack commands.
-- When targetID=-1 and weaponNum=-1 targetPriority determines the target search
-- radius; targetPriority=nil accompanies any actual

function gadgetHandler:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	local allowed = true
	local returnValue
	
	if targetID == -1 then
		local unitID = attackerID
		local aquireRange = defPriority
		for _, g in ipairs(self.AllowUnitTargetRangeList) do
			-- Send priority to each successive gadget.
			local targetAllowed, newRange = g:AllowUnitTargetRange(unitID, aquireRange)

			if (not targetAllowed) then
				allowed = false
				break
			end

			aquireRange = newRange
		end
		return true, aquireRange
	end
	
	local priority = defPriority
	for _, g in ipairs(self.AllowWeaponTargetList) do
		-- Send priority to each successive gadget.
		local targetAllowed, targetPriority = g:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, priority)

		if (not targetAllowed) then
			allowed = false
			break
		end

		priority = targetPriority
	end
	return allowed, priority
end

function gadgetHandler:AllowWeaponInterceptTarget(interceptorUnitID, interceptorWeaponNum, targetProjectileID)
	for _, g in ipairs(self.AllowWeaponInterceptTargetList) do
		if (not g:AllowWeaponInterceptTarget(interceptorUnitID, interceptorWeaponNum, targetProjectileID)) then
			return false
		end
	end
	
	return true
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

local inCreated = false
local finishedDuringCreated = false -- assumes non-recursive create
function gadgetHandler:UnitCreated(unitID, unitDefID, unitTeam, builderID)

  finishedDuringCreated = false
  inCreated = true
  for _,g in ipairs(self.UnitCreatedList) do
    g:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  end
  inCreated = false

  if finishedDuringCreated then
    finishedDuringCreated = false
    gadgetHandler:UnitFinished(unitID, unitDefID, unitTeam)
  end
end

function gadgetHandler:UnitFinished(unitID, unitDefID, unitTeam)
  if inCreated then
    finishedDuringCreated = true
    return
  end

  for _,g in ipairs(self.UnitFinishedList) do
    g:UnitFinished(unitID, unitDefID, unitTeam)
  end
  return
end

function gadgetHandler:UnitReverseBuilt(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitReverseBuiltList) do
    g:UnitReverseBuilt(unitID, unitDefID, unitTeam)
  end
  return
end

function gadgetHandler:UnitStunned(unitID, unitDefID, unitTeam, stunned)
  for _,g in ipairs(self.UnitStunnedList) do
    g:UnitStunned(unitID, unitDefID, unitTeam, stunned)
  end
  return
end

function gadgetHandler:UnitFromFactory(unitID, unitDefID, unitTeam,
                                       factID, factDefID, userOrders)
  for _,g in ipairs(self.UnitFromFactoryList) do
    g:UnitFromFactory(unitID, unitDefID, unitTeam,
                      factID, factDefID, userOrders)
  end
  return
end


function gadgetHandler:UnitDestroyed(unitID,     unitDefID,     unitTeam,
                                     attackerID, attackerDefID, attackerTeam, pre)
  if pre == false then return end
  for _,g in ipairs(self.UnitDestroyedList) do
    g:UnitDestroyed(unitID,     unitDefID,     unitTeam,
                    attackerID, attackerDefID, attackerTeam)
  end
  return
end


function gadgetHandler:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.RenderUnitDestroyedList) do
    g:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
  end
  return
end


function gadgetHandler:UnitExperience(unitID, unitDefID, unitTeam,
                                      experience, oldExperience)
  for _,g in ipairs(self.UnitExperienceList) do
    g:UnitExperience(unitID, unitDefID, unitTeam, experience, oldExperience)
  end
  return
end


function gadgetHandler:UnitIdle(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitIdleList) do
    g:UnitIdle(unitID, unitDefID, unitTeam)
  end
  return
end


function gadgetHandler:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
  for _,g in ipairs(self.UnitCmdDoneList) do
    g:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
  end
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
	
	if UnitPreDamaged_first then
		for _,g in ipairs(self.UnitPreDamagedList) do
			local weaponDefs = (g.UnitPreDamaged_GetWantedWeaponDef and g:UnitPreDamaged_GetWantedWeaponDef()) or allWeaponDefs
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
		local data = gadgets.data
		local g
		for i = 1, gadgets.count do
			g = data[i]
			local dam, imp = g:UnitPreDamaged(unitID, unitDefID, unitTeam,
					  rDam, paralyzer, weaponDefID,
					  attackerID, attackerDefID, attackerTeam,
					  projectileID)
			if (dam ~= nil) then
				rDam = dam
			end
			if (imp ~= nil) then
				rImp = math.min(imp, rImp)
			end
		end
	end

	return rDam, rImp
end

--[[ Old
function gadgetHandler:UnitPreDamaged(unitID, unitDefID, unitTeam,
                                   damage, paralyzer, weaponDefID,
								   projectileID, attackerID, attackerDefID, attackerTeam)
  
  local rDam = damage
  local rImp = 1.0

  for _,g in ipairs(self.UnitPreDamagedList) do
    dam, imp = g:UnitPreDamaged(unitID, unitDefID, unitTeam,
                  rDam, paralyzer, weaponDefID,
                  attackerID, attackerDefID, attackerTeam,
				  projectileID)
    if (dam ~= nil) then
      rDam = dam
    end
    if (imp ~= nil) then
      rImp = math.min(imp, rImp)
    end
  end

  return rDam, rImp
end
--]]

local UnitDamaged_first = true
local UnitDamaged_count = 0
local UnitDamaged_gadgets = {}

function gadgetHandler:UnitDamaged(unitID, unitDefID, unitTeam,
                                   damage, paralyzer, weaponID, projectileID, 
                                   attackerID, attackerDefID, attackerTeam)
								   
	if UnitDamaged_first then
		for _,g in ipairs(self.UnitDamagedList) do
			UnitDamaged_count = UnitDamaged_count + 1
			UnitDamaged_gadgets[UnitDamaged_count] = g
		end
		UnitDamaged_first = false
	end

	local g
	for i = 1, UnitDamaged_count do
		g = UnitDamaged_gadgets[i]
		g:UnitDamaged(unitID, unitDefID, unitTeam,
				damage, paralyzer, weaponID,
				attackerID, attackerDefID, attackerTeam)
	end
	return
end

--[[ Old
function gadgetHandler:UnitDamaged(unitID, unitDefID, unitTeam,
                                   damage, paralyzer, weaponID, projectileID, 
                                   attackerID, attackerDefID, attackerTeam)
  
  for _,g in ipairs(self.UnitDamagedList) do
    g:UnitDamaged(unitID, unitDefID, unitTeam,
                  damage, paralyzer, weaponID,
                  attackerID, attackerDefID, attackerTeam)
  end
  return
end
--]]


function gadgetHandler:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  for _,g in ipairs(self.UnitTakenList) do
    g:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  end
  return
end


function gadgetHandler:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  for _,g in ipairs(self.UnitGivenList) do
    g:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  end
  return
end


function gadgetHandler:UnitEnteredRadar(unitID, unitTeam, allyTeam, unitDefID)
  for _,g in ipairs(self.UnitEnteredRadarList) do
    g:UnitEnteredRadar(unitID, unitTeam, allyTeam, unitDefID)
  end
  return
end


function gadgetHandler:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
  for _,g in ipairs(self.UnitEnteredLosList) do
    g:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
  end
  return
end


function gadgetHandler:UnitLeftRadar(unitID, unitTeam, allyTeam, unitDefID)
  for _,g in ipairs(self.UnitLeftRadarList) do
    g:UnitLeftRadar(unitID, unitTeam, allyTeam, unitDefID)
  end
  return
end


function gadgetHandler:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
  for _,g in ipairs(self.UnitLeftLosList) do
    g:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
  end
  return
end


function gadgetHandler:UnitSeismicPing(x, y, z, strength,
                                       allyTeam, unitID, unitDefID)
  for _,g in ipairs(self.UnitSeismicPingList) do
    g:UnitSeismicPing(x, y, z, strength,
                      allyTeam, unitID, unitDefID)
  end
  return
end


function gadgetHandler:UnitLoaded(unitID, unitDefID, unitTeam,
                                  transportID, transportTeam)
  for _,g in ipairs(self.UnitLoadedList) do
    g:UnitLoaded(unitID, unitDefID, unitTeam,
                 transportID, transportTeam)
  end
  return
end


function gadgetHandler:UnitUnloaded(unitID, unitDefID, unitTeam,
                                    transportID, transportTeam)
  for _,g in ipairs(self.UnitUnloadedList) do
    g:UnitUnloaded(unitID, unitDefID, unitTeam,
                   transportID, transportTeam)
  end
  return
end


function gadgetHandler:UnitCloaked(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitCloakedList) do
    g:UnitCloaked(unitID, unitDefID, unitTeam)
  end
  return
end


function gadgetHandler:UnitDecloaked(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitDecloakedList) do
    g:UnitDecloaked(unitID, unitDefID, unitTeam)
  end
  return
end


function gadgetHandler:UnitUnitCollision(colliderID, collideeID)
	for _,g in ipairs(self.UnitUnitCollisionList) do
		g:UnitUnitCollision(colliderID, collideeID)
	end
end

function gadgetHandler:UnitFeatureCollision(colliderID, collideeID)
	for _,g in ipairs(self.UnitFeatureCollisionList) do
		g:UnitFeatureCollision(colliderID, collideeID)
	end
end


function gadgetHandler:StockpileChanged(unitID, unitDefID, unitTeam,
                                        weaponNum, oldCount, newCount)
  for _,g in ipairs(self.StockpileChangedList) do
    g:StockpileChanged(unitID, unitDefID, unitTeam,
                       weaponNum, oldCount, newCount)
  end
  return
end


--------------------------------------------------------------------------------
--
--  Feature call-ins
--

function gadgetHandler:FeatureCreated(featureID, allyTeam)
  for _,g in ipairs(self.FeatureCreatedList) do
    g:FeatureCreated(featureID, allyTeam)
  end
  return
end


function gadgetHandler:FeatureDestroyed(featureID, allyTeam)
  for _,g in ipairs(self.FeatureDestroyedList) do
    g:FeatureDestroyed(featureID, allyTeam)
  end
  return
end


--------------------------------------------------------------------------------
--
--  Projectile call-ins
--

function gadgetHandler:ProjectileCreated(proID, proOwnerID, proWeaponDefID)
  for _,g in ipairs(self.ProjectileCreatedList) do
    g:ProjectileCreated(proID, proOwnerID, proWeaponDefID)
  end
  return
end


function gadgetHandler:ProjectileDestroyed(proID)
  for _,g in ipairs(self.ProjectileDestroyedList) do
    g:ProjectileDestroyed(proID)
  end
  return
end


--------------------------------------------------------------------------------
--
--  Shield call-ins
--

function gadgetHandler:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID, startX, startY, startZ, hitX, hitY, hitZ)

  for _,g in ipairs(self.ShieldPreDamagedList) do
    -- first gadget to handle this consumes the event
    if (g:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID, startX, startY, startZ, hitX, hitY, hitZ)) then
      return true
    end
  end

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
	if Explosion_first then
		for _,g in ipairs(self.ExplosionList) do
			local weaponDefs = (g.Explosion_GetWantedWeaponDef and g:Explosion_GetWantedWeaponDef()) or allWeaponDefs
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
			noGfx = noGfx or g:Explosion(weaponID, px, py, pz, ownerID, proID)
		end
	end
	return noGfx or false
end

--[[ Base
function gadgetHandler:Explosion(weaponID, px, py, pz, ownerID)
  local noGfx = false
  for _,g in ipairs(self.ExplosionList) do
	noGfx = noGfx or g:Explosion(weaponID, px, py, pz, ownerID)
  end
  return noGfx
end
--]]

--------------------------------------------------------------------------------
--
--  Draw call-ins
--

function gadgetHandler:Update()
  for _,g in ipairs(self.UpdateList) do
    g:Update()
  end
  return
end


function gadgetHandler:DefaultCommand(type, id, engineCmd)
  for _,g in ipairs(self.DefaultCommandList) do
    local defCmd = g:DefaultCommand(type, id, engineCmd)
    if defCmd then
      return defCmd
    end
  end
  return
end


function gadgetHandler:DrawGenesis()
  for _,g in ipairs(self.DrawGenesisList) do
    g:DrawGenesis()
  end
  return
end


function gadgetHandler:DrawWorld()
  for _,g in ipairs(self.DrawWorldList) do
    g:DrawWorld()
  end
  return
end


function gadgetHandler:DrawWorldPreUnit()
  for _,g in ipairs(self.DrawWorldPreUnitList) do
    g:DrawWorldPreUnit()
  end
  return
end


function gadgetHandler:DrawWorldShadow()
  for _,g in ipairs(self.DrawWorldShadowList) do
    g:DrawWorldShadow()
  end
  return
end


function gadgetHandler:DrawWorldReflection()
  for _,g in ipairs(self.DrawWorldReflectionList) do
    g:DrawWorldReflection()
  end
  return
end


function gadgetHandler:DrawWorldRefraction()
  for _,g in ipairs(self.DrawWorldRefractionList) do
    g:DrawWorldRefraction()
  end
  return
end


function gadgetHandler:DrawScreenEffects(vsx, vsy)
  for _,g in ipairs(self.DrawScreenEffectsList) do
    g:DrawScreenEffects(vsx, vsy)
  end
  return
end

function gadgetHandler:DrawScreenPost(vsx, vsy)
  for _,g in ipairs(self.DrawScreenPostList) do
    g:DrawScreenPost(vsx, vsy)
  end
  return
end


function gadgetHandler:DrawScreen(vsx, vsy)
  for _,g in ipairs(self.DrawScreenList) do
    g:DrawScreen(vsx, vsy)
  end
  return
end


function gadgetHandler:DrawInMiniMap(mmsx, mmsy)
  for _,g in ipairs(self.DrawInMiniMapList) do
    g:DrawInMiniMap(mmsx, mmsy)
  end
  return
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadgetHandler:KeyPress(key, mods, isRepeat, label, unicode)
  for _,g in ipairs(self.KeyPressList) do
    if (g:KeyPress(key, mods, isRepeat, label, unicode)) then
      return true
    end
  end
  return false
end


function gadgetHandler:KeyRelease(key, mods, label, unicode)
  for _,g in ipairs(self.KeyReleaseList) do
    if (g:KeyRelease(key, mods, label, unicode)) then
      return true
    end
  end
  return false
end


function gadgetHandler:MousePress(x, y, button)
  local mo = self.mouseOwner
  if (mo) then
    mo:MousePress(x, y, button)
    return true  --  already have an active press
  end
  for _,g in ipairs(self.MousePressList) do
    if (g:MousePress(x, y, button)) then
      self.mouseOwner = g
      return true
    end
  end
  return false
end


function gadgetHandler:MouseMove(x, y, dx, dy, button)
  local mo = self.mouseOwner
  if (mo and mo.MouseMove) then
    return mo:MouseMove(x, y, dx, dy, button)
  end
end


function gadgetHandler:MouseRelease(x, y, button)
  local mo = self.mouseOwner
  local mx, my, lmb, mmb, rmb = Spring.GetMouseState()
  if (not (lmb or mmb or rmb)) then
    self.mouseOwner = nil
  end
  if (mo and mo.MouseRelease) then
    return mo:MouseRelease(x, y, button)
  end
  return -1
end


function gadgetHandler:MouseWheel(up, value)
  for _,g in ipairs(self.MouseWheelList) do
    if (g:MouseWheel(up, value)) then
      return true
    end
  end
  return false
end


function gadgetHandler:IsAbove(x, y)
  for _,g in ipairs(self.IsAboveList) do
    if (g:IsAbove(x, y)) then
      return true
    end
  end
  return false
end


function gadgetHandler:GetTooltip(x, y)
  for _,g in ipairs(self.GetTooltipList) do
    if (g:IsAbove(x, y)) then
      local tip = g:GetTooltip(x, y)
      if (string.len(tip) > 0) then
        return tip
      end
    end
  end
  return ''
end


function gadgetHandler:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
  for _,g in ipairs(self.UnsyncedHeightMapUpdateList) do
    g:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
  end
  return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadgetHandler:Save(zip)
  for _,g in ipairs(self.SaveList) do
    g:Save(zip)
  end
  return
end


function gadgetHandler:Load(zip)
  for _,g in ipairs(self.LoadList) do
    g:Load(zip)
  end
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

function gadgetHandler:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced) 	-- ours
--function gadgetHandler:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)	-- base
  for _,g in ipairs(self.AllowCommandList) do
	if not AllowCommand_WantedCommand[g] then
		AllowCommand_WantedCommand[g] = (g.AllowCommand_GetWantedCommand and g:AllowCommand_GetWantedCommand()) or true
	end
	if not AllowCommand_WantedUnitDefID[g] then
		AllowCommand_WantedUnitDefID[g] = (g.AllowCommand_GetWantedUnitDefID and g:AllowCommand_GetWantedUnitDefID()) or true
	end
	local wantedCommand = AllowCommand_WantedCommand[g]
	local wantedUnitDefID = AllowCommand_WantedUnitDefID[g]

	--if g:GetBadCommand() then
	--	Spring.Echo(g:GetBadCommand())
	--end
	if ((wantedCommand == true) or wantedCommand[cmdID]) and
		((wantedUnitDefID == true) or wantedUnitDefID[unitDefID]) and
		(not g:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)) then	-- ours
	--if (not g:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)) then	-- base
      return false
    end
  end
  return true
end

-- ours
function gadgetHandler:RecvFromSynced(cmd,...)
  if (cmd == "proxy_ChatMsg") then
    gadgetHandler:GotChatMsg(...)
    return
  end

  if (actionHandler.RecvFromSynced(cmd, ...)) then
    return
  end
  for _,g in ipairs(self.RecvFromSyncedList) do
    if (g:RecvFromSynced(cmd, ...)) then
      return
    end
  end
  return
end

-- base
--[[
function gadgetHandler:RecvFromSynced(...)
  if (actionHandler.RecvFromSynced(...)) then
    return
  end
  for _,g in ipairs(self.RecvFromSyncedList) do
    if (g:RecvFromSynced(...)) then
      return
    end
  end
  return
end
--]]

function gadgetHandler:GotChatMsg(msg, player)

  if (((player == 0) or (player == 255)) and Spring.IsCheatingEnabled()) then	-- ours
  --if ((player == 0) and Spring.IsCheatingEnabled()) then		-- base
    local sp = '^%s*'    -- start pattern
    local ep = '%s+(.*)' -- end pattern
    local s, e, match
    s, e, match = string.find(msg, sp..'togglegadget'..ep)
    if (match) then
      self:ToggleGadget(match)
      return true
    end
    s, e, match = string.find(msg, sp..'enablegadget'..ep)
    if (match) then
      self:EnableGadget(match)
      return true
    end
    s, e, match = string.find(msg, sp..'disablegadget'..ep)
    if (match) then
      self:DisableGadget(match)
      return false
    end
  end

  if (actionHandler.GotChatMsg(msg, player)) then
    return true
  end

  for _,g in ipairs(self.GotChatMsgList) do
    if (g:GotChatMsg(msg, player)) then
      return true
    end
  end

  return false
end


-- ours
function gadgetHandler:ViewResize(viewGeometry)
  local vsx = viewGeometry.viewSizeX
  local vsy = viewGeometry.viewSizeY

  for _,g in ipairs(self.ViewResizeList) do
    g:ViewResize(vsx, vsy, viewGeometry)
  end
  return
end

-- base
--[[
function gadgetHandler:ViewResize(vsx, vsy)
  for _,g in ipairs(self.ViewResizeList) do
    g:ViewResize(vsx, vsy)
  end
  return
end

-- generates ViewResize() calls for the gadgets
function gadgetHandler:SetViewSize(vsx, vsy)
  self.xViewSize = vsx
  self.yViewSize = vsy
  if ((self.xViewSizeOld ~= vsx) or
      (self.yViewSizeOld ~= vsy)) then
    gadgetHandler:ViewResize(vsx, vsy)
    self.xViewSizeOld = vsx
    self.yViewSizeOld = vsy
  end
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- FIXME: NOT IN BASE VERSION
--

function gadgetHandler:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams) -- opts is a bitmask
  for _,g in ipairs(self.UnitCommandList) do
    g:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams) 
  end
  return
end

function gadgetHandler:UnitEnteredWater(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitEnteredWaterList) do
    g:UnitEnteredWater(unitID, unitDefID, unitTeam)
  end
  return
end


function gadgetHandler:UnitEnteredAir(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitEnteredAirList) do
    g:UnitEnteredAir(unitID, unitDefID, unitTeam)
  end
  return
end


function gadgetHandler:UnitLeftWater(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitLeftWaterList) do
    g:UnitLeftWater(unitID, unitDefID, unitTeam)
  end
  return
end


function gadgetHandler:UnitLeftAir(unitID, unitDefID, unitTeam)
  for _,g in ipairs(self.UnitLeftAirList) do
    g:UnitLeftAir(unitID, unitDefID, unitTeam)
  end
  return
end

function gadgetHandler:GameSetup(state, ready, playerStates)
  for _,g in ipairs(self.GameSetupList) do
    local success, newReady = g:GameSetup(state, ready, playerStates)
    if (success) then
      return true, newReady
    end
  end
  return false
end

--[[
-- makes available to gadgets with handler = true
function gadgetHandler:AddSyncAction(gadget, cmd, func, help)
	return actionHandler.AddSyncAction(gadget, cmd, func, help)
end

function gadgetHandler:RemoveSyncAction(gadget, cmd)
	return actionHandler.RemoveSyncAction(gadget, cmd)
end
]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

gadgetHandler:Initialize()

