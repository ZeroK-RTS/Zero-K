unitDef = {
  unitname               = [[spiderassault]],
  name                   = [[Hermit]],
  description            = [[All Terrain Assault Bot]],
  acceleration           = 0.18,
  brakeRate              = 0.22,
  buildCostEnergy        = 160,
  buildCostMetal         = 160,
  buildPic               = [[spiderassault.png]],
  buildTime              = 160,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -3 0]],
  collisionVolumeScales  = [[24 30 24]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Geländegängige Sturmspinne]],
    description_fr = [[Robot d'assaut arachnide]],
    helptext       = [[The Hermit can take an incredible beating, and is useful as a shield for the weaker, more-damaging Recluses.]],
    helptext_fr    = [[Le Hermit est extraordinairement résistant pour sa taille. Si son canon ?plasma n'a pas la précision requise pour abattre les cibles rapides il reste néanmoins un bouclier parfait pour des unités moins solides telles que les Recluses.]],
	helptext_de    = [[Der Hermit kann unglaublich viel Pr?el einstecken und ist als Schutzschild f? schwächere, oder zu schonende Einheiten, hervorragend geeignet.]],
	modelradius    = [[12]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[spiderassault]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1400,
  maxSlope               = 36,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[hermit.s3o]],
  selfDestructAs         = [[BIG_UNITEX]],
  script                = [[spiderassault.lua]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance          = 420,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 30,
  turnRate               = 1600,

  weapons                = {

    {
      def                = [[THUD_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    THUD_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 36,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1800,
		light_color = [[0.80 0.54 0.23]],
		light_radius = 200,
      },

      damage                  = {
        default = 141,
        planes  = 141,
        subs    = 7,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 2.6,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 280,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[hermit_wreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ spiderassault = unitDef })
