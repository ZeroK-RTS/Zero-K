unitDef = {
  unitname               = [[armwar]],
  name                   = [[Warrior]],
  description            = [[Riot Bot]],
  acceleration           = 0.25,
  brakeRate              = 0.2,
  buildCostEnergy        = 220,
  buildCostMetal         = 220,
  buildPic               = [[ARMWAR.png]],
  buildTime              = 220,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 2 -5]],
  collisionVolumeScales  = [[26 36 26]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Robot émeutier]],
	description_de = [[Riot Roboter]],
    helptext       = [[The Warrior's devastating heavy Energy Machine Gun is effective versus most enemy units, in particular raiders. It performs poorly versus static defense, so do not use it as an assault unit. Counter by staying out of their range, as they are slow. Warriors quickly regenerate damage when out of combat.]],
    helptext_fr    = [[La dévastatrice mitrailleuse à plasma lourde du Warrior est efficace contre la majorité de ses enemis, en particulier les unités de raid. Il est très peu efficace contre les défenses statiques, ne l'utilisez donc pas comme unité d'assaut. Contrez le en restant hors de sa portée, étant donné sa faible vitesse de mouvement.]],
	helptext_de    = [[Sein schweres Maschingewehr ist gegen die meisten Einheiten effektiv, vor allem gegen Raider. Dennoch versagt es kläglich gegen stationäre Verteidigung. Also nutze ihn nicht als Sturmeinheit. Kontere den Warrior, indem du aus seiner Reichweite bleibst, sie sind langsam.]],
	modelradius    = [[7]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[kbotriot]],
  idleAutoHeal           = 30,
  idleTime               = 150,
  leaveTracks            = true,
  maxDamage              = 820,
  maxSlope               = 36,
  maxVelocity            = 1.71,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[Spherewarrior.s3o]],
  script                 = [[armwar.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:emg_shells_l]],
    },

  },

  sightDistance          = 345,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 20,
  turnRate               = 1800,
  upright                = true,

  weapons                = {

    {
      def                = [[WARRIOR_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    WARRIOR_WEAPON = {
      name                    = [[Heavy Pulse MG]],
      accuracy                = 350,
      alphaDecay              = 0.7,
      areaOfEffect            = 96,
      burnblow                = true,
      burst                   = 3,
      burstrate               = 0.1,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      customParams        = {
		light_camera_height = 1600,
		light_color = [[0.8 0.76 0.38]],
		light_radius = 150,
      },

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 2.1,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 270,
      reloadtime              = 0.45,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/heavy_emg]],
      stages                  = 10,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherewarrior_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3a.s3o]],
    },

  },

}

return lowerkeys({ armwar = unitDef })
