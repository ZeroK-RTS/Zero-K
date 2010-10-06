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
local function GreaterEq25(a)   return a>=25; end
local function GreaterZero(a)   return a>0;   end
local function GreaterEqZero(a) return a>=0;  end
local function GreaterFour(a)   return a>4;   end
local function LessEqZero(a)    return a<=0;  end
local function IsCoreOrChicken(a) return a.chicken; end
backgrounds = {
--//chicken queen has air movementtype
  {check={name="chickenq"},                                  texture="LuaRules/Images/IconGenBkgs/bg_ground_rock.png"},

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
  {check={factions=IsCoreOrChicken,canHover=true},                                    texture="LuaRules/Images/IconGenBkgs/bg_hover_rock.png"},
  {check={factions=IsCoreOrChicken,floater=true,minWaterDepth=LessEqZero},            texture="LuaRules/Images/IconGenBkgs/bg_hover_rock.png"},
  {check={factions=IsCoreOrChicken,waterline=GreaterZero,minWaterDepth=LessEqZero},   texture="LuaRules/Images/IconGenBkgs/bg_hover_rock.png"},
  {check={canHover=true},                                    texture="LuaRules/Images/IconGenBkgs/bg_hover.png"},
  {check={floater=true,minWaterDepth=LessEqZero},            texture="LuaRules/Images/IconGenBkgs/bg_hover.png"},
  {check={waterline=GreaterZero,minWaterDepth=LessEqZero},   texture="LuaRules/Images/IconGenBkgs/bg_hover.png"},
--//subs
  {check={waterline=GreaterEq25,minWaterDepth=GreaterZero},  texture="LuaRules/Images/IconGenBkgs/bg_underwater.png"},
  {check={floater=false,minWaterDepth=GreaterFour},          texture="LuaRules/Images/IconGenBkgs/bg_underwater.png"},
--//sea
  {check={floater=true,minWaterDepth=GreaterZero},           texture="LuaRules/Images/IconGenBkgs/bg_water.png"},
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
  
  [UnitDefNames.corestor.id] = {
    rot = 0,
  },
  [UnitDefNames.corrad.id] = {
    scale = 3,
    rot   = 200,
    clamp = 10,
  },
  [UnitDefNames.corarad.id] = {
    scale = 3,
    rot   = 200,
    clamp = 10,
  },
  [UnitDefNames.armjamt.id] = {
    rot = -45,
  },
  [UnitDefNames.corsilo.id] = {
    clamp = 0,
  },
  [UnitDefNames.armmex.id] = {
    clamp = 2,
  },
  [UnitDefNames.corsh.id] = {
    clamp = 0,
  },
  [UnitDefNames.armsh.id] = {
    clamp = 0,
  },
  [UnitDefNames.armgeo.id] = {
    clamp = 0,
  },
  [UnitDefNames.armtl.id] = {
    clamp = 0,
  },
  [UnitDefNames.armamph.id] = {
    clamp = 0,
  },
  [UnitDefNames.armlab.id] = {
    clamp = 0,
  },
  [UnitDefNames.armrad.id] = {
    clamp = 10,
  },
  [UnitDefNames.armrl.id] = {
    clamp = 2,
  },
  [UnitDefNames.corrl.id] = {
    clamp = 2,
  },
  [UnitDefNames.corhlt.id] = {
    clamp = 2,
  },
  [UnitDefNames.armhlt.id] = {
    clamp = 4,
  },
  [UnitDefNames.armfav.id] = {
    border = 0.156,
  },
  [UnitDefNames.corfav.id] = {
    border = 0.156,
  },
  [UnitDefNames.chicken_dodo.id] = {
    border = 0.156,
  },
  [UnitDefNames.blastwing.id] = {
    border = 0.156,
  },
  [UnitDefNames.bladew.id] = {
    border = 0.125,
  },
  [UnitDefNames.armlab.id] = {
    border = 0.125,
  },
  [UnitDefNames.corgator.id] = {
    border = 0.125,
  },
  [UnitDefNames.armflea.id] = {
    border = 0.125,
  },


  [UnitDefNames.corsumo.id] = {
    unfold = true,
  },
  [UnitDefNames.corpyro.id] = {
    unfold = true,
  },
  [UnitDefNames.corstorm.id] = {
    unfold = true,
  },
  [UnitDefNames.core_spectre.id] = {
    unfold = true,
  },
  [UnitDefNames.corjamt.id] = {
    unfold = true,
  },
  	
  [UnitDefNames.armarch.id] = {
    unfold = true,
    attack = true,
    wait   = 120,
    clamp  = 0,
  },
  [UnitDefNames.tawf013.id] = {
    unfold = true,
    attack = true,
    shotangle = 45,
    wait   = 120,
  },

  [UnitDefNames.cormart.id] = {
    unfold = true,
    attack = true,
    shotangle = 45,
    wait   = 120,
  },

  [UnitDefNames.corak.id] = {
    unfold = true,
    attack = true,
    wait   = 120,
   },  
  [UnitDefNames.armpb.id] = {
    unfold = true,
    attack = true,
    wait   = 50,
  },
  [UnitDefNames.armspy.id] = {
    unfold = true,
  },
  [UnitDefNames.armafrad.id] = {
    unfold = true,
    wait   = 210,
  },
  [UnitDefNames.armanni.id] = {
    unfold = true,
  },
  [UnitDefNames.armarad.id] = {
    unfold = true,
    wait   = 225,
  },
  [UnitDefNames.armgmm.id] = {
    clamp  = 0,
    unfold = true,
  },
  [UnitDefNames.armsolar.id] = {
    unfold = true,
  },
  [UnitDefNames.armsnipe.id] = {
--    unfold = true,
--    attack = true,
  },
  [UnitDefNames.armzeus.id] = {
    unfold = true,
    attack = true,
  },
  [UnitDefNames.cormex.id] = {
    clamp  = 0,
    unfold = true,
    wait   = 300,
  },
  [UnitDefNames.corsolar.id] = {
    unfold = true,
  },
  [UnitDefNames.cordoom.id] = {
    unfold = true,
  },
  [UnitDefNames.cordoom2.id] = {
    unfold = true,
  },
  [UnitDefNames.core_egg_shell.id] = {
    unfold = true,
    attack = true,
    wait   = 6,
  },
  [UnitDefNames.corcrw.id] = {
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


  [UnitDefNames.chickenq.id] = {
    rot    = 29,
    angle  = 10,
    unfold = false,
  },
  [UnitDefNames.chickenbroodqueen.id] = {
    rot    = 29,
    angle  = 10,
    unfold = false,
  },
  [UnitDefNames.corkrog.id] = {
    rot    = 28,
    angle  = 10,
  },
  [UnitDefNames.corkarg.id] = {
    rot    = 28,
    angle  = 10,
    border = 0.09,
  },
  [UnitDefNames.armorco.id] = {
    rot    = 28,
    angle  = 10,
  },
  [UnitDefNames.armbanth.id] = {
    rot    = 28,
    angle  = 10,
    unfold = true,
  },
  [UnitDefNames.armraz.id] = {
    rot    = 28,
    angle  = 10,
    border = 0.09,
  },
  [UnitDefNames.screamer.id] = {
    rot    = 30,
    angle  = 30,
  },

  [UnitDefNames.arm_spider.id] = {
    scale    = 3,
    attempts = 10,
  },


  [UnitDefNames.fakeunit.id] = {
    empty  = true,
  },
  [UnitDefNames.fakeunit_aatarget.id] = {
    empty  = true,
  },--[[
  [UnitDefNames.rampup.id]     = { empty  = true },
  [UnitDefNames.rampdown.id]   = { empty  = true },
  [UnitDefNames.levelterra.id] = { empty  = true },
  [UnitDefNames.armblock.id]   = { empty  = true },
  [UnitDefNames.corblock.id]   = { empty  = true },
  [UnitDefNames.armtrench.id]  = { empty  = true },
  [UnitDefNames.cortrench.id]  = { empty  = true },]]--
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
