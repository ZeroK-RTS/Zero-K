unitDef = {
  unitname            = [[hoverriot]],
  name                = [[Mace]],
  description         = [[Riot Hover]],
  acceleration        = 0.022,
  activateWhenBuilt   = true,
  brakeRate           = 0.03,
  buildCostMetal      = 400,
  builder             = false,
  buildPic            = [[hoverriot.png]],
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -8 0]],
  collisionVolumeScales  = [[48 36 48]],
  collisionVolumeType    = [[cylY]], 
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hover ?meutier]],
	description_de = [[Riotgleiter]],
    helptext       = [[The Mace is a mobile laser tower. Its high firepower is useful for killing light enemy units. It is perfectly accurate and is good against gunships and fast units. However, its thin armor makes it vulnerable when targetted directly, especially by skirmishers.]],
    helptext_fr    = [[Le Mace est une tour laser mobile. Sa forte puissance de feu et sa pr?cision parfaite sont appreciable pour se debarrasser de petites unit?s.]],
	helptext_de    = [[Der Mace ist ein mobiler Laserturm. Seine hohe Feuerkraft ist nützlich, um leichte, feindliche Einheiten zu töten. Er schießt höchst präzise und erweist sich gegen Hubschrauber und schnelle Einheiten als nützlich. Trotzdem macht ihn seine einfache Verteidigung anfällig für direkte Angriffe, vor allem durch Skirmisher.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 1200,
  maxSlope            = 36,
  maxVelocity         = 2.2,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hoverriot.s3o]],
  script              = [[hoverriot.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  sightDistance       = 407,
  sonarDistance       = 407,  
  turninplace         = 0,
  turnRate            = 400,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[LASER1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    LASER1 = {
      name                    = [[High Intensity Laserbeam]],
      areaOfEffect            = 8,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customparams = {
		stats_hide_damage = 1, -- continuous laser
		stats_hide_reload = 1,
		
		light_color = [[0.25 1 0.25]],
		light_radius = 120,
	  },

      damage                  = {
        default = 29.68,
        subs    = 1.75,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 345,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/laser_burn10]],
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 4.33,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hoverriot_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ hoverriot = unitDef })
