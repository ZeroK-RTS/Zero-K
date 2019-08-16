-- $Id: icontypes.lua 4585 2009-05-09 11:15:01Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    icontypes.lua
--  brief:   icontypes definitions
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--This file is used by engine, it's just placed here so LuaUI can access it too
--------------------------------------------------------------------------------

local icontypes = {
  default = {
    size=1.3,
    radiusadjust=1,
  },
  
  none = {
    size=0,
    radiusadjust=0,
  },
  
-- commanders
  commander0 = {
    bitmap='icons/armcommander.dds',
    size=1.9,
  },
  commander1 = {
    bitmap='icons/armcommander.dds',
    size=2,
  },
  commander2 = {
    bitmap='icons/armcommander.dds',
    size=2.2,
  },
  commander3 = {
    bitmap='icons/armcommander.dds',
    size=2.4,
  },
  commander4 = {
    bitmap='icons/armcommander.dds',
    size=2.6,
  },
  commander5 = {
    bitmap='icons/armcommander.dds',
    size=2.8,
  },

  corcommander = {
    bitmap='icons/corcommander.dds',
    size=2,
  },

  krogoth = {
    bitmap='icons/krogoth.dds',
    size=3,
  },

  air = {
    bitmap='icons/air.dds',
    size=1.2,
  },

  sea = {
    bitmap='icons/sea.dds',
    size=1.5,
  },

  building = {
    bitmap='icons/building.dds',
    radiusadjust=1,
    size=0.8,
  },

  --------------------------------------------------------------------------------
  -- LEGACY
  --------------------------------------------------------------------------------
  kbot = {
    bitmap='icons/bomb.dds',
    size=1.5,
  },
  assaultkbot = {
    bitmap='icons/t3generic.dds',
    size=1.8,
  },
  tank = {
    bitmap='icons/tank.dds',
    size=1.5,
  },
  heavytank = {
    bitmap='icons/riot.dds',
    size=2.0,
  },

  --long-range missiles such as Merls and Dominators - use cruisemissile now
  lrm = {
    bitmap='icons/lrm.dds',
    size=1.8,
  },
  scout = {
    bitmap='icons/scout.dds',
    size=1.5,
  },
  fixedarty = {
    bitmap='icons/fixedarty.dds',
    size=1.8,
  },
  mobilearty = {
    bitmap='icons/mobilearty.dds',
    size=1.8,
  },
  fixedaa = {
    bitmap='icons/fixedaa.dds',
    size=1.8,
  },
  mobileaa = {
    bitmap='icons/mobileaa.dds',
    size=1.8,
  },

  --kamikaze!
  bomb = {
    bitmap='icons/bomb.dds',
    size=1.6,
  },

  --------------------------------------------------------------------------------
  -- CURRENT ICONS
  --------------------------------------------------------------------------------

  --kbots
  kbotjammer = {
    bitmap='icons/kbotjammer.dds',
    size=2.0,
  },
  kbotshield = {
    bitmap='icons/kbotshield.dds',
    size=1.8,
  },
  kbotradar = {
    bitmap='icons/kbotradar.dds',
    size=1.8,
  },
  kbotraider = {
    bitmap='icons/kbotraider.dds',
    size=1.8,
  },
  kbotscythe = {
    bitmap='icons/kbotscythe.dds',
    size=1.8,
  },
  kbotassault = {
    bitmap='icons/kbotassault.dds',
    size=2,
  },
  kbotskirm = {
    bitmap='icons/kbotskirm.dds',
    size=1.8,
  },
  kbotriot = {
    bitmap='icons/kbotriot.dds',
    size=1.8,
  },
  kbotarty = {
    bitmap='icons/kbotarty.dds',
    size=1.8,
  },
  kbotlrarty = {
    bitmap='icons/kbotlrarty.dds',
    size=1.8,
  },
  kbotlrm = {
    bitmap='icons/kbotlrm.dds',
    size=1.8,
  },
  kbotaa = {
    bitmap='icons/kbotaa.dds',
    size=1.8,
  },
  kbotscout = {
    bitmap='icons/kbotscout.dds',
    size=1.8,
  },
  --puppy
  kbotbomb = {
    bitmap='icons/kbotbomb.dds',
    size=1.8,
  },

  --vehicles
  vehicleshield = {
    bitmap='icons/vehicleshield.dds',
    size=1.8,
  },
  vehiclejammer = {
    bitmap='icons/vehiclejammer.dds',
    size=1.8,
  },
  vehicleradar = {
    bitmap='icons/vehicleradar.dds',
    size=1.8,
  },
  vehiclegeneric = {
    bitmap='icons/vehiclegeneric.dds',
    size=1.8,
  },
  vehiclescout = {
    bitmap='icons/vehiclescout.dds',
    size=1.8,
  },
  vehicleraider = {
    bitmap='icons/vehicleraider.dds',
    size=1.8,
  },
  vehicleassault = {
    bitmap='icons/vehicleassault.dds',
    size=1.8,
  },
  vehicleskirm = {
    bitmap='icons/vehicleskirm.dds',
    size=1.8,
  },
  vehiclesupport = {
    bitmap='icons/vehiclesupport.dds',
    size=1.8,
  },
  vehicleaa = {
    bitmap='icons/vehicleaa.dds',
    size=1.8,
  },
  vehicleriot = {
    bitmap='icons/vehicleriot.dds',
    size=1.8,
  },
  vehiclearty = {
    bitmap='icons/vehiclearty.dds',
    size=1.8,
  },
  vehiclespecial = {
    bitmap='icons/vehiclespecial.png',
    size=2.1,
  },
  vehiclelrarty = {
    bitmap='icons/vehiclelrarty.dds',
    size=2.2,
  },
  vehicleaa = {
    bitmap='icons/vehicleaa.dds',
    size=1.8,
  },

  --walkers
  walkerjammer = {
    bitmap='icons/walkerjammer.dds',
    size=2,
  },
  walkershield = {
    bitmap='icons/walkershield.dds',
    size=2,
  },
  walkerraider = {
    bitmap='icons/walkerraider.dds',
    size=1.6,
  },
  walkerassault = {
    bitmap='icons/walkerassault.dds',
    size=1.7,
  },
  walkerskirm = {
    bitmap='icons/walkerskirm.dds',
    size=1.7,
  },
  walkerriot = {
    bitmap='icons/walkerriot.dds',
    size=1.6,
  },
  walkerarty = {
    bitmap='icons/walkerarty.dds',
    size=1.6,
  },
  walkerlrarty = {
    bitmap='icons/walkerlrarty.dds',
    size=2,
  },
  walkeraa = {
    bitmap='icons/walkeraa.dds',
    size=1.6,
  },
  walkerscout = {
    bitmap='icons/walkerscout.dds',
    size=2,
  },
  --roach
  walkerbomb = {
    bitmap='icons/walkerbomb.png',
	distance=0.5,
    size=1.8,
  },
  walkersupport = {
    bitmap='icons/walkersupport.png',
    size=2,
  },

  -- amphibious
  amphraider = {
    bitmap='icons/amphraider.png',
    size=1.9,
  },
  amphtorpraider = {
    bitmap='icons/amphtorpraider.png',
    size=1.9,
  },
  amphskirm = {
    bitmap='icons/amphskirm.png',
    size=1.8,
  },
  amphassault = {
    bitmap='icons/amphassault.png',
    size=2.6,
  },
  amphaa = {
    bitmap='icons/amphaa.png',
    size=1.8,
  },
  amphtorpriot = {
    bitmap='icons/amphtorpriot.png',
    size=2.2,
  },
  amphtorpassault = {
    bitmap='icons/amphtorpriot.png',
    size=2.6,
  },
  amphbomb = {
	bitmap='icons/amphbomb.png',
    size=1.9,
  },
  ampharty = {
	bitmap='icons/torparty.png',
    size=2,
  },
  amphtransport = {
    bitmap='icons/amphtransport.png',
    size=2.2,
  },
  
  --t2 vehicles (aka tanks)
  tankantinuke = {
    bitmap='icons/tankantinuke.dds',
    size=2.8,
  },
  tankassault = {
    bitmap='icons/tankassault.dds',
    size=2.0,
  },
  tankskirm = {
    bitmap='icons/tankskirm.dds',
    size=2.3,
  },
  tankriot = {
    bitmap='icons/tankriot.dds',
    size=2.0,
  },
  tankraider = {
    bitmap='icons/tankraider.dds',
    size=2.0,
  },
  tankarty = {
    bitmap='icons/tankarty.dds',
    size=2.0,
  },
  tanklrarty = {
    bitmap='icons/tanklrarty.dds',
    size=2.2,
  },
  tanklrm = {
    bitmap='icons/tanklrm.dds',
    size=2.0,
  },
  tankaa = {
    bitmap='icons/tankaa.dds',
    size=2.0,
  },
  tankscout = {
    bitmap='icons/tankscout.dds',
    size=2.0,
  },


  --hover
  hoverraider = {
    bitmap='icons/hoverraider.dds',
    size=1.8,
  },
  hoverassault = {
    bitmap='icons/hoverassault.dds',
    size=1.8,
  },
  hoverskirm = {
    bitmap='icons/hoverskirm.dds',
    size=1.8,
  },
  hoverspecial = {
    bitmap='icons/hoverspecial.png',
    size=1.8,
  },
  hoverriot = {
    bitmap='icons/hoverriot.dds',
    size=1.8,
  },
  hoverarty = {
    bitmap='icons/hoverarty.dds',
    size=1.8,
  },
  hoveraa = {
    bitmap='icons/hoveraa.dds',
    size=1.8,
  },
  hovertransport = {
    bitmap='icons/hovertransport.dds',
    size=1.8,
  },

  --spider
  spiderantinuke = {
    bitmap='icons/spiderantinuke.dds',
    size=2.8,
  },
  spidergeneric = {
    bitmap='icons/spidergeneric.dds',
    size=1.8,
  },
  spiderscout = {
    bitmap='icons/spiderscout.dds',
	distance=0.75,
    size=1.7,
  },
  spiderraider = {
    bitmap='icons/spiderraider.dds',
    size=1.8,
  },
  spiderskirm = {
    bitmap='icons/spiderskirm.dds',
    size=1.8,
  },
  spiderriot = {
    bitmap='icons/spiderriot.dds',
    size=1.8,
  },
  spiderriotspecial = {
    bitmap='icons/spiderriotspecial.png',
    size=1.8,
  },
  spiderassault = {
    bitmap='icons/spiderassault.dds',
    size=1.8,
  },
  spiderarty = {
    bitmap='icons/spiderarty.dds',
    size=1.8,
  },
  spideraa = {
    bitmap='icons/spideraa.dds',
    size=1.8,
  },
  spidersupport = {
    bitmap='icons/spidersupport.dds',
    size=2.4,
  },
  spiderspecialscout = {
    bitmap='icons/spiderspecialscout.dds',
    size=2,
  },
  --tick
  spiderbomb = {
    bitmap='icons/spiderbomb.dds',
	distance=0.5,
    size=1.8,
  },
  
  --jumper
  jumpjetgeneric = {
    bitmap='icons/jumpjetgeneric.dds',
    size=1.8,
  },
  jumpjetaa = {
    bitmap='icons/jumpjetaa.dds',
    size=1.8,
  },
  jumpjetassault = {
    bitmap='icons/jumpjetassault.dds',
    size=1.8,
  },
  --skuttle
  jumpjetbomb = {
    bitmap='icons/jumpjetbomb.dds',
	distance=0.5,
    size=1.8,
  },
  jumpjetraider = {
    bitmap='icons/jumpjetraider.dds',
    size=1.8,
  },
  jumpjetriot = {
    bitmap='icons/jumpjetriot.dds',
    size=1.8,
  },
  kbotwideriot = {
    bitmap='icons/kbotwideriot.png',
    size=2,
  },
  
  
  -- fatbots (jumpers that don't jump)
  fatbotarty = {
    bitmap='icons/fatbotarty.png',
    size=2.1,
  },
  fatbotsupport = {
    bitmap='icons/fatbotsupport.png',
    size=1.8,
  },
  
  --striders (aka tier 3)
  t3riot = {
    bitmap='icons/t3riot.dds',
    size=2.6,
  },
  t3generic = {
    bitmap='icons/t3generic.dds',
    size=2.9,
  },
  t3genericbig = {
    bitmap='icons/t3generic.dds',
    size=3,
  },
  t3special = {
    bitmap='icons/t3special.png',
    size=2.7,
  },
  t3spiderbuilder = {
    bitmap='icons/t3spiderbuilder.png',
    size=2.7,
  },
  t3arty = {
    bitmap='icons/t3arty.dds',
    size=2.7,
  },
  t3skirm = {
    bitmap='icons/t3skirm.dds',
    size=2.7,
  },
  
  t3spiderriot = {
    bitmap='icons/t3spiderriot.png',
    size=2.4,
  },
  t3spidergeneric = {
    bitmap='icons/t3spidergeneric.png',
    size=2.7,
  },
  
  t3jumpjetriot = {
    bitmap='icons/t3jumpjetriot.png',
    size=2.4,
  },

  
  --icon for construction units and field engineers
  builder = {
    bitmap='icons/builder.dds',
    size=1.8,
  },
  amphbuilder = {
    bitmap='icons/amphbuilder.png',
    size=1.8,
  },
  hoverbuilder = {
    bitmap='icons/hoverbuilder.png',
    size=1.8,
  },
  jumpjetbuilder = {
    bitmap='icons/jumpjetbuilder.png',
    size=1.8,
  },
  kbotbuilder = {
    bitmap='icons/kbotbuilder.png',
    size=1.8,
  },
  shipbuilder = {
    bitmap='icons/shipbuilder.png',
    size=1.8,
  },
  shipbuilder_alt = {
    bitmap='icons/shipbuilder_alt.png',
    size=2.2,
  },
  spiderbuilder = {
    bitmap='icons/spiderbuilder.png',
    size=1.8,
  },
  tankbuilder = {
    bitmap='icons/tankbuilder.png',
    size=1.8,
  },
  vehiclebuilder = {
    bitmap='icons/vehiclebuilder.png',
    size=1.8,
  },
  walkerbuilder = {
    bitmap='icons/walkerbuilder.png',
    size=1.8,
  },
  builderair = {
    bitmap='icons/builderair.dds',
    size=1.8,
  },
  t3builder = {
    bitmap='icons/t3builder.dds',
    size=2,
  },
  staticbuilder = {
    bitmap='icons/staticbuilder.dds',
    size=1,
  },
  t3hub = {
    bitmap='icons/t3hub.dds',
    size=2.4,
  },
  
  --defense
  defenseshield = {
    bitmap='icons/defenseshield.dds',
    size=2.0,
  },
  defense = {
    bitmap='icons/defense.dds',
    size=2.0,
  },
  defensetorp = {
    bitmap='icons/defensetorp.png',
    size=2.0,
  },
  defenseskirm = {
    bitmap='icons/defenseskirm.dds',
    size=2.0,
  },
  defenseheavy = {
    bitmap='icons/defenseheavy.dds',
    size=2.0,
  },
  defenseriot = {
    bitmap='icons/defenseriot.dds',
    size=2.0,
  },
  defensesupport = {
    bitmap='icons/defensesupport.png',
    size=2.0,
  },
  defenseraider = {
    bitmap='icons/defenseraider.dds',
    size=2.0,
  },
  defenseaa = {
    bitmap='icons/defenseaa.dds',
    size=2.0,
  },
  defenseskirmaa = {
    bitmap='icons/defenseskirmaa.png',
    size=2.0,
  },
  defensespecial = {
    bitmap='icons/defensespecial.dds',
    size=2.0,
  },

  staticjammer = {
    bitmap='icons/staticjammer.dds',
    size=2.0,
  },
  staticshield = {
    bitmap='icons/staticshield.dds',
    size=2.0,
  },
  statictransport = {
    bitmap='icons/statictransport.png',
    size=1.4,
  },
  staticaa = {
    bitmap='icons/staticaa.dds',
    size=2.0,
  },
  staticskirmaa = {
    bitmap='icons/staticskirmaa.png',
    size=2.0,
  },
  staticarty = {
    bitmap='icons/staticarty.dds',
    size=2.2,
  },
  staticbomb = {
    bitmap='icons/staticbomb.dds',
    size=2.0,
  },
  heavysam = {
    bitmap='icons/heavysam.dds',
    size=2.2,
  },

  --covers LRPC ships as well as statics
  lrpc = {
    bitmap='icons/lrpc.dds',
    size=2.4,
  },

  radar = {
    bitmap='icons/radar.dds',
    size=2,
  },
  advradar = {
    bitmap='icons/radar.dds',
    size=2.8,
  },
   sonar = {
    bitmap='icons/sonar.dds',
    size=2,
  },
  
  --now only covers snipers
  sniper = {
    bitmap='icons/sniper.dds',
    size=2.4,
  },
  --Pole Bot
  stealth = {
    bitmap='icons/sniper.dds',
    size=1.6,
  },
  
  --clogger icon
  clogger = {
    bitmap='icons/clogger.dds',
    size=2,
  },
  
  --Lucifer
  fixedtachyon = {
    bitmap='icons/fixedtachyon.dds',
    size=2,
  },
  
  -- DDM
  staticassaultriot = {
    bitmap='icons/staticassaultriot.png',
    size=2,
  },
  
  -- Sunlance
  staticassault = {
    bitmap='icons/staticassault.png',
    size=1.8,
  },
  
  --Lance
  mobiletachyon = {
    bitmap='icons/mobiletachyon.dds',
    size=2.3,
  },


  --plane icons
  scoutplane = {
    bitmap='icons/scoutplane.dds',
    size=1.6,
  },
  radarplane = {
    bitmap='icons/radarplane.dds',
    size=2.0,
  },
  fighter = {
    bitmap='icons/fighter.dds',
    size=1.5,
  },
  stealthfighter = {
    bitmap='icons/stealthfighter.dds',
    size=1.7,
  },
  bomber = {
    bitmap='icons/bomber.dds',
    size=1.8,
  },
  bombernuke = {
    bitmap='icons/bombernuke.dds',
    size=2.5,
  },
  bomberriot = {
    bitmap='icons/bomberriot.dds',
    size=2.1,
  },
  bomberassault = {
    bitmap='icons/bomberassault.dds',
    size=2.1,
  },
  bomberspecial = {
    bitmap='icons/bomberspecial.dds',
    size=2.1,
  },
  bomberraider = {
    bitmap='icons/bomberraider.dds',
    size=2.1,
  },
  smallgunship = {
    bitmap='icons/gunship.png',
    size=1.4,
  },
  gunship = {
    bitmap='icons/gunship.png',
    size=2,
  },
  gunshipaa = {
    bitmap='icons/gunshipaa.png',
    size=2,
  },
  gunshipears = {
    bitmap='icons/gunshipears.png',
    size=2,
  },
  heavygunship = {
    bitmap='icons/heavygunship.dds',
    size=2.4,
  },
  heavygunshipears = {
    bitmap='icons/heavygunshipears.png',
    size=2.4,
  },
  supergunship = {
    bitmap='icons/supergunship.dds',
    size=2.8,
  },
  gunshipscout = {
    bitmap='icons/gunshipscout.png',
    size=1.5,
  },
  gunshipspecial = {
    bitmap='icons/gunshipspecial.png',
    size=1.5,
  },
  gunshipraider = {
    bitmap='icons/gunshipraider.png',
    size=2,
  },
  gunshipskirm = {
    bitmap='icons/gunshipskirm.png',
    size=2,
  },
  gunshipriot = {
    bitmap='icons/gunshipriot.png',
    size=4,
  },
  gunshipassault = {
    bitmap='icons/gunshipassault.png',
    size=2.4,
  },
  gunshiparty = {
    bitmap='icons/gunshiparty.png',
    size=2.4,
  },
  gunshiptransport = {
    bitmap='icons/gunshiptransport.png',
    size=2,
  },
  gunshiptransport_large = {
    bitmap='icons/gunshiptransport.png',
    size=3.2,
  },
  heavygunshipskirm = {
    bitmap='icons/heavygunshipskirm.png',
    size=2.4,
  },
  heavygunshiptransport = {
    bitmap='icons/heavygunshiptransport.png',
    size=2.4,
  },
  heavygunshipassault = {
    bitmap='icons/heavygunshipassault.png',
    size=2.4,
  },
  nebula = {
    bitmap='icons/nebula.dds',
    size=4,
  },
  airtransport = {
    bitmap='icons/airtransport.dds',
    size=2.3,
  },
  airtransportbig = {
    bitmap='icons/airtransport.dds',
    size=3,
  },
  airbomb = {
    bitmap='icons/airbomb.dds',
	distance=0.5,
    size=1.6,
  },

  --spec ops
  t3builder = {
    bitmap='icons/t3builder.dds',
    size=1.8,
  },
  --nanos
  staticbuilder = {
    bitmap='icons/staticbuilder.dds',
    size=1.5,
  },

  --ship icons
  shipcon = {
    bitmap='icons/shipcon.dds',
    size=2.2,
  },
  shipscout = {
    bitmap='icons/shipscout.dds',
    size=2.2,
  },
  shipscout_alt = {
    bitmap='icons/shipscout_alt.png',
    size=1.7,
  },
  shipskirm = {
    bitmap='icons/shipskirm.dds',
    size=2.8,
  },
  shipskirm_alt = {
    bitmap='icons/shipskirm_alt.png',
    size=2.0,
  },
  shiptorpraider = {
	bitmap='icons/shiptorpraider.dds',
    size=2.2,
  },
  shipraider_alt = {
	bitmap='icons/shipraider_alt.png',
    size=2,
  },
  subraider = {
	bitmap='icons/subraider.dds',
    size=3.0,
  },
  shipriot = {
    bitmap='icons/shipriot.dds',
	size=2.8,
  },
  shipriot_alt = {
    bitmap='icons/shipriot_alt.png',
	size=2.2,
  },
  shipassault = {
    bitmap='icons/shipassault.png',
	size=2.8,
  },
  shipassault_alt = {
    bitmap='icons/shipassault_alt.png',
	size=2.4,
  },
  shiparty = {
    bitmap='icons/shiparty.dds',
	size=3.0,
  },
  shiparty_alt = {
    bitmap='icons/shiparty_alt.png',
	size=2.3,
  },
  shipaa = {
    bitmap='icons/shipaa.dds',
	size=3.0,
  },
  shipaa_alt = {
    bitmap='icons/shipaa_alt.png',
	size=2.0,
  },
  shiptransport = {
    bitmap='icons/shiptransport.dds',
    size=2.5,
  },
  shipheavyarty = {
    bitmap='icons/shipheavyarty.dds',
    size=4,
  },
  subtacmissile = {
    bitmap='icons/subtacmissile.dds',
    size=4,
  },
  shipcarrier = {
    bitmap='icons/shipcarrier.dds',
    size=4,
  },

  --icon for energy buildings of various tiers, including pylon
  energy_med = {
	bitmap='icons/energy_med.png',
    size=2.1,
  },
  
  energywind = {
    bitmap='icons/energywind.png',
    size=2,
  },
  energysolar = {
    bitmap='icons/energysolar.dds',
    size=2,
  },
  
  energyfusion = {
    bitmap='icons/energyfusion.dds',
    size=2,
  },
  
  energysingu = {
    bitmap='icons/energysingu.dds',
    size=3.2,
  },
  
  energygeo = {
    bitmap='icons/energygeo.png',
    size=2,
  },
  
  energyheavygeo = {
    bitmap='icons/energyheavygeo.png',
    size=2.4,
  },
  
  pylon = {
    bitmap='icons/pylon.dds',
    size=1.8,
  },

  --icon for cruise missiles such as Detonator and Catalyst
  cruisemissile = {
    bitmap='icons/cruisemissile.dds',
    size=2.5,
  },
  cruisemissilesmall = {
    bitmap='icons/cruisemissile.dds',
    size=1,
  },

  --icon for nuclear missile silos
  nuke = {
    bitmap='icons/nuke.dds',
    size=3.0,
  },

  --icon for ABM platforms, both static and mobile
  antinuke = {
    bitmap='icons/antinuke.dds',
    size=3.0,
  },

  --Starlight/Zenith
  mahlazer = {
    bitmap='icons/mahlazer.dds',
    size=3.0,
  },
  -- Starlight satellite
  satellite = {
    bitmap = 'icons/satellite.png',
    size = 3.0,
  },
  special = {
    bitmap='icons/special.dds',
    size=1.6,
  },
  shield = {
    bitmap='icons/shield.dds',
    size=1.6,
  },
  mex = {
    bitmap='icons/mex.dds',
    size = 1.1,
  },
  storage = {
    bitmap='icons/storage.dds',
    size = 1,
  },
  power = {
    bitmap='icons/power.dds',
    size=1,
    radiusadjust=1,
  },

  --landmines
  mine = {
    bitmap='icons/mine.dds',
	distance=0.75,
    size=1.4,
  },

  --facs
  factory = {
    bitmap='icons/factory.dds',
    size=2.6,
    radiusadjust=1,
  },
  fact3 = {
    bitmap='icons/fact3.dds',
    size=2.6,
    radiusadjust=0,
  },
  factank = {
    bitmap='icons/factank.dds',
    size=2.6,
    radiusadjust=0,
  },
  facair = {
    bitmap='icons/facair.dds',
    size=2.6,
    radiusadjust=0,
  },
  facgunship = {
    bitmap='icons/facgunship.dds',
    size=2.6,
    radiusadjust=0,
  },
  facvehicle = {
    bitmap='icons/facvehicle.dds',
     size=2.6,
    radiusadjust=0,
  },
  fackbot = {
    bitmap='icons/fackbot.dds',
    size=2.6,
    radiusadjust=0,
  },
  facwalker = {
    bitmap='icons/facwalker.dds',
    size=2.6,
    radiusadjust=0,
  },
  facspider = {
    bitmap='icons/facspider.png',
    size=2.6,
    radiusadjust=0,
  },
  facjumpjet = {
    bitmap='icons/facjumpjet.png',
    size=2.6,
    radiusadjust=0,
  },
  facamph = {
    bitmap='icons/facamph.png',
    size=2.6,
    radiusadjust=0,
  },
  facship = {
    bitmap='icons/facship.dds',
    size=2.6,
    radiusadjust=0,
  },
  fachover = {
    bitmap='icons/fachover.dds',
    size=2.6,
    radiusadjust=0,
  },

  --chicken
  chicken = {
    --bitmap='icons/chicken.dds',
    bitmap='icons/kbotraider.dds',
    size=1.4,
  },
  chickena = {
    --bitmap='icons/chickena.dds',
    bitmap='icons/walkerassault.dds',
    size=2.1,
  },
  chickenc = {
    --bitmap='icons/chickenc.dds',
    bitmap='icons/spiderassault.dds',
    size=1.8,
  },
  chickenf = {
    --bitmap='icons/chickenf.dds',
    bitmap='icons/fighter.dds',
    size=2.2,
  },
  chickens = {
    --bitmap='icons/chickens.dds',
    bitmap='icons/kbotskirm.dds',
    size=1.6,
  },
  chickenr = {
    --bitmap='icons/chickenr.dds',
    bitmap='icons/kbotarty.dds',
    size=1.6,
  },
  chickendodo = {
    --bitmap='icons/chickendodo.dds',
    bitmap='icons/kbotbomb.dds',
    size=1.4,
  },
  chickenleaper = {
    --bitmap='icons/chickenleaper.dds',
    bitmap='icons/jumpjetraider.dds',
    size=1.8,
  },
  --chicken mini queen
  chickenminiq = {
    bitmap='icons/chickenq.dds',
    size=3.5,
  },
  --chicken queen
  chickenq = {
    bitmap='icons/chickenq.dds',
    size=5.0,
  },
  
  --planetwars
  pw_assault = {
    bitmap='icons/pw_assault.png',
	distance = 1.3,
    size = 3.0,
  },
  pw_bomberfac = {
    bitmap='icons/pw_bomberfac.png',
	distance = 1.6,
    size = 3.4,
  },
  pw_defense = {
    bitmap='icons/pw_defense.png',
	distance = 1.3,
    size = 3.0,
  },
  pw_defense2 = {
    bitmap='icons/pw_defense2.png',
	distance = 1.6,
    size = 3.2,
  },
  pw_dropfac = {
    bitmap='icons/pw_dropfac.png',
	distance = 1.6,
    size = 3.2,
  },
  pw_metal = {
    bitmap='icons/pw_mex.png',
	distance = 1.2,
    size = 2.7,
  },
  pw_energy = {
    bitmap='icons/pw_energy.png',
	distance = 1.2,
    size = 2.7,
  },
  pw_energy2 = {
    bitmap='icons/pw_energy2.png',
	distance = 1.6,
    size = 3.2,
  },
  pw_interception = {
    bitmap='icons/pw_interception.png',
	distance = 1.2,
    size = 3.0,
  },
  pw_relay = {
    bitmap='icons/pw_interception.png',
	distance = 1.2,
    size = 2.0,
  },
  pw_jammer = {
    bitmap='icons/pw_jammer.png',
	distance = 1.0,
    size = 3.0,
  },
  pw_riot = {
    bitmap='icons/pw_riot.png',
	distance = 1.0,
    size = 3.0,
  },
  pw_special = {
    bitmap='icons/pw_special.png',
	distance = 1.0,
    size = 2.7,
  },
  pw_warpgate = {
    bitmap='icons/pw_warpgate.png',
	distance = 1.6,
    size = 3.0,
  },
  pw_wormhole = {
    bitmap='icons/pw_wormhole.png',
	distance = 1.0,
    size = 2.7,
  },
  pw_wormhole2 = {
    bitmap='icons/pw_wormhole2.png',
	distance = 1.0,
    size = 3.0,
  },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return icontypes

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

