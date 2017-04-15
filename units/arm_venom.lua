unitDef = {
  unitname               = [[arm_venom]],
  name                   = [[Venom]],
  description            = [[Lightning Riot Spider]],
  acceleration           = 0.26,
  brakeRate              = 0.78,
  buildCostMetal         = 200,
  buildPic               = [[arm_venom.png]],
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[38 38 38]],
  collisionVolumeType    = [[ellipsoid]], 
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Araignée à effet de zone EMP]],
    description_de = [[Unterstützende EMP Spinne]],
    helptext       = [[The Venom is an all-terrain unit designed to paralyze enemies so other units can easily destroy them. It moves particularly fast for a riot unit and in addition to paralysis it does a small amount of damage. Works well in tandem with the Recluse to keep enemies from closing range with the fragile skirmisher.]],
    helptext_fr    = [[Le Venom est une araignée tout terrain rapide spécialement conçue pour paralyser l'ennemi afin que d'autres unités puissent les détruire rapidement et sans risques. Sa faible portée est compensée par son effet de zone pouvant affecter plusieurs unités à proximité de sa cible. Est particulièrement efficace en tandem avec le Recluse ou l'Hermit.]],
	helptext_de    = [[Venom ist eine geländeunabhängige Einheit, welche Gegner paralysieren kann, damit andere Einheiten diese einfach zerstören können. Venom besitzt eine AoE und ist nützlich, um gengerische Schwärme in Schach zu halten.]],
	aimposoffset   = [[0 0 0]],
	midposoffset   = [[0 -6 0]],
	modelradius    = [[19]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spiderriotspecial]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 750,
  maxSlope               = 72,
  maxVelocity            = 2.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[venom.s3o]],
  script                 = [[arm_venom.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:YELLOW_LIGHTNING_MUZZLE]],
      [[custom:YELLOW_LIGHTNING_GROUNDFLASH]],
    },

  },

  sightDistance          = 440,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 54,
  turnRate               = 1600,

  weapons                = {

    {
      def                = [[spider]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs             = {

    spider = {
      name                    = [[Electro-Stunner]],
      areaOfEffect            = 160,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
	  
      customParams            = {
        extra_damage = [[18]],
		
		light_color = [[0.75 0.75 0.56]],
		light_radius = 190,
      },

      damage                  = {
        default        = 600.5,
      },

      duration                = 8,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION160AoE]],
      fireStarter             = 0,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 3,
      range                   = 240,
      reloadtime              = 1.75,
      rgbColor                = [[1 1 0.7]],
      soundStart              = [[weapon/lightning_fire]],
      soundTrigger            = true,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[venom_wreck.s3o]],
    },
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ arm_venom = unitDef })
