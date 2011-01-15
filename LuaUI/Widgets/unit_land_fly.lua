-- $Id: unit_land_fly.lua 3675 2009-01-04 06:38:19Z evil4zerggin $
local versionNumber = "v1.2.2"

function widget:GetInfo()
  return {
    name      = "Land Fly",
    desc      =  versionNumber .. " Sets air units to land or fly.",
    author    = "Evil4Zerggin",
    date      = "2 June 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

----------------------------------------------------------------
--config
----------------------------------------------------------------
local gunshipsFly = true
local transportsFly = false
local constructorsFly = false
local allFly = false
local cloakedAlwaysFly = true --only takes precedence when true

----------------------------------------------------------------
--helper functions
----------------------------------------------------------------
function ToBool(x)
  return x and x ~= "0" and x ~= 0
end

----------------------------------------------------------------
--speedups
----------------------------------------------------------------
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetMyTeamID = Spring.GetMyTeamID
local CMD_IDLEMODE = CMD.IDLEMODE
local CMD_INSERT = CMD.INSERT

local param = {0,CMD_IDLEMODE,0,0}
local opt   = {"alt"}

local idleFlyers = {}

----------------------------------------------------------------
--callins
----------------------------------------------------------------

function widget:Initialize() 
  for unitDefID, unitDef in pairs(UnitDefs) do
    if (unitDef.canFly) then
      idleFlyers[unitDefID] = (allFly)or
		(gunshipsFly and not(unitDef.isBomber or unitDef.isFighter) and ToBool(unitDef.weapons[1]))or
		(transportsFly and ToBool(unitDef.isTransport))or
		(constructorsFly and ToBool(unitDef.buildSpeed))or
		(cloakedAlwaysFly and ToBool(unitDef.canCloak))or
		(unitDef.name == "owl")
    end
  end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
  if (idleFlyers[unitDefID] and unitTeam == GetMyTeamID()) then
    --GiveOrderToUnit(unitID, CMD_INSERT, param, opt) doesn't work for no reason :<
    GiveOrderToUnit(unitID, CMD_IDLEMODE,{0},{"shift","alt"})
  end
end
