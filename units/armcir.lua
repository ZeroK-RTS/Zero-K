unitDef = {
  unitname                      = [[armcir]],
  name                          = [[Chainsaw]],
  description                   = [[Long-Range Anti-Air Missile Battery]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 900,
  buildCostMetal                = 900,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3.6,
  buildingGroundDecalSizeY      = 3.6,
  buildingGroundDecalType       = [[armcir_aoplane.dds]],
  buildPic                      = [[ARMCIR.png]],
  buildTime                     = 900,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT]],
  collisionVolumeOffsets        = [[0 12 0]],
  collisionVolumeScales         = [[58 76 58]],
  collisionVolumeType	        = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Batterie de Missiles Anti-Air ? Moyenne Port?e]],
	description_de = [[Weitreichende Anti-Air Raketenbatterie]],
	helptext_de    = [[Der Chainsaw ist eine weitreichendes Anit-Air Gesch�tz, welches massiv Schaden austeilt und sogar Bomber vom Himmel holen kann. Dennoch kann es nicht viel Schaden einstecken und versagt kl�glich, wenn es direkt angegriffen wird.]],
    helptext       = [[The Chainsaw is a long range anti-air turret, dealing out massive damage, able to knock bombers out of the sky very quickly. It can't take very much damage in return, though, and does poorly when attacked directly.]],
    helptext_fr    = [[Cette batterie de missile ultra v?loce permet d'abattre des cibles aeriennes lourdes - comme les bombardiers - avant qu'elles ne puissent passer ? l'attaque. Il n?cessite d'?tre plac? en terrain d?gag? pour utiliser pleinement son potentiel. Reste assez fragile et ? prot?ger.]],
	aimposoffset   = [[0 10 0]],
	modelradius    = [[19]],
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[staticskirmaa]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  losEmitHeight                 = 40,
  maxDamage                     = 2500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 5000,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[armcir.s3o]],
  script                        = [[armcir.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  sightDistance                 = 702,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooo]],
	
  sfxtypes            = {

    explosiongenerators = {
      [[custom:light_red_short]],
      [[custom:light_green_short]],
      [[custom:light_blue_short]],
    },

  },
	
  weapons                       = {

    {
      def                = [[MISSILE]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    MISSILE = {
      name                    = [[Long-Range SAM]],
      areaOfEffect            = 24,
      canattackground         = false,
      cegTag                  = [[chainsawtrail]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
		light_color = [[0.6 0.7 0.7]],
		light_radius = 420,
	  },

      damage                  = {
        default = 22.51,
        planes  = 225.1,
        subs    = 12.5,
      },

      explosionGenerator      = [[custom:MISSILE_HIT_PIKES_160]],
      fireStarter             = 20,
      flightTime              = 4,
      impactOnly              = true,
      impulseBoost            = 0.123,
      impulseFactor           = 0.0492,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]],
      noSelfDamage            = true,
      range                   = 1800,
      reloadtime              = 1,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/med_aa_hit]],
      soundStart              = [[weapon/missile/med_aa_fire]],
      soundTrigger            = true,
      startVelocity           = 550,
      texture2                = [[AAsmoketrail]],
      tolerance               = 16000,
      tracks                  = true,
      turnRate                = 55000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 550,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[chainsaw_d.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

}

return lowerkeys({ armcir = unitDef })
