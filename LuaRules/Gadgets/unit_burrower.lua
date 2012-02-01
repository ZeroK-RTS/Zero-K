-- $Id: unit_burrower.lua 3658 2009-01-03 18:34:01Z carrepairer $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "burrower",
    desc      = "Manage burrowing units.",
    author    = "CarRepairer",
    date      = "February 23, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local abs                       = math.abs

--local CMD_ONOFF = CMD.ONOFF
local SYNCSTR = "unit_burrower"

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

local GetUnitIsActive           = Spring.GetUnitIsActive
local GetUnitStates             = Spring.GetUnitStates
local GetCOBScriptID            = Spring.GetCOBScriptID
local GetUnitStates             = Spring.GetUnitStates
local GetUnitBasePosition       = Spring.GetUnitBasePosition
local GetUnitHeading            = Spring.GetUnitHeading
local GetUnitCommands           = Spring.GetUnitCommands

local SetUnitBlocking           = Spring.SetUnitBlocking
local SetUnitCloak              = Spring.SetUnitCloak
local SetUnitRotation           = Spring.SetUnitRotation
local SetUnitExperience         = Spring.SetUnitExperience
local SetUnitHealth             = Spring.SetUnitHealth
local SetUnitLineage            = Spring.SetUnitLineage

local CallCOBScript             = Spring.CallCOBScript
local GiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray
local CreateUnit                = Spring.CreateUnit
local GiveOrderToUnit           = Spring.GiveOrderToUnit
local DestroyUnit               = Spring.DestroyUnit 

local burrowers = {}
local burrowed = {}
local holes = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function DuplicateUnit(unitID, unitDefID, unitTeam, destUnitName)
  local px, py, pz = GetUnitBasePosition(unitID)
  SetUnitBlocking(unitID, false)

  local newUnitID = CreateUnit(destUnitName, px, py, pz, 0, unitTeam)
  SetUnitBlocking(newUnitID, true)

  local h = GetUnitHeading(unitID)
  SetUnitRotation(newUnitID, 0, -h * math.pi / 32768, 0)

  local states = GetUnitStates(unitID)
  GiveOrderArrayToUnitArray( { newUnitID }, {
    { CMD.FIRE_STATE, { states.firestate },             { } },
    { CMD.MOVE_STATE, { states.movestate },             { } },
    { CMD.REPEAT,     { states["repeat"] and 1 or 0 },  { } },
    { CMD.ONOFF,      { states.active and 1 or 0 },     { } },
  })

  local cmds = GetUnitCommands(unitID)
  for i = 1, #cmds do
    local cmd = cmds[i]
    GiveOrderToUnit(newUnitID, cmd.id, cmd.params, cmd.options.coded)
  end
  

  --//copy experience
  local newXp = Spring.GetUnitExperience(unitID)
  SetUnitExperience(newUnitID, newXp)

    --// copy health
  local health,maxHealth = Spring.GetUnitHealth(unitID)  
  SetUnitHealth(newUnitID, health)

  local lineage = Spring.GetUnitLineage(unitID)
  SetUnitLineage(newUnitID,lineage,true)

  return newUnitID

end

function ReplaceMe(unitID, unitDefID, teamID)
  local unitName = UnitDefs[unitDefID].name
  local destUnitName = burrowers[unitName]
  local destIsBurrowed = burrowed[destUnitName]


  if (destUnitName) then     
    newUnitID = DuplicateUnit(unitID, unitDefID, teamID, destUnitName)    
    SendToUnsynced(SYNCSTR, newUnitID, unitID, teamID, (destIsBurrowed or false) )
    if destIsBurrowed then
      SetUnitCloak(newUnitID, 4)
    end
    DestroyUnit(unitID, false, true) 
  end

end

function Surface(unitID, unitDefID, teamID)

  --create hole
  local px, py, pz = GetUnitBasePosition(unitID)
  local holeUnitID = CreateUnit('dughole', px, py+1, pz, 0, teamID)
  SetUnitBlocking(holeUnitID, false)
  SetUnitBlocking(unitID, false)
  SetUnitCloak(holeUnitID, 4)
  --DestroyUnit(holeUnitID, false, true) 
  holes[holeUnitID] = true

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  burrowers["chicken_digger"] = "chicken_digger_b"
  burrowers["chicken_digger_b"] = "chicken_digger"
  burrowed["chicken_digger_b"] = true 

  burrowers["chicken_listener"] = "chicken_listener_b"
  burrowers["chicken_listener_b"] = "chicken_listener"
  burrowed["chicken_listener_b"] = true 

  gadgetHandler:RegisterGlobal("ReplaceMe",ReplaceMe)
  gadgetHandler:RegisterGlobal("Surface",Surface)
end

--Needed when someone gives you a unit?
function gadget:UnitCreated(unitID, unitDefID, teamID)
  local unitName = UnitDefs[unitDefID].name
  if burrowed[unitName] then
    SendToUnsynced(SYNCSTR, unitID, -1, teamID, true)
  end
end

function gadget:UnitFromFactory(unitID, unitDefID, teamID, builderID, _, _)
  local unitName = UnitDefs[unitDefID].name
  if burrowers[unitName] then
    GiveOrderToUnit(unitID, CMD.ONOFF, {0}, {})
  end
end


function gadget:UnitDestroyed(unitID, _, teamID)
  SendToUnsynced(SYNCSTR, unitID, -1, teamID, false)
end

function gadget:UnitTaken(unitID, _, teamID)
  SendToUnsynced(SYNCSTR, unitID, -1, teamID, false)
end

function gadget:GameFrame(n)
	if (((n+2) % 32) < 0.1) then
		for holeUnitID, _ in pairs(holes) do
			DestroyUnit(holeUnitID, false, true) 
		end
		holes = {}
		
	end
end
  


--------------------------------------------------------------------------------
--  END SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------

--local SYNCED = SYNCED

local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glBlending       = gl.Blending
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
local glColor          = gl.Color

local GL_GREATER       = GL.GREATER

local GetGameFrame     = Spring.GetGameFrame
local GetUnitDefID     = Spring.GetUnitDefID
local GetSelectedUnits = Spring.GetSelectedUnits
local GetLocalTeamID   = Spring.GetLocalTeamID

local SelectUnitArray  = Spring.SelectUnitArray
local AreTeamsAllied   = Spring.AreTeamsAllied
local IsUnitSelected   = Spring.IsUnitSelected

local iconsize   = 12
local iconhsize  = iconsize * 0.5
local burrowedUnits = {}
local myTeamID


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function DrawUnitFunc(yshift)
  glTranslate(0, yshift, 0)
  glBillboard()
  glTexRect(-iconhsize, 0, iconhsize, iconsize)
end

-- Add unit to list if burrowed == true, remove if false.
local function updateBurrowers(_, unitID, oldUnitID, teamID, burrowed)
    if (AreTeamsAllied(teamID, myTeamID)) then
      burrowedUnits[unitID] = burrowed or nil

      if (oldUnitID > -1) then
        burrowedUnits[oldUnitID] = (not burrowed) or nil
        if IsUnitSelected(oldUnitID) then
          local unitsToSelect = GetSelectedUnits()
          table.insert(unitsToSelect, unitID)
          SelectUnitArray(unitsToSelect)
        end
      end

    end
end


function gadget:Initialize()
  myTeamID = GetLocalTeamID()
  gadgetHandler:AddSyncAction(SYNCSTR, updateBurrowers)
end

function gadget:DrawWorld()
  
  if (not next(burrowedUnits)) then
    return false
  end

  local gameFrame = GetGameFrame()
  local alpha = abs((gameFrame % 30) - 15) / 15
  
  glDepthMask(true) 
  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0)
  glColor(1,1,1,alpha)
  glTexture('LuaRules/Images/burrower/mole.png')

  --Draw symbol on burrowed units.
  for unitID, _ in pairs(burrowedUnits) do
    glDrawFuncAtUnit(unitID, false, DrawUnitFunc, 5)
  end 

  glTexture(false)
  glAlphaTest(false)
  glDepthTest(false)
  glDepthMask(false)

end



--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
