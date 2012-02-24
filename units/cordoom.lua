unitDef = {
  unitname                      = [[cordoom]],
  name                          = [[Doomsday Machine]],
  description                   = [[Medium Range Defense Fortress - Requires 50 Power (Main Gun)]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  armoredMultiple               = 0.25,
  brakeRate                     = 0,
  buildAngle                    = 4096,
  buildCostEnergy               = 1200,
  buildCostMetal                = 1200,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[cordoom_aoplane.dds]],
  buildPic                      = [[CORDOOM.png]],
  buildTime                     = 1200,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK TURRET]],
  collisionVolumeScales         = [[50 100 50]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Forteresse Arm?e]],
	description_de = [[Verteidigungsfestung mittlerer Reichweite - Benötigt ein angeschlossenes Stromnetz von 50 Energie, um feuern zu können.]],
    helptext       = [[Armed with a heavy plasma cannon and a Heat Ray, the Doomsday Machine forms a focal defense point against enemy assault pushes. It can bunker down to survive attack by long-range artillery or air attacks to reduce incoming damage to a quarter, although it cannot fire its weapons while doing so.]],
    helptext_fr    = [[Arm?e d'un canon plasma lourd de moyenne port?e et d'un rayon ? chaleur la Doomday Machine ou DDM comme on la surnomme, est capable de faire face ? tous type de menace. Nu?e, unit?s blind?es voire aerienne si assez proche, tout y passe! Son prix relativement ?lev? en limite cependant l'usage.]],
	helptext_de    = [[Bewaffnet mit einer schweren Plasmakanone und einem Hitzestrahl nimmt die Doomsday Machine einen zentralen Punkt in der Verteidigung gegen feindliche Angriffsoffensiven ein. Die Maschine kann sich verbarrikadieren, um weitreichenden Artilleriebeschuss oder Luftangriffe zu überstehen, dabei kann sie aber nicht weiter feuern.]],
    keeptooltip    = [[any string I want]],
    neededlink     = 50,
    pylonrange     = 50,
	extradrawrange = 430,
  },

  damageModifier                = 0.25,
  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[staticassaultriot]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = true,
  mass                          = 636,
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
  
  side                          = [[CORE]],
  sightDistance                 = 780,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[o]],

  weapons                       = {

    {
      def                = [[PLASMA]],
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
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
      cegTag                  = [[HEATRAY_CEG]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 52.5,
        planes  = 52.5,
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
      renderType              = 0,
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
      burnBlow                = true,
      craterBoost             = 0.7,
      craterMult              = 1.2,

      damage                  = {
        default = 1200,
        planes  = 1200,
        subs    = 60,
      },

      edgeEffectiveness       = 0.7,
      explosionGenerator      = [[custom:FLASHSMALLBUILDINGEX]],
      fireStarter             = 99,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      proximityPriority       = 6,
      range                   = 700,
      reloadtime              = 3,
      renderType              = 4,
      soundHit                = [[explosion/ex_large7]],
      soundStart              = [[weapon/cannon/heavy_cannon2]],
      sprayangle              = 768,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 750,
    },

  },


  featureDefs                   = {

    DEAD = {
      description      = [[Wreckage - Doomsday Machine]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 10000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 480,
      object           = [[ddm_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 480,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Doomsday Machine]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 10000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 240,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 240,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ cordoom = unitDef })
