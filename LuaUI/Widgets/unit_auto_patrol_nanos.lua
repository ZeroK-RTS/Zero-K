-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_immobile_buider.lua
--  brief:   sets immobile builders to ROAMING, and gives them a PATROL order
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Auto Patrol Nanos",
    desc      = "Sets nano towers to ROAM, with a PATROL command",
    author    = "trepan",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_PATROL        = CMD.PATROL
local CMD_STOP          = CMD.STOP
local spGetGameFrame    = Spring.GetGameFrame
local spGetMyTeamID     = Spring.GetMyTeamID
local spGetTeamUnits    = Spring.GetTeamUnits
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local abs = math.abs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- if this is >0, then commands are re-issued for immobile
-- builders that have been idling for the number of game frames
-- (in case a player accidentally STOPs them)

local idleFrames = 0

local mapCenterX
local mapCenterZ

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Game'
options = 
{
	idleSeconds = {
		name = 'Nano Tower Idle Seconds (0-5)',
		desc = 'Number of seconds a nano turret is idle before it is set to patrol (0 for never).',
		type = 'number',
		
		min = 0,max=5,value = 0,
		OnChange = function(self) idleFrames = self.value*30 end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function IsImmobileBuilder(ud)
  return(ud and ud.builder and not ud.canMove
         and not ud.isFactory)
end


local function SetupUnit(unitID)
  -- set immobile builders (nanotowers?) to the ROAM movestate,
  -- and give them a PATROL order (does not matter where, afaict)
  local x, y, z = spGetUnitPosition(unitID)
  if (x) then

    -- point patrol towards map center
    vx = mapCenterX - x
    vz = mapCenterZ - z
    x = x + vx*25/abs(vx)
    z = z + vz*25/abs(vz)

    spGiveOrderToUnit(unitID, CMD_MOVE_STATE, { 2 }, {})
    spGiveOrderToUnit(unitID, CMD_PATROL, { x, y, z }, {})
  end
end


function widget:Initialize()

  mapCenterX = Game.mapSizeX / 2
  mapCenterZ = Game.mapSizeZ / 2

  for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
    local unitDefID = spGetUnitDefID(unitID)
    if (IsImmobileBuilder(UnitDefs[unitDefID])) then
      SetupUnit(unitID)
    end
  end
end


function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam ~= spGetMyTeamID()) then
    return
  end
  if (IsImmobileBuilder(UnitDefs[unitDefID])) then
    SetupUnit(unitID)
  end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--if (idleFrames > 0) then
if true then

  local idlers = {}


  function widget:GameFrame(frame)
	if idleFrames == 0 then return end
    for unitID, f in pairs(idlers) do
      local idler = idlers[k]
      if ((frame - f) > idleFrames) then
        local cmds = spGetUnitCommands(unitID)
        if (cmds and (#cmds <= 0)) then
          SetupUnit(unitID)
        else
          idlers[unitID] = nil
        end
      end
    end  
  end


  function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    idlers[unitID] = nil
  end


  function widget:UnitIdle(unitID, unitDefID, unitTeam)
    if (unitTeam ~= spGetMyTeamID()) then
      return
    end
    if (IsImmobileBuilder(UnitDefs[unitDefID])) then
      idlers[unitID] = spGetGameFrame()
    end
  end


end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
