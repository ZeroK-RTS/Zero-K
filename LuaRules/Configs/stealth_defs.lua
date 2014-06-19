-- $Id: stealth_defs.lua 3496 2008-12-21 20:33:13Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local passiveStealth = {
	draw   = false,
    init   = false,
    energy = 0,
    delay  = 0,
	tieToCloak = true,
}

local stealthDefs = {

  corsktl = true,
  armspy = true,
  spherepole = true,
  armsnipe = true,
  armcomdgun = true,
  battledrone = true,
}

for name, _ in pairs(stealthDefs) do
	stealthDefs[name] = passiveStealth
end

-- for procedural comms - lazy hack
for name, ud in pairs(UnitDefNames) do
	if ud.customParams.cloakstealth then
		stealthDefs[name] = passiveStealth
	end
end

if (Spring.IsDevLuaEnabled()) then
  for k,v in pairs(UnitDefNames) do
    stealthDefs[k] = {
      init   = false,
      energy = v.metalCost * 0.05,
      draw   = true
    }
  end
end



return stealthDefs


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
