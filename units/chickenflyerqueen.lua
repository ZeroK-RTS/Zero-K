unitDef = {
  unitname            = [[chickenflyerqueen]],
  name                = [[Chicken Flyer Queen]],
  description         = [[Clucking Hell!]],
  acceleration        = 1.2,
  airHoverFactor      = 0,
  brakeRate           = 0.8,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenflyerqueen.png]],
  buildTime           = 40000,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  cruiseAlt           = 150,

  customParams        = {
    description_fr = [[L'enfer volant !]],
	description_de = [[Lachende Höllenbrut!]],
    helptext       = [[Two words: RUN AWAY! The Chicken Queen is the matriach of the Thunderbird colony, and when aggravated is virtually impossible to stop. She can spit immensely powerful acid, drop land chickens, and spray spores to kill aircraft. Only the most determined, focused assault can hope to stop this beast in her tracks.]],
    helptext_fr    = [[Deux mots : FUIS MALHEUREUX ! La reine poulet est la matriarche de la colonie et une fois sa col?re atis?e elle est presque indestructible. Elle crache un acide extr?mement corrosif, largue des poulets et envoie des spores aux unit?s volantes. Seuls les assauts les plus brutaux et les mieux coordonn?s peuvent esp?rer venir ? bout de cette monstruosit?.]],
	helptext_de    = [[Zwei Worte: LAUF WEG! Die Chicken Queen ist die Matriarchin der Thunderbirdkolonie und sobald verärgert ist es eigentlich unmöglich sie noch zu stoppen. Sie kann kraftvolle Säure spucken, Landchicken abwerfen und Sporen gegen Lufteinheiten versprühen. Nur der entschlossenste und konzentrierteste Angriff kann es ermöglichen dieses Biest eventuell doch noch zu stoppen.]],
  },

  explodeAs           = [[NOWEAPON]],
  floater             = true,
  footprintX          = 8,
  footprintZ          = 8,
  hoverattack         = true,
  iconType            = [[chickenq]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[64000]],
  maxDamage           = 150000,
  maxSlope			  = 36,
  maxVelocity         = 3,
  minCloakDistance    = 250,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP STUPIDTARGET MINE]],
  objectName          = [[chickenflyerqueen.s3o]],
  power               = 45000,
  script              = [[chickenflyerqueen.lua]],
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 4096,
  turnRate            = 900,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[GOO]],
      badTargetCategory  = [[GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
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
      def                = [[DODOBOMB]],
      onlyTargetCategory = [[NONE]],
    },


    {
      def                = [[BASILISKBOMB]],
      onlyTargetCategory = [[NONE]],
    },


    {
      def                = [[TIAMATBOMB]],
      onlyTargetCategory = [[NONE]],
    },

  },


  weaponDefs          = {

    BASILISKBOMB = {
      name                    = [[Basilisk Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      
      customparams            = {
      	spawns_name = "chickenc",
      	spawns_expire = 0,
      },

      damage                  = {
        default = 180,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      model                   = [[chickenc.s3o]],
      range                   = 500,
      reloadtime              = 10,
      smokeTrail              = false,
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },


    DODOBOMB     = {
      name                    = [[Dodo Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 1,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customparams            = {
      	spawns_name = "chicken_dodo",
      	spawns_expire = 30,
      },

      damage                  = {
        default = 1,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      model                   = [[chicken_dodobomb.s3o]],
      range                   = 500,
      reloadtime              = 10,
      smokeTrail              = false,
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },


    GOO          = {
      name                    = [[Blob]],
      areaOfEffect            = 200,
      burst                   = 8,
      burstrate               = 0.01,
      cegTag                  = [[queen_trail]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1500,
        planes  = 1500,
        subs    = 30,
      },

      explosionGenerator      = [[custom:large_green_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      proximityPriority       = -4,
      range                   = 500,
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


    SPORES       = {
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
      fixedlauncher           = true,
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
      range                   = 500,
      reloadtime              = 4,
      smokeTrail              = true,
      sprayangle              = 4096,
      startVelocity           = 200,
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


    TIAMATBOMB   = {
      name                    = [[Tiamat Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 72,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      
      customparams            = {
      	spawns_name = "chicken_tiamat",
      	spawns_expire = 0,
      },

      damage                  = {
        default = 350,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      model                   = [[chickenbroodqueen.s3o]],
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 10,
      smokeTrail              = false,
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },

  },

}

return lowerkeys({ chickenflyerqueen = unitDef })
