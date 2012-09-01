-- $Id$

function widget:GetInfo()
  return {
    name      = "Building Starter",
    desc      = "v2 Hold Q to queue a building to be started and not continued.",
    author    = "Google Frog",
    date      = "Dec 13, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true  --  loaded by default?
  }
end

local buildings = {}
local numBuildings = 0

local team = Spring.GetMyTeamID()
include("keysym.h.lua")

local CMD_REMOVE = CMD.REMOVE

-- Speedups

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetTeamUnits = Spring.GetTeamUnits
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitPosition = Spring.GetUnitPosition
local spGetKeyState = Spring.GetKeyState
local spGetSelectedUnits = Spring.GetSelectedUnits

local abs = math.abs
--
function widget:Initialize()
	 if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		Spring.Echo("<Building Starter>: disabled for spectators")
		widgetHandler:RemoveWidget()
	end
end

function widget:CommandNotify(id, params, options)
 
  if (id < 0) then
  
    local ux = params[1]
    local uz = params[3]
	
    if (spGetKeyState(KEYSYMS.Q)) then

	  buildings[numBuildings] = { x = ux, z = uz}
	  numBuildings = numBuildings+1
	  
	else
	  for j, i in pairs(buildings) do   
	    if (i.x) then	  
	      if (i.x == ux) and (i.z == uz) then	    
		    buildings[j] = nil
          end
	    end
      end
	end
	
  end
  
end


function CheckBuilding(ux,uz,ud)

  for _, i in pairs(buildings) do    
	
	if (i.x) then	  
	  if (abs(i.x - ux) < 16) and (abs(i.z - uz) < 16) then	    
		i.ud = ud
	    return true	  
      end
	end
	
  end
	
  return false
	
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  
  if (unitTeam ~= team) then 
    return
  end
  
  local units = spGetTeamUnits(team)
  
  local ux, uy, uz  = spGetUnitPosition(unitID)
  
  if CheckBuilding(ux,uz,unitID) then
    for _, unit_id in ipairs(units) do
      local cQueue = spGetCommandQueue(unit_id)
	
		for _, command in ipairs(cQueue) do
		  
		  if command.id < 0 then 
	        local cx = command.params[1]
		    local cz = command.params[3]
		
			if (abs(cx-ux) < 16) and (abs(cz-uz) < 16) then
				spGiveOrderToUnit(unit_id, CMD_REMOVE, {command.tag}, {} )
			end		  
		
		end			
      end	  
	end	
  end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
  
  for j, i in ipairs(buildings) do    
	if (i.ud) then
      buildings[j] = nil
	end
  end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  
  for j, i in pairs(buildings) do    
	if (i.ud) then
      buildings[j] = nil
	end
  end
  
end

