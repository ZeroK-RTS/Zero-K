unitDef = {
  unitname                      = [[cordoom]],
  name                          = [[Doomsday Machine]],
  description                   = [[Medium Range Defense Fortress - Requires 50 Power (Main Gun)]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  armoredMultiple               = 0.25,
  brakeRate                     = 0,
  buildCostEnergy               = 1600,
  buildCostMetal                = 1600,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[cordoom_aoplane.dds]],
  buildPic                      = [[CORDOOM.png]],
  buildTime                     = 1600,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[45 100 45]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Forteresse Arm?e]],
	description_de = [[Verteidigungsfestung mittlerer Reichweite - Benötigt ein angeschlossenes Stromnetz von 50 Energie, um feuern zu können.]],
    helptext       = [[Armed with a heavy plasma cannon and a Heat Ray, the Doomsday Machine forms a focal defense point against enemy assault pushes. It can bunker down to survive attack by long-range artillery or air attacks to reduce incoming damage to a quarter, although it cannot fire its weapons while doing so.]],
    helptext_fr    = [[Arm?e d'un canon plasma lourd de moyenne port?e et d'un rayon ? chaleur la Doomday Machine ou DDM comme on la surnomme, est capable de faire face ? tous type de menace. Nu?e, unit?s blind?es voire aerienne si assez proche, tout y passe! Son prix relativement ?lev? en limite cependant l'usage.]],
	helptext_de    = [[Bewaffnet mit einer schweren Plasmakanone und einem Hitzestrahl nimmt die Doomsday Machine einen zentralen Punkt in der Verteidigung gegen feindliche Angriffsoffensiven ein. Die Maschine kann sich verbarrikadieren, um weitreichenden Artilleriebeschuss oder Luftangriffe zu ?erstehen, dabei kann sie aber nicht weiter feuern.]],
    keeptooltip    = [[any string I want]],
    neededlink     = 50,
    pylonrange     = 50,
	extradrawrange = 430,
	aimposoffset   = [[0 30 0]],
	midposoffset   = [[0 0 0]],
	modelradius    = [[20]],
  },

  damageModifier                = 0.25,
  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[staticassaultriot]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  losEmitHeight                 = 70,
  maxDamage                     = 10000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[DDM.s3o]],
  onoffable                     = true,
  script                        = [[cordoom.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ESTOR_BUILDING]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },
  sightDistance                 = 780,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooo ooo ooo]],

  weapons                       = {

    {
      def                = [[PLASMA]],
	  badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },


    {
      def                = [[HEATRAY]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    HEATRAY = {
      name                    = [[Heat Ray]],
      accuracy                = 512,
      areaOfEffect            = 20,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		light_camera_height = 2000,
		light_color = [[0.9 0.4 0.12]],
		light_radius = 180,
		light_fade_time = 35,
		light_fade_offset = 10,
		light_beam_mult_frames = 9,
		light_beam_mult = 8,
	  },

      damage                  = {
        default = 51.1,
        planes  = 51.1,
        subs    = 2.625,
      },

      duration                = 0.3,
      dynDamageExp            = 1,
      dynDamageInverted       = false,
      explosionGenerator      = [[custom:HEATRAY_HIT]],
      fallOffRate             = 0.9,
      fireStarter             = 90,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      proximityPriority       = 6,
	  projectiles			  = 2,
      range                   = 430,
      reloadtime              = 0.1,
      rgbColor                = [[1 0.1 0]],
      rgbColor2               = [[1 1 0.25]],
      soundStart              = [[weapon/heatray_fire]],
      thickness               = 3.95284707521047,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 500,
    },


    PLASMA  = {
      name                    = [[Heavy Plasma Cannon]],
      areaOfEffect            = 192,
      avoidFeature            = false,
      burnBlow                = true,
      craterBoost             = 0.7,
      craterMult              = 1.2,

      customParams            = {
		light_color = [[2.2 1.6 0.9]],
		light_radius = 550,
      },

      damage                  = {
        default = 1201,
        subs    = 60,
      },

      edgeEffectiveness       = 0.7,
      explosionGenerator      = [[custom:FLASHSMALLBUILDING]],
      fireStarter             = 99,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      proximityPriority       = 6,
      range                   = 650,
      reloadtime              = 3,
      soundHit                = [[weapon/cannon/cannon_hit4]],
	  --soundHitVolume          = 70,
      soundStart              = [[weapon/cannon/heavy_cannon2]],
      sprayangle              = 768,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 750,
    },

  },


  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[ddm_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ cordoom = unitDef })
