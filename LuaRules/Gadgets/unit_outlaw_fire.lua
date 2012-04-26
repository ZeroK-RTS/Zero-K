local versionNumber = "v0.1"

function gadget:GetInfo()
  return {
    name      = "Outlaw Fire",
    desc      = versionNumber .. " Makes Outlaw fire all the time, active state toggles",
    author    = "Jseah",
    date      = "8/3/12",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--include("LuaRules/Configs/customcmds.h.lua")

local cycletime = 30  --How fast this updates in number of frames

local TeamUnits          = Spring.GetTeamUnits
local GetUnitDefID       = Spring.GetUnitDefID
local FindUnitCmdDesc    = Spring.FindUnitCmdDesc
local GetUnitCmdDesc     = Spring.GetUnitCmdDescs
local UnitIsDead         = Spring.GetUnitIsDead
local GiveOrder          = Spring.GiveOrderToUnit
local GetUnitPosition    = Spring.GetUnitPosition
local Echo               = Spring.Echo
local count = cycletime
local outlaws = {}

function gadget:GameFrame()
  count = count - 1
  if count <= 0 then
    for unitID,_ in pairs(outlaws) do
	  if not UnitIsDead(unitID) and UnitIsDead(unitID) ~= nil then
        local x, y, z = GetUnitPosition(unitID)
        local cmdDescID = FindUnitCmdDesc(unitID, CMD.ONOFF)
        local cmdDesc = GetUnitCmdDesc(unitID, cmdDescID, cmdDescID)
        local nparams = cmdDesc[1].params
        if nparams[1] == '1' then
          GiveOrder(unitID, 34923, {x, y, z}, {})
        else
          GiveOrder(unitID, 34924, {x, y, z}, {})
        end
	  else
	    outlaws[unitID] = nil
	  end
    end
    count = cycletime
  end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  local ud = UnitDefs[unitDefID]
  if ud.name == "cormak" then
    outlaws[unitID] = true
  end
end

function gadget:Initialize()
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = GetUnitDefID(unitID)
    gadget:UnitCreated(unitID, unitDefID)
  end
end
