-- $Id: icon_generator.lua 4354 2009-04-11 14:32:28Z licho $
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--
--  Icon Generator Config File
--

--// Info
if (info) then
  local ratios      = {["5to4"]=(4/5)} --{["16to10"]=(10/16), ["1to1"]=(1/1), ["5to4"]=(4/5)} --, ["4to3"]=(3/4)}
  local resolutions = {{64,64}} --{{128,128},{64,64}}
  local schemes     = {""}

  return schemes,resolutions,ratios
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// filename ext
imageExt = ".png"

--// render into a fbo in 4x size
renderScale = 4

--// faction colors (check (and needs) LuaRules/factions.lua)
factionTeams = {
  arm     = 0,   --// arm
  core    = 1,   --// core
  chicken = 2,   --// chicken
  unknown = 2,   --// unknown
}
factionColors = {
  arm     = {0.05, 0.96, 0.95},   --// arm
  core    = {0.05, 0.96, 0.95},   --// core
  chicken = {1.0,0.8,0.2},   --// chicken
  unknown = {0.05, 0.96, 0.95},   --// unknown
}


-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// render options textured
textured = (scheme~="bw")
lightAmbient = {1.1,1.1,1.1}
lightDiffuse = {0.4,0.4,0.4}
lightPos     = {-0.2,0.4,0.5}

--// Ambient Occlusion & Outline settings
aoPower     = ((scheme=="bw") and 1.5) or 1
aoContrast  = ((scheme=="bw") and 2.5) or 1
aoTolerance = 0
olContrast  = ((scheme=="bw") and 5) or 10
olTolerance = 0

--// halo (white)
halo  = false --(scheme~="bw")


-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// backgrounds
background = true
local function Greater30(a)     return a>30;  end
local function GreaterEq15(a)   return a>=15; end
local function GreaterZero(a)   return a>0;   end
local function GreaterEqZero(a) return a>=0;  end
local function GreaterFour(a)   return a>4;   end
local function LessEqZero(a)    return a<=0;  end
local function IsCoreOrChicken(a)
	if a then return a.chicken
	else return false end
end
local function IsHover(a)
	return a and a.name and string.find(a.name, "hover") ~= nil
end
backgrounds = {
--// stuff that needs hardcoding
  {check={name="shipcarrier"}, texture="LuaRules/Images/IconGenBkgs/bg_water.png"},

  
--[[terraforms
  {check={name="rampup"},                                    texture="LuaRules/Images/IconGenBkgs/rampup.png"},
  {check={name="rampdown"},                                  texture="LuaRules/Images/IconGenBkgs/rampdown.png"},
  {check={name="levelterra"},                                texture="LuaRules/Images/IconGenBkgs/level.png"},
  {check={name="armblock"},                                  texture="LuaRules/Images/IconGenBkgs/block.png"},
  {check={name="corblock"},                                  texture="LuaRules/Images/IconGenBkgs/block.png"},
  {check={name="armtrench"},                                 texture="LuaRules/Images/IconGenBkgs/trench.png"},
  {check={name="cortrench"},                                 texture="LuaRules/Images/IconGenBkgs/trench.png"},
]]--
--//air
  {check={canFly=true},                                      texture="LuaRules/Images/IconGenBkgs/bg_air.png"},
--//hovers
  {check={factions=IsCoreOrChicken,moveDef=IsHover},            texture="LuaRules/Images/IconGenBkgs/bg_hover_rock.png"},
  {check={moveDef=IsHover},            texture="LuaRules/Images/IconGenBkgs/bg_hover.png"},
--//subs
  {check={waterline=GreaterEq15,minWaterDepth=GreaterZero},  texture="LuaRules/Images/IconGenBkgs/bg_underwater.png"},
  {check={floatOnWater=false,minWaterDepth=GreaterFour},          texture="LuaRules/Images/IconGenBkgs/bg_underwater.png"},
--//sea
  {check={floatOnWater=true,minWaterDepth=GreaterZero},           texture="LuaRules/Images/IconGenBkgs/bg_water.png"},
--//amphibous
  {check={factions=IsCoreOrChicken,maxWaterDepth=Greater30,minWaterDepth=LessEqZero}, texture="LuaRules/Images/IconGenBkgs/bg_amphibous_rock.png"},
  {check={maxWaterDepth=Greater30,minWaterDepth=LessEqZero}, texture="LuaRules/Images/IconGenBkgs/bg_amphibous.png"},
--//ground
  {check={factions=IsCoreOrChicken},                         texture="LuaRules/Images/IconGenBkgs/bg_ground_rock.png"},
  {check={},                                                 texture="LuaRules/Images/IconGenBkgs/bg_ground.png"},
}


-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// default settings for rendering
--//zoom   := used to make all model icons same in size (DON'T USE, it is just for auto-configuration!)
--//offset := used to center the model in the fbo (not in the final icon!) (DON'T USE, it is just for auto-configuration!)
--//rot    := facing direction
--//angle  := topdown angle of the camera (0 degree = frontal, 90 degree = topdown)
--//clamp  := clip everything beneath it (hide underground stuff)
--//scale  := render the model x times as large and then scale down, to replaces missing AA support of FBOs (and fix rendering of very tine structures like antennas etc.))
--//unfold := unit needs cob to unfolds
--//move   := send moving cob events (works only with unfold)
--//attack := send attack cob events (works only with unfold)
--//shotangle := vertical aiming, useful for arties etc. (works only with unfold+attack)
--//wait   := wait that time in gameframes before taking the screenshot (default 300) (works only with unfold)
--//border := free space around the final icon (in percent/100)
--//empty  := empty model (used for fake units in CA)
--//attempts := number of tries to scale the model to fit in the icon

defaults = {border=0.05, angle=45, rot="right", clamp=-10000, scale=1.5, empty=false, attempts=10, wait=120, zoom=1.0, offset={0,0,0},};


-----------------------------------------------------------------------
-----------------------------------------------------------------------

--// per unitdef settings
unitConfigs = {
  
  [UnitDefNames.staticradar.id] = {
    scale = 3,
    rot   = 200,
    clamp = 10,
  },
  [UnitDefNames.staticjammer.id] = {
    rot = -45,
  },
  [UnitDefNames.staticnuke.id] = {
    clamp = 0,
  },
  [UnitDefNames.hoverraid.id] = {
    clamp = 0,
  },
  [UnitDefNames.turretmissile.id] = {
    clamp = 2,
  },
  [UnitDefNames.turretheavylaser.id] = {
    clamp = 2,
  },
  [UnitDefNames.vehscout.id] = {
    border = 0.156,
  },
  [UnitDefNames.gunshipbomb.id] = {
    border = 0.156,
  },
  [UnitDefNames.gunshipemp.id] = {
    border = 0.125,
  },
  [UnitDefNames.vehraid.id] = {
    border = 0.125,
  },
  [UnitDefNames.spiderscout.id] = {
    border = 0.125,
  },


  [UnitDefNames.jumpsumo.id] = {
    unfold = true,
  },
  [UnitDefNames.jumpraid.id] = {
    unfold = true,
  },
  [UnitDefNames.shieldskirm.id] = {
    unfold = true,
  },
  [UnitDefNames.shieldshield.id] = {
    unfold = true,
  },
  [UnitDefNames.staticshield.id] = {
    unfold = true,
  },
  	
  [UnitDefNames.tankarty.id] = {
    unfold = true,
    attack = true,
    shotangle = 45,
    wait   = 120,
  },
  [UnitDefNames.shieldraid.id] = {
    unfold = true,
    attack = true,
    wait   = 120,
   },
  [UnitDefNames.turretgauss.id] = {
    unfold = true,
    attack = true,
    wait   = 50,
  },
  [UnitDefNames.spiderantiheavy.id] = {
    unfold = true,
  },
  [UnitDefNames.turretantiheavy.id] = {
    unfold = true,
  },
  [UnitDefNames.staticheavyradar.id] = {
    unfold = true,
    wait   = 225,
  },
  [UnitDefNames.energysolar.id] = {
    unfold = true,
  },
  [UnitDefNames.cloaksnipe.id] = {
--    unfold = true,
--    attack = true,
  },
  [UnitDefNames.cloakassault.id] = {
    unfold = true,
    attack = true,
  },
  [UnitDefNames.hoverdepthcharge.id] = {
    unfold = true,
  },
  [UnitDefNames.cloakjammer.id] = {
    unfold = true,
    wait   = 100,
  },
  [UnitDefNames.staticmex.id] = {
    clamp  = 0,
    unfold = true,
    wait   = 600,
  },
  [UnitDefNames.turretheavy.id] = {
    unfold = true,
  },
  [UnitDefNames.gunshipkrow.id] = {
    unfold = true,
  },
  [UnitDefNames.chickenf.id] = {
    unfold = true,
    wait   = 190,
  },
  [UnitDefNames.chicken_pigeon.id] = {
    border = 0.11,
  },

  [UnitDefNames.chicken_dodo.id] = {
    border = defaults.border,
  },

  [UnitDefNames.chickenbroodqueen.id] = {
    rot    = 29,
    angle  = 10,
    unfold = false,
  },
  [UnitDefNames.striderdetriment.id] = {
    rot    = 20,
    angle  = 10,
  },
  [UnitDefNames.striderbantha.id] = {
    rot    = 28,
    angle  = 10,
    unfold = true,
  },
  [UnitDefNames.striderdante.id] = {
    rot    = 28,
    angle  = 10,
  },
  [UnitDefNames.nebula.id] = {
    rot    = 28,
    angle  = 10,
  },
  [UnitDefNames.turretaaheavy.id] = {
    rot    = 30,
    angle  = 30,
  },
  [UnitDefNames.spiderassault.id] = {
    unfold = true,
  },
  [UnitDefNames.amphlaunch.id] = {
    unfold = true,
  },
  [UnitDefNames.spidercon.id] = {
    scale    = 3,
    attempts = 10,
  },
  [UnitDefNames.commrecon1.id] = {
    unfold = true,
    --attack = true,
  },
  [UnitDefNames.commsupport1.id] = {
	unfold = true,
    --attack = true,
  },
  [UnitDefNames.zenith.id] = {
    wait   = 50,
  },
  [UnitDefNames.fakeunit.id] = {
    empty  = true,
  },
  [UnitDefNames.fakeunit_aatarget.id] = {
    empty  = true,
  },
  [UnitDefNames.fakeunit_los.id] = {
    empty  = true,
  },
  [UnitDefNames.wolverine_mine.id] = {
    unfold  = true,
    wait = 60,
  },
  [UnitDefNames.hovercon.id] = {
    unfold  = true,
    wait = 60,
  },
}

for i=1,#UnitDefs do
  if (UnitDefs[i].canFly) then
    if (unitConfigs[i]) then
      if (unitConfigs[i].unfold ~= false) then
        unitConfigs[i].unfold = true
        unitConfigs[i].move   = true
      end
    else
      unitConfigs[i] = {unfold = true, move = true}
    end
  elseif (UnitDefs[i].canKamikaze) then
    if (unitConfigs[i]) then
      if (not unitConfigs[i].border) then
        unitConfigs[i].border = 0.156
      end
    else
      unitConfigs[i] = {border = 0.156}
    end
  end
end
