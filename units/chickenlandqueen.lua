unitDef = {
  unitname               = [[chickenlandqueen]],
  name                   = [[Chicken Queen]],
  description            = [[Clucking Hell!]],
  acceleration           = 1,
  autoHeal               = 0,
  bmcode                 = [[1]],
  brakeRate              = 1,
  buildCostEnergy        = 0,
  buildCostMetal         = 0,
  builder                = false,
  buildPic               = [[chickenflyerqueen.png]],
  buildTime              = 105600,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  canSubmerge            = false,
  cantBeTransported      = true,
  category               = [[LAND]],
  collisionSphereScale   = 1,
  collisionVolumeOffsets = [[0 0 15]],
  collisionVolumeScales  = [[46 110 120]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],

  customParams           = {
    description_fr = [[Le mal incarn?!]],
    helptext       = [[Two words: RUN AWAY! The Chicken Queen is the matriach of the Thunderbird colony, and when aggravated is virtually impossible to stop. It can spit fiery napalm, spray spores to kill aircraft, and kick land units away from it. Most of all, its jaws can rip apart the largest assault mech in seconds. Only the most determined, focused assault can hope to stop this beast in her tracks.]],
    helptext_fr    = [[Deux mots : FUIS MALHEUREUX ! La reine poulet est la matriarche de la colonie et une fois sa col?re attis?e elle est presque indestructible. Elle crache un acide extr?mement corrosif, largue des poulets et envoie des spores aux unit?s volantes. Seulement les assauts les plus brutaux et coordonn?s peuvent esp?rer venir ? bout de cette monstruosit?.]],
  },

  defaultmissiontype     = [[standby]],
  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 8,
  footprintZ             = 8,
  iconType               = [[chickenq]],
  idleAutoHeal           = 0,
  idleTime               = 300,
  leaveTracks            = true,
  maneuverleashlength    = [[640]],
  mass                   = 4251,
  maxDamage              = 240000,
  maxVelocity            = 2.5,
  minCloakDistance       = 250,
  movementClass          = [[AKBOT6]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE]],
  objectName             = [[chickenflyerqueen.s3o]],
  power                  = 65536,
  script                 = [[chickenlandqueen.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                   = [[THUNDERBIRDS]],
  sightDistance          = 2048,
  smoothAnim             = true,
  sonarDistance          = 450,
  steeringmode           = [[2]],
  TEDClass               = [[KBOT]],
  trackOffset            = 18,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrack]],
  trackWidth             = 100,
  turnRate               = 399,
  upright                = false,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[MELEE]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 150,
      onlyTargetCategory = [[SWIM LAND SUB SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[FIREGOO]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 150,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[QUEENCRUSH]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    FIREGOO    = {
      name                    = [[Napalm Goo]],
      areaOfEffect            = 256,
      burst                   = 8,
      burstrate               = 0.01,
      cegTag                  = [[queen_trail_fire]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 400,
        planes  = 400,
        subs    = 2,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NAPALM_Expl]],
      firestarter             = 400,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      proximityPriority       = -4,
      range                   = 1200,
      reloadtime              = 6,
      renderType              = 4,
      rgbColor                = [[0.8 0.4 0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[weapon/burn_mixed]],
      soundStart              = [[chickens/bigchickenroar]],
      sprayAngle              = 6100,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.2,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
    },


    MELEE      = {
      name                    = [[ChickenClaws]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 1000,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 1,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 200,
      reloadtime              = 0.8,
      size                    = 0,
      soundStart              = [[chickens/bigchickenbreath]],
      startsmoke              = [[0]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
    },


    QUEENCRUSH = {
      name                    = [[ChickenKick]],
      areaOfEffect            = 400,
      collideFriendly         = false,
      craterBoost             = 0.001,
      craterMult              = 0.002,

      damage                  = {
        default    = 10,
        chicken    = 0.001,
        commanders = 1,
        planes     = 10,
        subs       = 5,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 500,
      impulseFactor           = 1,
      intensity               = 1,
      interceptedByShieldType = 1,
      lineOfSight             = false,
      noSelfDamage            = true,
      range                   = 512,
      reloadtime              = 1,
      renderType              = 4,
      rgbColor                = [[1 1 1]],
      thickness               = 1,
      tolerance               = 100,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 0.8,
    },


    SPORES     = {
      name                    = [[Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 8,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 75,
        planes  = [[150]],
        subs    = 7.5,
      },

      dance                   = 60,
      dropped                 = 1,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 5,
      groundbounce            = 1,
      guidance                = true,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[chickeneggpink.s3o]],
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 4,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      startsmoke              = [[1]],
      startVelocity           = 100,
      texture1                = [[]],
      texture2                = [[sporetrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 32000,
    },

  },

}

return lowerkeys({ chickenlandqueen = unitDef })
