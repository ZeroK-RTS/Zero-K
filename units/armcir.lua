unitDef = {
  unitname                      = [[armcir]],
  name                          = [[Chainsaw]],
  description                   = [[Long-Range AA Missile Battery]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildAngle                    = 65536,
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
  collisionVolumeTest	        = 1,
  collisionVolumeType	        = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    usetacai       = [[1]],
    description_fr = [[Batterie de Missiles Anti-Air ? Moyenne Port?e]],
	description_de = [[Weitreichende Anti-Air Raketenbatterie]],
	description_pl = [[Bateria rakiet przeciwlotniczych]],
	helptext_de    = [[Der Chainsaw ist eine weitreichendes Anit-Air Gesch�tz, welches massiv Schaden austeilt und sogar Bomber vom Himmel holen kann. Dennoch kann es nicht viel Schaden einstecken und versagt kl�glich, wenn es direkt angegriffen wird.]],
	helptext_pl    = [[Chainsaw to bateria rakiet przeciwlotniczych dalekiego zasiegu, ktora zadaje wysokie obrazenia, ale ma niska wytrzymalosc.]],
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
  mass                          = 318,
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
  side                          = [[ARM]],
  sightDistance                 = 702,
  smoothAnim                    = true,
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
	  },

      damage                  = {
        default = 22.5,
        planes  = 225,
        subs    = 12.5,
      },

      explosionGenerator      = [[custom:MISSILE_HIT_PIKES_160]],
      fireStarter             = 20,
      flightTime              = 4,
      guidance                = true,
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
      startsmoke              = [[1]],
      startVelocity           = 550,
      texture2                = [[AAsmoketrail]],
      tolerance               = 16000,
      tracks                  = true,
      turnRate                = 55000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 550,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Chainsaw]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2500,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[chainsaw_d.3ds]],
      reclaimable      = true,
      reclaimTime      = 320,
    },

    HEAP  = {
      description      = [[Debris - Chainsaw]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2500,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
    },

  },

}

return lowerkeys({ armcir = unitDef })
