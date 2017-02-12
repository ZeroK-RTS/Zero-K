unitDef = {
  unitname            = [[armflea]],
  name                = [[Flea]],
  description         = [[Ultralight Scout Spider (Burrows)]],
  acceleration        = 0.7,
  brakeRate           = 2.1,
  buildCostEnergy     = 20,
  buildCostMetal      = 20,
  buildPic            = [[ARMFLEA.png]],
  buildTime           = 20,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND TOOFAST]],
  cloakCost           = 0,
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Ultraleichte Kundschafter Spinne]],
    description_fr = [[Éclaireur tout terrain ultra léger]],
    helptext       = [[The Flea can hide in inaccessible locations where its sophisticated sensor suite allows it to see further than it can be seen. It can be used in small groups to effectively raid mexes early on, and in maps with tall cliffs can attack from unexpected angles. It does very little damage and dies to any form of opposition.]],
    helptext_de    = [[Flea kann sich in unerreichbaren Gegenden verstecken, wo ein durchdachter Sensor es ermöglicht weiter zu sehen als Flea gesehen werden kann. In kleinen Gruppen kann es effektiv die gegnerischen Extraktoren überlaufen. Es macht aber nur wenig Schaden und stirbt sofort bei irgendeiner Gegenwehr.]],
    helptext_fr    = [[Le Flea, unité ultra légère invisible une fois immobile, peut se cacher dans des endroits inaccessibles d'où il peut observer de loin grâce à ses capteurs sophistiqués sans être vu, tel un éclaireur. Il peut aussi être utilisé en petit groupe pour effectuer des raids surprises sur les éléments de production enemis non protégés, en début de jeu. Il ne cause que très peu de dégats et meurt aisément face à toute opposition.]],
    idle_cloak = 1,
  },

  explodeAs           = [[TINY_BUILDINGEX]],
  footprintX          = 1,
  footprintZ          = 1,
  iconType            = [[spiderscout]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 40,
  maxSlope            = 72,
  maxVelocity         = 4.8,
  maxWaterDepth       = 15,
  minCloakDistance    = 120,
  movementClass       = [[TKBOT1]],
  moveState           = 0,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[arm_flea.s3o]],
  pushResistant       = 0,
  script	      			= [[armflea.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[TINY_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:digdig]],
    },

  },

  sightDistance       = 560,
  turnRate            = 2100,

  weapons             = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {

    LASER = {
      name                    = [[Micro Laser]],
      areaOfEffect            = 8,
      beamTime                = 0.1,
      burstrate               = 0.2,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
		light_color = [[0.8 0.8 0]],
		light_radius = 50,
      },

      damage                  = {
        default = 10.57,
        planes  = 10.57,
        subs    = 0.5,
      },

      explosionGenerator      = [[custom:beamweapon_hit_yellow_tiny]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.22,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 140,
      reloadtime              = 0.25,
      rgbColor                = [[1 1 0]],
      soundStart              = [[weapon/laser/small_laser_fire]],
      soundTrigger            = true,
      thickness               = 2.14476105895272,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 600,
    },

  },

  featureDefs                   = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[flea_d.dae]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[debris1x1b.s3o]],
    },

  },

}

return lowerkeys({ armflea = unitDef })
