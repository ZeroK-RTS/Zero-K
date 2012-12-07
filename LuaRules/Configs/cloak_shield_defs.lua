-- $Id: cloak_shield_defs.lua 4643 2009-05-22 05:52:27Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--Modified by Evil4Zerggin

--
--  Cloak Levels
--
--  0:  disabled
--  1:  conditionally enabled, uses energy
--  2:  conditionally enabled, does no use energy
--  3:  enabled, unless stunned
--  4:  always enabled
--

-- decloakDistance: Units cloaked by the cloaker have this decloakdistance. Use false to use the unit's own decloak distance (typically 0)


local function JammerAlign(defName)
  local ud = UnitDefNames[defName]
  if (ud == nil) then return 0 end
  local jamRad = ud.jammerRadius
  return 64 * math.floor(jamRad / 64)
end

local function GetUnitDecloakDistance(defName)
  local ud = UnitDefNames[defName]
  if (ud == nil) then return 0 end
  local decloakDist = ud.decloakDistance
  return 64 * math.floor(decloakDist / 64)
end

local cloakShieldDefs = {
  armjamt = {
    init = true,
    draw = true,
    energy = 12,
    maxrad = JammerAlign('armjamt'),
    growRate = 512,
    shrinkRate = 2048,
    selfCloak = true,
    decloakDistance = 300,
  },
  spherecloaker = {
    init = true,
    draw = true,
    energy = 15,
    maxrad = JammerAlign('spherecloaker'),
    growRate = 512,
    shrinkRate = 2048,
    selfCloak = true,
    decloakDistance = 300,
  },
}

-- reads from customParams and copies to cloakShieldDefs as appropriate - needed for procedurally generated comms
-- as always, need better way to handle if upgrades are desired!
local presets = {
  module_cloakfield = {
    init = true,
    draw = true,
    energy = 12,
    maxrad = 350,
    growRate = 512,
    shrinkRate = 2048,
    selfCloak = true,
    decloakDistance = 300,
  },
}

for name, ud in pairs(UnitDefNames) do
	if ud.customParams.cloakshield_preset then
		cloakShieldDefs[name] = Spring.Utilities.CopyTable(presets[ud.customParams.cloakshield_preset])
	end
end

if (Spring.IsDevLuaEnabled()) then
  for name, ud in pairs(UnitDefNames) do
    if (cloakShieldDefs[name] == nil) then
      cloakShieldDefs[name] = {
        init   = false,
        energy = 1024, --v.metalCost / 10,
        draw   = true,
        minrad = 50,
        maxrad = 256,
        growRate = 256,
        shrinkRate = 1024,
        selfCloak = false,
        decloakDistance = false,
        level = 4,
      }
    end
  end
end

local uncloakables = {}

for k,v in pairs(UnitDefNames) do
  if (v.customParams.cannotcloak) then
    uncloakables[k] = true
  end
end


return cloakShieldDefs, uncloakables


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
