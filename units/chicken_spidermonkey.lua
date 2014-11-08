unitDef = {
  unitname            = [[chicken_spidermonkey]],
  name                = [[Spidermonkey]],
  description         = [[All-Terrain Support]],
  acceleration        = 0.36,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_spidermonkey.png]],
  buildTime           = 500,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Lanceur de filet tout terrain]],
	description_de = [[Gelandegängige Luftabwehr]],
	description_pl = [[Terenowe wsparcie]],
    helptext       = [[The Spidermonkey is a very unusual support chicken. As the name suggests, it can climb walls, however it can also spin a silk line that slows and yanks enemies.]],
    helptext_fr    = [[Le spidermonkey est une unit? de soutien tr?s inhabituelle parmis les poulets. Comme le nom l'indique il peut grimper les parois les plus escarp?es mais peut en plus projetter comme une fronde un filet pour bloquer au sol les unit?s a?riennes, ? la mani?re d'une araign?e attrappant des insectes.]],
	helptext_de    = [[Der Spidermonkey ist ein sehr ungewöhnliches Chicken. Wie der Name verrät, kann er Wände hochklettern und schließlich auch wie eine Spinne per Netz seine Fliegen, bzw. Flugzeuge Luft fangen.]],
	helptext_pl    = [[Spidermonkey wije i wypluwa siec, ktora utrudnia ruch i atak trafionym jednostkom; moze takze wspinac sie na strome wzniesienia.]],
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[spiderskirm]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  mass                = 253,
  maxDamage           = 1500,
  maxSlope            = 72,
  maxVelocity         = 2.2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[ATKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER STUPIDTARGET MINE]],
  objectName          = [[chicken_spidermonkey.s3o]],
  power               = 500,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 700,
  smoothAnim          = true,
  sonarDistance       = 450,
  trackOffset         = 0.5,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = [[ChickenTrackPointy]],
  trackWidth          = 70,
  turnRate            = 1200,
  upright             = false,
  workerTime          = 0,

  weapons             = {
    {
      def                = [[WEB]],
	  badTargetCategory	 = [[UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
	  mainDir            = [[0 0 1]],
      maxAngleDif        = 180,	  
    },

    --{
    --  def                = [[SPORES]],
    --  badTargetCategory  = [[SWIM LAND SHIP HOVER]],
    --  onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    --},

  },


  weaponDefs          = {

    SPORES = {
      name                    = [[Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 5,
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
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = 1,
      flightTime              = 5,
      groundbounce            = 1,
      guidance                = true,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[chickeneggpink.s3o]],
      range                   = 600,
      reloadtime              = 6,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundstart              = [[weapon/hiss]],
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


    WEB    = {
      name                    = [[Web Weapon]],
      accuracy                = 800,
      
      customParams            = {
        impulse = [[-200]],
        timeslow_damagefactor = 1,
        timeslow_onlyslow = 1,
        timeslow_smartretarget = 0.33,
      },
      
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 30,
        subs    = 0.75,
      },

      dance                   = 150,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      fixedlauncher           = true,
      flightTime              = 3,
      impactOnly              = true,
      interceptedByShieldType = 2,
      range                   = 600,
      reloadtime              = 0.1,
      selfprop                = true,
      smokeTrail              = true,
      soundstart              = [[chickens/web]],
      startsmoke              = [[1]],
      startVelocity           = 600,
      texture2                = [[smoketrailthin]],
      tolerance               = 63000,
      tracks                  = true,
      turnRate                = 90000,
      turret                  = true,
      weaponAcceleration      = 400,
      weaponTimer             = 1,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 2000,
    },

  },

}

return lowerkeys({ chicken_spidermonkey = unitDef })
