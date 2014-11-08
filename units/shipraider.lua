unitDef = {
  unitname               = [[shipraider]],
  name                   = [[Typhoon]],
  description            = [[Corvette (Assault/Raider)]],
  acceleration           = 0.0768,
  activateWhenBuilt      = true,
  brakeRate              = 0.042,
  buildAngle             = 16384,
  buildCostEnergy        = 320,
  buildCostMetal         = 320,
  builder                = false,
  buildPic               = [[CORESUPP.png]],
  buildTime              = 320,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 4 -2]],
  collisionVolumeScales  = [[25 25 90]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Corvette d'Assaut/Pillage]],
	description_de = [[Korvette (Sturmangriff/Raider)]],
	description_pl = [[Korweta]],
    helptext       = [[The Typhoon is a brawler, combining high speed, decent armor, and strong firepower at a low cost--for a ship. Use corvette packs against anything on the surface, but watch out for submarines.]],
    helptext_fr    = [[La corvette est ? la fois bon-march? et rapide. Son blindage moyen et sa forte puissance de feu laser en font un bon compromis, mais est vuln?rable aux attaques sousmarines. ]],
	helptext_de    = [[Der Typhoon ist ein Schiff, welches Geschwindigkeite, Panzerung und Feuerkraft verh�ltnism��ig g�nstig verbindet - zumindest f�r ein Schiff. Nutze Korvetten gegen alles auf der Oberfl�che, achte aber auf feindliche U-Boote.]],
	helptext_pl    = [[Korweta oferuje wysoka predkosc, duza wytrzymalosc i silne dzialka za niska (jak na statek) cene. Grupy korwet dobrze niszcza cele na powierzchni, ale nie maja obrony glebinowej.]],
    modelradius    = [[15]],
	turnatfullspeed = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[corvette]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 2200,
  maxVelocity            = 2.5,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB SINK TURRET]],
  objectName             = [[vette.s3o]],
  scale                  = [[0.5]],
  script				 = [[shipraider.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_l]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 429,
  smoothAnim             = true,
  turninplace            = 0,
  turnRate               = 480,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    EMG = {
      name                    = [[Medium Pulse MG]],
      areaOfEffect            = 36,
      burst                   = 4,
      burstrate               = 0.1,
      burnblow                = true,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      damage                  = {
        default = 13,
        planes  = 13,
        subs    = 0.5,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 280,
      reloadtime              = 0.4,
      rgbColor                = [[1 0.95 0.4]],
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/emg]],
      sprayAngle              = 1180,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 240,
    },

  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Typhoon]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 2200,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[vette_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Typhoon]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2200,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ shipraider = unitDef })
