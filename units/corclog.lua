unitDef = {
  unitname               = [[corclog]],
  name                   = [[Dirtbag]],
  description            = [[Box of Dirt]],
  acceleration           = 0.2,
  brakeRate              = 0.2,
  buildCostEnergy        = 30,
  buildCostMetal         = 30,
  buildPic               = [[corclog.png]],
  buildTime              = 30,
  canAttack              = false,
  canFight               = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND STUPIDTARGET]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[34 45 27]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    canjump            = 1,
    jump_range         = 400,
    jump_speed         = 6,
    jump_reload        = 10,
    jump_from_midair   = 0,
    jump_spread_exception = 1,

    description_es = [[Caja de tierra]],
    description_fr = [[]],
    description_it = [[Scatola di terra]],
    description_de = [[Behalter voller Dreck]],
    description_pl = [[Pudlo z piachem]],
    helptext       = [[The Dirtbag exists to block enemy movement and generally get in the way. They are so dedicated to this task that they release their dirt payload upon death to form little annoying mounds. While waiting for their fate Dirtbags enjoy headbutting and scouting.]],
  },

  explodeAs              = [[CLOGGER_EXPLODE]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[clogger]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 600,
  maxSlope               = 36,
  maxVelocity            = 2.5,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP]],
  objectName             = [[clogger.s3o]],
  script                 = [[corclog.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[CLOGGER_EXPLODE]],
  selfDestructCountdown  = 0,
  sightDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2000,
  upright                = true,
  
  weapons             = {

    {
      def                = [[Headbutt]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },
  
  weaponDefs          = {

    Headbutt = {
      name                    = [[Headbutt]],
      beamTime                = 1/30,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      canattackground         = true,
      collideFeature          = false,
      collideFriendly         = false,
      collideGround           = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		light_radius = 0,
        combatrange = 5,
	  },

      damage                  = {
        default = 36,
        planes  = 36,
        subs    = 3.6,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 90,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      lodDistance             = 10000,
      noSelfDamage            = true,
      range                   = 50,
      reloadtime              = 2,
      rgbColor                = [[1 0.25 0]],
      soundStart              = [[explosion/ex_small4_2]],
      soundStartVolume        = 25,
      targetborder            = 1,
      thickness               = 0,
      tolerance               = 1000000,
      turret                  = true,
      waterweapon             = true,
      weaponType              = [[BeamLaser]],
    },

    CLOGGER_EXPLODE = {
      areaOfEffect       = 8,
      craterMult         = 0,
      edgeEffectiveness  = 0,
      explosionGenerator = "custom:dirt2",
      impulseFactor      = 0,
      name               = "Dirt Spill",
      soundHit           = "explosion/clogger_death",
      damage = {
        default = 1,
      },
    },
  },
  
  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris1x1a.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris1x1a.s3o]],
    },

  },

}

return lowerkeys({ corclog = unitDef })
