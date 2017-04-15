unitDef = {
  unitname               = [[chickenq]],
  name                   = [[Chicken Queen]],
  description            = [[Clucking Hell!]],
  acceleration           = 1,
  autoHeal               = 0,
  brakeRate              = 3,
  buildCostEnergy        = 0,
  buildCostMetal         = 0,
  builder                = false,
  buildPic               = [[chickenq.png]],
  buildTime              = 105600,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  cantBeTransported      = true,
  category               = [[LAND]],
  collisionSphereScale   = 1,
  collisionVolumeOffsets = [[0 0 15]],
  collisionVolumeScales  = [[46 110 120]],
  collisionVolumeType    = [[box]],

  customParams           = {
    description_fr = [[Le mal incarn?!]],
	description_de = [[Lachende Hˆllenbrut!]],
    helptext       = [[Two words: RUN AWAY! The Chicken Queen is the matriach of the Thunderbird colony, and when aggravated is virtually impossible to stop. It can spit acid, spray spores to kill aircraft, and kick land units away from it. Most of all, its jaws can rip apart the largest assault mech in seconds. Only the most determined, focused assault can hope to stop this beast in her tracks.]],
    helptext_fr    = [[Deux mots : FUIS MALHEUREUX ! La reine poulet est la matriarche de la colonie et une fois sa col?re attis?e elle est presque indestructible. Elle crache un acide extr?mement corrosif, largue des poulets et envoie des spores aux unit?s volantes. Seulement les assauts les plus brutaux et coordonn?s peuvent esp?rer venir ? bout de cette monstruosit?.]],
	helptext_de    = [[Zwei Worte: LAUF WEG! Die Chicken Queen ist die Matriarchin der Thunderbirdkolonie und sobald ver‰rgert ist es eigentlich unmˆglich sie noch zu stoppen. Sie kann kraftvolle S‰ure spucken, Landchicken abwerfen und Sporen gegen Lufteinheiten versprÅEen. Nur der entschlossenste und konzentrierteste Angriff kann es ermˆglichen dieses Biest eventuell doch noch zu stoppen.]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 8,
  footprintZ             = 8,
  iconType               = [[chickenq]],
  idleAutoHeal           = 0,
  idleTime               = 300,
  leaveTracks            = true,
  maxDamage              = 200000,
  maxVelocity            = 2.5,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE]],
  objectName             = [[chickenq.s3o]],
  power                  = 65536,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance          = 2048,
  sonarDistance          = 450,
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
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[GOO]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[QUEENCRUSH]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    GOO        = {
      name                    = [[Blob]],
      areaOfEffect            = 256,
      burst                   = 8,
      burstrate               = 0.01,
      cegTag                  = [[queen_trail]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 800,
        planes  = 800,
        subs    = 4,
      },

      explosionGenerator      = [[custom:large_green_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      proximityPriority       = -4,
      range                   = 1200,
      reloadtime              = 6,
      rgbColor                = [[0.2 0.6 0]],
      size                    = 8,
      sizeDecay               = 0,
      soundStart              = [[chickens/bigchickenroar]],
      sprayAngle              = 6100,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
    },


    MELEE      = {
      name                    = [[Chicken Claws]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default = 2000,
        planes  = 2000,
        subs    = 2000,
      },

      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 1,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 200,
      reloadtime              = 0.4,
      size                    = 0,
      soundStart              = [[chickens/bigchickenbreath]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
    },


    QUEENCRUSH = {
      name                    = [[Chicken Kick]],
      areaOfEffect            = 400,
      collideFriendly         = false,
      craterBoost             = 0.001,
      craterMult              = 0.002,

      customParams           = {
	lups_noshockwave = "1",
      },      
      
      damage                  = {
        default    = 10,
        chicken    = 0.001,
        planes     = 10,
        subs       = 5,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 2000,
      impulseFactor           = 1,
      intensity               = 1,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 512,
      reloadtime              = 1,
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
      
      customParams            = {
        light_radius = 0,
      },

      damage                  = {
        default = 75,
        planes  = [[150]],
        subs    = 7.5,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 5,
      groundbounce            = 1,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[chickeneggpink.s3o]],
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 4,
      smokeTrail              = true,
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

return lowerkeys({ chickenq = unitDef })
