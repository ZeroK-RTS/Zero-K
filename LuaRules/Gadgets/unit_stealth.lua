-- $Id: unit_stealth.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  THIS ISN'T THE ORIGINAL! (it contains a bugfix by jK)
--
--  file:    unit_stealth.lua
--  brief:   adds active unit stealth capability
--  author:  Dave Rodgers (bugfixed by jK)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "UnitStealth",
    desc      = "Adds active unit stealth capability",
    author    = "trepan (bugfixed by jK)",
    date      = "May 02, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  FIXME: (TODO)
--  - don't allow state changes during pauses (tied to the above)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Proposed Command ID Ranges:
--
--    all negative:  Engine (build commands)
--       0 -   999:  Engine
--    1000 -  9999:  Group AI
--   10000 - 19999:  LuaUI
--   20000 - 29999:  LuaCob
--   30000 - 39999:  LuaRules
--


local CMD_STEALTH = 32100

local SYNCSTR = "unit_stealth"


--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

--
--  speed-ups
--

local SetUnitStealth    = Spring.SetUnitStealth

local UseUnitResource   = Spring.UseUnitResource

local SetUnitRulesParam = Spring.SetUnitRulesParam


--------------------------------------------------------------------------------

local stealthDefs = {}

local stealthUnits = {} -- make it global in Initialize()

local wantingUnits = {}


local stealthCmdDesc = {
  id      = CMD_STEALTH,
  type    = CMDTYPE.ICON_MODE,
  name    = 'Stealth',
  cursor  = 'Stealth',  -- add with LuaUI?
  action  = 'stealth',
  tooltip = 'Stealth State: Sets whether the unit is stealthed or not',
  params  = {'0', 'Stealth Off', 'Stealth On' }
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ValidateStealthDefs(mds)
  local newDefs = {}
  for udName,stealthData in pairs(mds) do
    local ud = UnitDefNames[udName]
    if (not ud) then
      Spring.Echo('Bad stealth unit type: ' .. udName)
    else
      local newData = {}
      newData.draw   = stealthData.draw
      newData.init   = stealthData.init
      newData.energy = stealthData.energy or 0
      newData.delay  = stealthData.delay or 30
      newDefs[ud.id] = newData
--[[
      print('Stealth ' .. udName)
      print('  init   = ' .. tostring(newData.init))
      print('  delay  = ' .. tostring(newData.delay))
      print('  energy = ' .. tostring(newData.energy))
--]]
    end
  end
  return newDefs
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddStealthCmdDesc(unitID, stealthDef)
  stealthCmdDesc.params[1] = (stealthDef.init and '1') or '0'
  local insertID = 
    Spring.FindUnitCmdDesc(unitID, CMD.CLOAK)      or
    Spring.FindUnitCmdDesc(unitID, CMD.ONOFF)      or
    Spring.FindUnitCmdDesc(unitID, CMD.TRAJECTORY) or
    Spring.FindUnitCmdDesc(unitID, CMD.REPEAT)     or
    Spring.FindUnitCmdDesc(unitID, CMD.MOVE_STATE) or
    Spring.FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or
    123456 -- back of the pack
  Spring.InsertUnitCmdDesc(unitID, insertID + 1, stealthCmdDesc)
end


local function AddStealthUnit(unitID, stealthDef)
  AddStealthCmdDesc(unitID, stealthDef)

  local stealthData = {
    id      = unitID,
    def     = stealthDef,
    draw    = stealthDef.draw,
    active  = stealthDef.init,
    energy  = stealthDef.energy / 32,
  }
  stealthUnits[unitID] = stealthData

  if (stealthDef.init) then
    wantingUnits[unitID] = stealthData
    SetUnitRulesParam(unitID, "stealth", 2)
    if (stealthDef.draw) then
      SendToUnsynced(SYNCSTR, unitID, true)
    end
  else
    SetUnitRulesParam(unitID, "stealth", 0)
  end
end


--------------------------------------------------------------------------------

function gadget:Initialize()
  -- get the stealthDefs
  stealthDefs = include("LuaRules/Configs/stealth_defs.lua")
  if (not stealthDefs) then
    gadgetHandler:RemoveGadget()
    return
  end
  gadgetHandler:RegisterCMDID(CMD_STEALTH)

  stealthDefs = ValidateStealthDefs(stealthDefs)

  -- add the Stealth command to existing units
  for _,unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local stealthDef = stealthDefs[unitDefID]
    if (stealthDef) then
      AddStealthUnit(unitID, stealthDef)
    end
  end
end


function gadget:Shutdown()
  for _,unitID in ipairs(Spring.GetAllUnits()) do
    local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
    Spring.SetUnitStealth(unitID, ud.stealth)
    local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_STEALTH)
    if (cmdDescID) then
      Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
    end
  end
end


--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  local stealthDef = stealthDefs[unitDefID]
  if (not stealthDef) then
    return
  end
  AddStealthUnit(unitID, stealthDef)
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  stealthUnits[unitID] = nil
  wantingUnits[unitID] = nil
  SendToUnsynced(SYNCSTR, unitID, false)
end


function gadget:UnitTaken(unitID, unitDefID, unitTeam)
  local stealthUnit = stealthUnits[unitID]
  if (stealthUnit) then
    local stealthDef = stealthUnit.def
    if (stealthDef.init) then
      wantingUnits[unitID] = stealthData
      SetUnitRulesParam(unitID, "stealth", 2)
      if (stealthDef.draw) then
        SendToUnsynced(SYNCSTR, unitID, true)
      end
    else
      wantingUnits[unitID] = nil
      SetUnitRulesParam(unitID, "stealth", 0)
    end
    SendToUnsynced(SYNCSTR, unitID, stealthDef.init)
  end
end


--------------------------------------------------------------------------------

function gadget:GameFrame()
  for unitID, stealthData in pairs(wantingUnits) do
    if (stealthData.delay) then
      stealthData.delay = stealthData.delay - 1
      if (stealthData.delay <= 0) then
        stealthData.delay = nil
      end
    else
      local newState
      if (Spring.GetUnitIsStunned(unitID)) then
        newState = false
      else
        newState = UseUnitResource(unitID, 'e', stealthData.energy)
      end
      if (stealthData.active ~= newState) then
        stealthData.active = newState
        SetUnitStealth(unitID, stealthData.active)
        if (newState) then
          SetUnitRulesParam(unitID, "stealth", 2)
        else
          SetUnitRulesParam(unitID, "stealth", 1)
          stealthData.delay = stealthData.def.delay
        end
        if (stealthData.draw) then
          SendToUnsynced(SYNCSTR, unitID, newState)
        end
      end
    end
  end
end


--------------------------------------------------------------------------------

function StealthCommand(unitID, cmdParams)
  if (type(cmdParams[1]) ~= 'number') then
    return false
  end
  local stealthData = stealthUnits[unitID]
  if (not stealthData) then
    return false
  end

  local state = (cmdParams[1] == 1)
  if (state) then
    wantingUnits[unitID] = stealthData
    SetUnitRulesParam(unitID, "stealth", 2)
  else
    wantingUnits[unitID] = nil
    SetUnitRulesParam(unitID, "stealth", 0)
  end
  if (stealthData.draw) then
    SendToUnsynced(SYNCSTR, unitID, state)
  end

  stealthData.active = state
  SetUnitStealth(unitID, state)

  local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_STEALTH)
  if (cmdDescID) then
    stealthCmdDesc.params[1] = (state and '1') or '0'
    Spring.EditUnitCmdDesc(unitID, cmdDescID, { params = stealthCmdDesc.params})
  end
end


function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOptions)
  if (cmdID ~= CMD_STEALTH) then
    return true  -- command was not used
  end
  StealthCommand(unitID, cmdParams)  
  return false  -- command was used
end


function gadget:CommandFallback(unitID, unitDefID, teamID,
                                cmdID, cmdParams, cmdOptions)
  if (cmdID ~= CMD_STEALTH) then
    return false  -- command was not used
  end
  StealthCommand(unitID, cmdParams)  
  return true, true  -- command was used, remove it
end


--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------

--
-- speed-ups
--

local GetUnitTeam         = Spring.GetUnitTeam
local GetUnitRadius       = Spring.GetUnitRadius
local GetUnitHeading      = Spring.GetUnitHeading
local GetUnitViewPosition = Spring.GetUnitViewPosition

local GetGameFrame        = Spring.GetGameFrame
local GetFrameTimeOffset  = Spring.GetFrameTimeOffset

local glCallList        = gl.CallList
local glDrawListAtUnit = gl.DrawListAtUnit


--------------------------------------------------------------------------------

local drawUnits = {}

local shapeList = 0
local setupMatList = 0
local resetMatList = 0


local function VertexYspin(x, y, z, rads)
  local s = math.sin(rads)
  local c = math.cos(rads)
  local nz = (z * c) - (x * s)
  local nx = (x * c) + (z * s)
  gl.Vertex(nx, y, nz)            
end

      
local function CreateShape(count)
  local d = 0.1
  for i = 0, count - 1 do
    local rads = (2 * math.pi) * (i / count)
    gl.BeginEnd(GL.TRIANGLES, function()
      VertexYspin(1,         0, -d, rads)
      VertexYspin(1,         0,  d, rads)
      VertexYspin(1 + 2 * d, 0,  0, rads)
    end)
  end
end  


local function SetupMaterial()
  gl.Color(1, 0.0, 0.0, 0.5)
  gl.Blending(GL.SRC_ALPHA, GL.ONE)
  gl.DepthTest(true)
end


local function ResetMaterial()
  gl.DepthTest(false)
  gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
end


--------------------------------------------------------------------------------

local function UnitUpdate(cmd, unitID, state)
  if (state) then
    drawUnits[unitID] = true
  else
    drawUnits[unitID] = nil
  end
end

function gadget:Initialize()
  gadgetHandler:AddSyncAction(SYNCSTR, UnitUpdate)
  shapeList    = gl.CreateList(CreateShape, 16)
  setupMatList = gl.CreateList(SetupMaterial)
  resetMatList = gl.CreateList(ResetMaterial)
end


function gadget:Shutdown()
  gl.DeleteList(shapeList)
  gl.DeleteList(setupMatList)
  gl.DeleteList(resetMatList)
end


--------------------------------------------------------------------------------



function gadget:DrawWorld()
  if (not next(drawUnits)) then
    return
  end

  local frame = GetGameFrame() + GetFrameTimeOffset()
  local degrees = (frame * 2) % 360

  glCallList(setupMatList)

  local spec, specFullView = Spring.GetSpectatingState()
  local readTeam
  if (specFullView) then
    readTeam = Script.ALL_ACCESS_TEAM
  else
    readTeam = Spring.GetLocalTeamID()
  end

  CallAsTeam({ ['read'] = readTeam }, function()
    local msg = ''
    for unitID in pairs(drawUnits) do
      if (unitID) then
        if (Spring.IsUnitAllied(unitID)) then
          local r = GetUnitRadius(unitID)
          if (r) then
            glDrawListAtUnit(unitID, shapeList, true, r, r, r, degrees)
          end
        end
      end
    end
  end)

  glCallList(resetMatList)
end


function gadget:UpdateFIXME() -- testing "stealth" RulesParam
  for _,unitID in ipairs(Spring.GetSelectedUnits()) do
    print(unitID, Spring.GetUnitRulesParam(unitID, "stealth"))
  end
end


--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
