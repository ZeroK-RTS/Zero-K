unitDef = {
  unitname            = [[chicken_tiamat]],
  name                = [[Tiamat]],
  description         = [[Heavy Assault/Riot]],
  acceleration        = 0.36,
  autoheal            = 20,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_tiamat.png]],
  buildTime           = 350,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND FIREPROOF]],

  customParams        = {
    description_fr = [[Assault lourd]],
	description_de = [[Schwere Sturm-/Rioteinheit]],
    fireproof      = 1,
    helptext       = [[The ultimate assault chicken, the Tiamat is a fire-breathing, iron-jawed, spore-spewing monstrosity that knows no fear, no mercy. It even has a mucous shield to protect itself and surrounding chickens from damage.]],
    helptext_fr    = [[L'ultime unit? d'assault pouler, le Tiamat est une monstruosit? crachant des flammes, d?chirant de ses machoires d'acier et lan?ant des spores sur ses victimes. Elle poss?de m?me un bouclier ?nerg?tique r?sultant de sa fureur, lui procurant ? elle et aux unit?s alli?es ? proximit? une protection efficace durant leur progession vers l'adversaire.]],
	helptext_de    = [[Das ultimative Sturmchicken: Tiamat ist eine feuer-, eisenspuckende und Sporenspeiende Monstrosit�t, die keine Angst oder Furcht kennt, aber auch keine Gnade. Sie besitzt sogar ein schleimiges Schild, welches sie selbst und nahe, verb�Edete Einheiten sch�Ezt.]],
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[t3generic]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 3650,
  maxSlope            = 37,
  maxVelocity         = 2.3,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT6]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB STUPIDTARGET MINE]],
  objectName          = [[chickenbroodqueen.s3o]],
  power               = 350,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
      [[custom:RAIDMUZZLE]],
    },

  },
  sightDistance       = 256,
  trackOffset         = 7,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 34,
  turninplace         = 0,
  turnRate            = 806,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[JAWS]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },


    {
      def                = [[SPORES]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[FLAMETHROWER]],
      badTargetCategory  = [[FIREPROOF]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },


    {
      def = [[SHIELD]],
    },

  },


  weaponDefs          = {

    FLAMETHROWER = {
      name                    = [[Flamethrower]],
      areaOfEffect            = 64,
      avoidGround             = false,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideGround           = false,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,
      cegTag                  = [[flamer]],

	  customParams        	  = {
		flamethrower = [[1]],
	    setunitsonfire = "1",
		burntime = [[450]],
	  },
	  
      damage                  = {
        default = 12,
        subs    = 0.01,
      },

      duration				  = 0.01,
      explosionGenerator      = [[custom:SMOKE]],
      fallOffRate             = 1,
      fireStarter             = 100,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.3,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      --predictBoost			  = 1,
      range                   = 290,
      reloadtime              = 0.16,
      rgbColor                = [[1 1 1]],
      soundStart              = [[weapon/flamethrower]],
      soundTrigger            = true,
      texture1                = [[flame]],
      thickness	              = 0,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 800,
    },


    JAWS         = {
      name                    = [[Jaws]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 300,
        planes  = 300,
        subs    = 3,
      },

      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      range                   = 160,
      reloadtime              = 1.5,
      size                    = 0,
      soundHit                = [[chickens/chickenbig2]],
      soundStart              = [[chickens/chickenbig2]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },


    SHIELD       = {
      name                    = [[Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      shieldAlpha             = 0.15,
      shieldBadColor          = [[1.0 1 0.1]],
      shieldGoodColor         = [[0.1 1.0 0.1]],
      shieldInterceptType     = 3,
      shieldPower             = 2500,
      shieldPowerRegen        = 180,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 300,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[wake]],
      visibleShield           = true,
      visibleShieldHitFrames  = 30,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },


    SPORES       = {
      name                    = [[Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 8,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_radius = 0,
      },
      
      damage                  = {
        default = 100,
        planes  = 100,
        subs    = 100,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = 1,
      flightTime              = 5,
      groundbounce            = 1,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[chickeneggpink.s3o]],
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 6,
      smokeTrail              = true,
      startVelocity           = 100,
      texture1                = [[]],
      texture2                = [[sporetrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 32000,
    },

  },

}

return lowerkeys({ chicken_tiamat = unitDef })
