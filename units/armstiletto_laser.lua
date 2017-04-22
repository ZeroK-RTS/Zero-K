unitDef = {
  unitname            = [[armstiletto_laser]],
  name                = [[Thunderbird]],
  description         = [[Disarming Lightning Bomber]],
  brakerate           = 0.4,
  buildCostMetal      = 550,
  buildPic            = [[armstiletto_laser.png]],
  canAttack           = true,
  canFly              = true,
  canMove             = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 4]],
  collisionVolumeScales  = [[45 20 50]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  cruiseAlt           = 180,

  customParams        = {
    description_de = [[Entwaffnungbomber]],
    description_fr = [[Bombardier desarmant]],
    helptext       = [[Fast bomber armed with a lightning generator that disarms units in a wide area under it.]],
    helptext_de    = [[Schneller Entwaffnungbomber, der mit einem Stossspannungsgenerator zum Entwaffnen großflächiger Gebiete bewaffnet ist.]],
    helptext_fr    = [[Rapide, armé de canons desarmant pouvant désarmer les unités dans une large bande.]],
    modelradius    = [[10]],
    requireammo    = [[1]],
    refuelturnradius = [[170]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomberriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxAcc              = 0.5,
  maxDamage           = 1000,
  maxFuel             = 1000000,
  maxVelocity         = 9,
  minCloakDistance    = 75,
  noChaseCategory     = [[TERRAFORM FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName          = [[stiletto.s3o]],
  script              = [[armstiletto_laser.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 660,
  turnRadius          = 20,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

    {
      def                = [[ARMBOMBLIGHTNING]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[NONE]],
    },

  },

  weaponDefs          = {

    ARMBOMBLIGHTNING = {
      name                    = [[Lightning]],
      areaOfEffect            = 192,
      avoidFeature            = false,
      avoidFriendly           = false,
      beamTime                = 1/30,
      burst                   = 80,
      burstRate               = 0.3,
	  cameraShake             = 150,
      canattackground         = false,
      collideFriendly         = false,
      coreThickness           = 0.6,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        disarmDamageMult = 1,
        disarmDamageOnly = 1,
        disarmTimer      = 16, -- seconds
	  
		light_radius = 350,
		light_color = [[2 2 2]],
      },
 
      damage                  = {
        default        = 675,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:WHITE_LIGHTNING_BOMB]],
      fireStarter             = 90,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 5,
      minIntensity            = 1,
      range                   = 730,
      reloadtime              = 1,
      rgbColor                = [[1 1 1]],
      sprayAngle              = 6000,
      texture1                = [[lightning]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 10,
      tileLength              = 50,
      tolerance               = 32767,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },


    BOGUS_BOMB       = {
      name                    = [[Fake Bomb]],
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 2,
      burstrate               = 1,
      collideFriendly         = false,

      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:NONE]],
      interceptedByShieldType = 1,
      intensity               = 0,
      myGravity               = 0.8,
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 1,
      sprayangle              = 64000,
      weaponType              = [[AircraftBomb]],
    },

  },

  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[Stiletto_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ armstiletto_laser = unitDef })
