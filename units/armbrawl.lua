unitDef = {
  unitname            = [[armbrawl]],
  name                = [[Brawler]],
  description         = [[Fire Support Gunship]],
  acceleration        = 0.2,
  brakeRate           = 0.16,
  buildCostEnergy     = 760,
  buildCostMetal      = 760,
  builder             = false,
  buildPic            = [[ARMBRAWL.png]],
  buildTime           = 760,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = true,
  collisionVolumeOffsets = [[0 0 -5]],
  collisionVolumeScales  = [[40 20 60]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  cruiseAlt           = 240,

  customParams        = {
    airstrafecontrol = [[0]],
    description_fr = [[ADAV d'Assaut Terrestre]],
	description_de = [[Luftnaher Unterstützungskampfhubschrauber]],
	helptext       = [[The Brawler is a fire support gunship that flies out of the reach of most ground mobiles. It is tough enough to survive limited anti-air fire, and its twin EMGs chew through units stupid enough to stay put.]],
    helptext_de    = [[Der Brawler ist eine Angriffseinheit, die den meisten Bodenrakten ausweichen kann. Der Brawler besitzt genug Munition, um begrenztes Anti-Air Feuer zu überleben und seine Zwillings-EMGs zerfetzen die Panzerung als wäre es Papier.]],
    helptext_fr    = [[Le Brawler est un ADAV lourd, de par son blondage comme de par le calibre de ses mitrailleuses. Il peut donc résister r des défenses anti air assez longtemps pour s'en débarrasser. Un redoutable ADAV, mais cependant sans défense contre l'air.]],
	modelradius    = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  hoverAttack         = true,
  iconType            = [[heavygunshipskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  maxDamage           = 2800,
  maxVelocity         = 3.3,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[stingray.s3o]],
  script              = [[armbrawl.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },
  sightDistance       = 600,
  turnRate            = 600,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[EMG]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 70,
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },

  },


  weaponDefs          = {

    EMG = {
      name                    = [[Heavy Pulse MG]],
      areaOfEffect            = 40,
      avoidFeature            = false,
	  burnBlow                = true,
      burst                   = 4,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      customparams = {
        combatrange = 650,
        light_camera_height = 2000,
        light_color = [[0.9 0.84 0.45]],
        light_ground_height = 120,
      },
	  
      damage                  = {
        default = 19.3,
        subs    = 1.0,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
	  myGravity               = 0.15,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 0.45,
      rgbColor                = [[1 0.95 0.5]],
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/cannon/brawler_emg]],
      sprayAngle              = 1400,
      tolerance               = 2000,
      turret                  = true,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 420,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[brawler_d.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ armbrawl = unitDef })
