-- $Id: unit_windmill_control.lua 4120 2009-03-20 01:05:01Z carrepairer $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Windmill Control",
    desc      = "Controls windmill helix and overrides map wind settings",
    author    = "quantum",
    date      = "June 29, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-- Changelog:
-- 		CarRepairer: Enhanced to allow overriding map's min/max wind values in mod options. Negative values (default) will use map's values.


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- 
if (gadgetHandler:IsSyncedCode()) then
	
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local windDefs = {
  [ UnitDefNames['armwin'].id ] = true,
}

local windmills = {}
local groundMin, groundMax = 0,0
local groundExtreme = 0
local slope = 0

local windMin, windMax, windMin10, windMax10

local strength, next_strength, strength_step, step_count = 0,0,0,0


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- Speed-ups

local SetUnitCOBValue      = Spring.SetUnitCOBValue
local GetWind              = Spring.GetWind
local GetUnitDefID         = Spring.GetUnitDefID
local GetHeadingFromVector = Spring.GetHeadingFromVector
--local windMin              = Game.windMin*0.1
--local windMax              = Game.windMax*0.1
local AddUnitResource      = Spring.AddUnitResource
local GetUnitBasePosition  = Spring.GetUnitBasePosition
local GetUnitIsStunned     = Spring.GetUnitIsStunned
local SetUnitTooltip       = Spring.SetUnitTooltip
local sformat = string.format
local pi_2  = math.pi * 2
local fmod  = math.fmod
local atan2 = math.atan2
local rand = math.random

local function round(num, idp)
  return sformat("%." .. (idp or 0) .. "f", num)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


function gadget:GameFrame(n)
  if (((n+16) % 32) < 0.1) then
    if (n==48) then
	  local windMinStr = windMin .. ''
	  local windMaxStr = windMax .. ''
      Spring.SendMessage('Wind Range: '.. windMinStr:sub(1,5) ..' - '.. windMaxStr:sub(1,5) ..'. Max Windmill altitude bonus is: ' .. string.format('%.2f',slope)*100 .. '%' )
    end
    if (next(windmills)) then
      
	  if step_count > 0 then
		strength = strength + strength_step
		step_count = step_count - 1
	  end	  
	  local _, _, _, strength2, x, _, z = GetWind()
      local heading = GetHeadingFromVector(x, z) - 16384

	  local teamEnergy = {}
	  
      SetUnitCOBValue(next(windmills), 4096, heading)
      for unitID, entry in pairs(windmills) do
        local de = (windMax - strength)*entry[1].alt + strength
        local paralyzed = GetUnitIsStunned(unitID)
        local speed = 0
        if (not paralyzed) then
          local tid = entry[2]
		  teamEnergy[tid] = (teamEnergy[tid] or 0) + de -- monitor team energy
		  AddUnitResource(unitID, "e", de)
          speed = de * COBSCALE 
        end
    
        SetUnitCOBValue(unitID, 1024, speed)
      end
	  
	  for teamID, energy in pairs(teamEnergy) do 
		SendToUnsynced("SendWindProduction", teamID, energy)   
	  
	  end 
    end
  end
  
    
	if (windMin10 < windMax10) and (((n+16) % (32*30)) < 0.1) then
		next_strength = rand(windMin10, windMax10) / 10
		strength_step = (next_strength - strength) * 0.1
		step_count = 10
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function SetupUnit(unitID,unitDefID, teamID)
  local scriptIDs = {}

  local _, y = GetUnitBasePosition(unitID)
  if (groundMax<=0) then
    scriptIDs.alt = 0.0
  else
    local altitude = (y - groundMin)/groundExtreme
    scriptIDs.alt = altitude*slope
  end

  local unitDef   = UnitDefs[unitDefID]
  Spring.SetUnitRulesParam(unitID,"minWind",windMin+(windMax-windMin)*scriptIDs.alt, {inlos = true})
  SetUnitTooltip(unitID, --Spring.GetUnitTooltip(unitID)..
    unitDef.humanName .. " - " .. unitDef.tooltip ..
    " (E " .. round(windMin+(windMax-windMin)*scriptIDs.alt,1) .. "-" .. round(windMax,1) .. ")"
  )
  windmills[unitID] = {scriptIDs, teamID}

  --// initialize spinning
  --local _, _, _, strength = GetWind()
  local de = (windMax - strength)*scriptIDs.alt + strength
  local paralyzed = GetUnitIsStunned(unitID)
  local speed = 0
  if (not paralyzed) then
    speed = de * COBSCALE * 0.1
  end
  SetUnitCOBValue(unitID, 1024, speed)
end


function gadget:Initialize()
	windMin = Game.windMin*0.1
	windMax = Game.windMax*0.1
	
	if Spring.GetModOptions() then
		local moWindMin = tonumber(Spring.GetModOptions().minwind or -1)	
		local moWindMax = tonumber(Spring.GetModOptions().maxwind or -1)	
		
		windMin = moWindMin >= 0 and moWindMin or windMin
		windMax = moWindMax >= 0 and moWindMax or windMax
		
		windMin = windMin < windMax and windMin or windMax
	end
	windMin10 = windMin * 10
	windMax10 = windMax * 10

  Spring.SetGameRulesParam("WindMin",windMin)
  Spring.SetGameRulesParam("WindMax",windMax)
	
  groundMin, groundMax = Spring.GetGroundExtremes()
  groundMin, groundMax = math.max(groundMin,0), math.max(groundMax,1)
  groundExtreme = groundMax - groundMin

  --this is a function defined between 0 and 1, so we can adjust the gadget 
  -- effect between 0% (flat maps) and 100% (mountained maps)
  slope = 1/(1+math.exp(4 - groundExtreme/105))

  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    if (windDefs[unitDefID]) then
      SetupUnit(unitID,unitDefID, Spring.GetUnitTeam(unitID))
    end
  end
  strength = windMax
  if windMin10 < windMax10 then
	strength = rand(windMin10, windMax10) / 10
  end
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  if (windDefs[unitDefID]) then
    SetupUnit(unitID,unitDefID, unitTeam)
  end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, unitTeam)
  if (windDefs[unitDefID]) then 
    SetupUnit(unitID,unitDefID, unitTeam)
  end
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  if (windDefs[unitDefID]) then 
    windmills[unitID] = nil
  end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- UNSYNCED SHIT 
-------------------------------------------------------------------------------------
else 	

function gadget:Initialize() 
	gadgetHandler:AddSyncAction("SendWindProduction",SendWindProduction)
end 

function SendWindProduction(_, teamID, wind) 
  if (teamID ~= Spring.GetLocalTeamID()) then return end
  if (Script.LuaUI('SendWindProduction')) then
    Script.LuaUI.SendWindProduction(teamID, wind)
  end
end


	
end


