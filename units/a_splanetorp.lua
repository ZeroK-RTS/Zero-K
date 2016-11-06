unitDef = {
  unitname            = [[a_splanetorp]],
  name                = [[Harpy]],
  description         = [[Torpedo Bomber]],
  amphibious          = true,
  buildCostEnergy     = 150,
  buildCostMetal      = 150,
  builder             = false,
  buildPic            = [[bomberstrike.png]],
  buildTime           = 150,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[80 10 30]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAlt           = 90,

  customParams        = {
    description_pl = [[???]],
    helptext       = [[The low flying Harpy launches a pair of single-target torpedoes capable of striking any target on or below the water. It is ineffective against targets on land.]],
    helptext_pl    = [[???]],
    --modelradius    = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomber]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  mass                = 234,
  maxAcc              = 0.5,
  maxDamage           = 550,
  maxElevator         = 0.02,
  maxRudder           = 0.006,
  maxFuel             = 1000000,
  maxVelocity         = 7.8,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[a_splanetorp.s3o]],
  script              = [[a_splanetorp.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {},

  side                = [[CORE]],
  sightDistance       = 660,
  turnRadius          = 120,
  workerTime          = 0,

  
  weapons           = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
	  mainDir            = [[0 0 1]],
      maxAngleDif        = 90, 
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },


  weaponDefs        = {

    TORPEDO = {
      name                    = [[Torpedo Launcher]],
      areaOfEffect            = 10,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 190.1,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      edgeEffectiveness       = 0.6,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      model                   = [[wep_m_dragonsfang.s3o]],
      numbounce               = 4,
	  projectiles	      	  = 2,
      range                   = 400,
      reloadtime              = 10,
      soundHit                = [[explosion/wet/ex_underwater]],
      --soundStart              = [[weapon/torpedo]],
      startVelocity           = 100,
      tracks                  = true,
      turnRate                = 22000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 200,
      weaponTimer             = 3,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 100,
    },

  },

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[a_splanetorp_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ a_splanetorp = unitDef })
