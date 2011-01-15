--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Everything Hold Pos.",
    desc      = "EVERYTHING! (except planes)",
    author    = "Google Frog",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetTeamUnits = Spring.GetTeamUnits
local spGetUnitDefID = Spring.GetUnitDefID

local team = Spring.GetMyTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings

-- What to hold ground with
local function IsGround(ud)
 return (not (ud.canFly or ud.isBuilding or (ud.builder and not ud.canMove and not ud.isFactory) ) )
end

-- Exceptions
local unitArray = { 

  "factoryplane",
  "factorygunship",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local unitSet = {}

function widget:Initialize() 

  for i, v in pairs(unitArray) do
    unitSet[v] = true
  end
  
end

--function widget:GameStart()


function widget:GameFrame(n)
  if (n == 1) then
  
    local units = spGetTeamUnits(team)
  
    for i, id in pairs(units) do
      widget:UnitCreated(id, spGetUnitDefID(id), team)
    end
  end
end

local function IsException(ud)
  
  for i, v in pairs(unitSet) do
    if (unitSet[ud.name]) then
	  return false
	end
  end
  
  return true
  
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam == team) then
    
	local ud = UnitDefs[unitDefID]
    if (ud ~= nil) then
  
      if IsException(ud) then
	    if IsGround(ud) then
	      spGiveOrderToUnit(unitID, CMD.MOVE_STATE, { 0 }, {})
		end
	  else
		spGiveOrderToUnit(unitID, CMD.MOVE_STATE, { 1 }, {})
      end
	
	  if ud.canFly then
	    spGiveOrderToUnit(unitID, CMD.AUTOREPAIRLEVEL, { 0 }, {})
	  end
	
	end
	
  end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
  spGiveOrderToUnit(unitID, CMD.ONOFF, { 1 }, { }) 
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


