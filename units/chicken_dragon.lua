unitDef = {
  unitname               = [[chicken_dragon]],
  name                   = [[White Dragon]],
  description            = [[Uber Assault Chicken]],
  acceleration           = 1,
  autoHeal               = 0,
  bmcode                 = [[1]],
  brakeRate              = 1,
  buildCostEnergy        = 0,
  buildCostMetal         = 0,
  builder                = false,
  buildPic               = [[chicken_dragon.png]],
  buildTime              = 10500,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  canSubmerge            = false,
  cantBeTransported      = true,
  category               = [[LAND]],
  collisionSphereScale   = 1,
  collisionVolumeOffsets = [[0 0 7.5]],
  collisionVolumeScales  = [[23 55 60]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],

  customParams           = {
    description_fr = [[Unit? d'assaut poulet ultra lourde]],
	description_de = [[Über Sturmchicken]],
    helptext       = [[The White Dragons, senior guardians of the chicken hive, are monstrous beings second only to the queen herself. With a powerful stomp, lethal jaws, corrosive goo and a multitude of spores, they are a threat to be feared indeed.]],
    helptext_fr    = [[Les White Dragons, gardiens s?culaires des nids poulet sont d'immenses cr?atures monstrueuses extr?mement f?roces. Capables d'?craser sous leur poids leurs adversaires, de broyer les alliages les plus robustes avec leur m?choire, de projeter leur bave corrosive et de cribler les unit?s a?riennes d'un amas de spores corrosifs, leur simple apparition sur le champ de bataille glace le sang.]],
	helptext_de    = [[Der White Dragon ist ein außerordentlich monströses Wesen. Mit kraftvollen Stampfern, todbringendem Maul, ätzendem Schleim und einer Vielzahl von Sporen stellt er eine bedrohliche und furchteinflößende Gefahr dar.]],
  },

  defaultmissiontype     = [[standby]],
  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 5,
  footprintZ             = 5,
  iconType               = [[chickenminiq]],
  idleAutoHeal           = 5,
  idleTime               = 300,
  leaveTracks            = true,
  maneuverleashlength    = [[640]],
  mass                   = 1284,
  maxDamage              = 30000,
  maxSlope               = 18,
  maxVelocity            = 2.1,
  minCloakDistance       = 225,
  movementClass          = [[AKBOT6]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE]],
  objectName             = [[chicken_dragon.s3o]],
  power                  = 10500,
  script                 = [[chickenq.cob]],
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
  sightDistance          = 1200,
  smoothAnim             = true,
  sonarDistance          = 450,
  steeringmode           = [[2]],
  TEDClass               = [[KBOT]],
  trackOffset            = 18,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrack]],
  trackWidth             = 100,
  turninplace            = 0,
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
      def                = [[GOO]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[QUEENCRUSH]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    GOO        = {
      name                    = [[Blob]],
      areaOfEffect            = 160,
      burst                   = 8,
      burstrate               = 0.01,
      cegTag                  = [[queen_trail]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 500,
        planes  = 500,
        subs    = 2.5,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:large_green_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      proximityPriority       = -4,
      range                   = 700,
      reloadtime              = 8,
      renderType              = 4,
      rgbColor                = [[0.2 0.6 0]],
      size                    = 5,
      sizeDecay               = 0,
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
      name                    = [[Chicken Jaws]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default = 300,
        planes  = 300,
        subs    = 300,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 1,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 160,
      reloadtime              = 0.6,
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
      name                    = [[Chicken Kick]],
      areaOfEffect            = 300,
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
      impulseBoost            = 300,
      impulseFactor           = 1,
      intensity               = 1,
      interceptedByShieldType = 1,
      lineOfSight             = false,
      noSelfDamage            = true,
      range                   = 384,
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
      burst                   = 5,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 60,
        planes  = 60,
        subs    = 6,
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
      reloadtime              = 5,
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

return lowerkeys({ chicken_dragon = unitDef })
