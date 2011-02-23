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

  spherepole = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },
  armsnipe = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },

  armcom = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },
  
  armadvcom = {
    draw   = true,
    init   = false,
    energy = 10,
    delay  = 30,
  },

  corcom = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },

  coradvcom = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },
  
  commrecon = {
    draw   = true,
    init   = false,
    energy = 10,
    delay  = 30,
  },

  commsupport = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },

  commadvsupport = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },
  
  armcomdgun = {
    draw   = true,
    init   = false,
    energy = 20,
    delay  = 30,
  },
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
