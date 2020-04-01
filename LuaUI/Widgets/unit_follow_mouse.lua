--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    write_unit_defs.lua
--  brief:   writes unit defs to file
--  author:  Tim Pitman
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "FollowMouse",
    desc      = "Selected units follow the mouse cursor when H is held down",
    author    = "Aztek",
    date      = "Jun 8, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- include keyboard key definitions
include("keysym.h.lua")

-- static delay timer
delayTimer = 0

spGetKeyState      = Spring.GetKeyState
spGetModKeyState   = Spring.GetModKeyState
spGetMouseState    = Spring.GetMouseState
spTraceScreenRay   = Spring.TraceScreenRay
spGetSelectedUnits = Spring.GetSelectedUnits
spGetUnitDefID     = Spring.GetUnitDefID
spGiveOrderToUnit  = Spring.GiveOrderToUnit

local function MoveUnit(unitID, x, y, z)
--  Spring.Echo('MoveUnit called')
  spGiveOrderToUnit(unitID, CMD.MOVE, { x, y, z }, { "" })
end

function widget:Update(deltaTime)
  -- wait at least 5 cycles between sending orders
  -- currently this is how I'm getting rid of the constant "Can't reach destination" errors.
  if (delayTimer > 5) then
    delayTimer = 0
    local fKeyPressed = spGetKeyState(KEYSYMS.H)
    local alt,ctrl,meta,shift = spGetModKeyState()
    
    if (fKeyPressed) then
      local mousePosX, mousePosY = spGetMouseState()
      local itemUnderMouse, moveToPos = spTraceScreenRay(mousePosX, mousePosY, true)
      
      if (itemUnderMouse == "ground") then
        local units = spGetSelectedUnits()
        
        for i,unitID in ipairs(units) do
          local unitDefID = spGetUnitDefID(unitID)
          if (UnitDefs[unitDefID].canMove) then
            -- TODO: there's got to be a better way to do this...
            MoveUnit(unitID, moveToPos[1], moveToPos[2], moveToPos[3])
          end 
        end
      end
    end
  else
    delayTimer = delayTimer + 1
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------