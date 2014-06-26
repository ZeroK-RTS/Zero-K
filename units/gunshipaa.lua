unitDef = {
  unitname               = [[gunshipaa]],
  name                   = [[Trident]],
  description            = [[AA Gunship]],
  acceleration           = 0.18,
  airStrafe              = 0,
  amphibious             = true,
  bankingAllowed         = false,
  brakeRate              = 0.5,
  buildCostEnergy        = 320,
  buildCostMetal         = 320,
  builder                = false,
  buildPic               = [[gunshipaa.png]],
  buildTime              = 320,
  canAttack              = true,
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[36 36 36]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  collide                = true,
  corpse                 = [[DEAD]],
  cruiseAlt              = 110,

  customParams           = {
    --description_bp = [[Aeronave flutuadora agressora]],
    --description_fr = [[ADAV Pilleur]],
	description_de = [[Flugabwehr Hubschrauber]],
	description_pl = [[Przeciwlotniczy statek powietrzny]],
    helptext       = [[The Trident is a slow gunship that cuts down enemy aircraft with missiles. It is much slower than other gunships, so it is much easier to kill the Trident with ground units than with planes.]],
    --helptext_bp    = [[A aeronave flutuante agressora leve de Logos. Seus mísseis s?o precisos e pode atingir o ar, tornando-a útil contra alvos pequenos e outras aeronaves agressoras.]],
    --helptext_fr    = [[des missiles pr?cis et une vitesse de vol appr?ciable, le Rapier saura vous d?fendre contre d'autres pilleurs ou mener des assauts rapides.]],
	--helptext_de    = [[Der Rapier ist ein leichter Raiderhubschrauber. Seine Raketen sind akkurat und treffen auch Lufteinheiten. Des Weiteren erweist er sich gegen kleine Ziele und als Gegenwehr gegen andere Raider als sehr nützlich.]],
	helptext_pl    = [[Trident to wolny statek powietrzny, ktory niszczy lotnictwo silnymi rakietami. Jego szybkosc i niski pulap sprawiaja jednak, ze mozna go latwo zniszczyc jednostkami naziemnymi.]],
	modelradius    = [[18]],
	midposoffset   = [[0 15 0]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  hoverAttack            = true,
  iconType               = [[gunshipaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 208,
  maxDamage              = 1200,
  maxVelocity            = 3.6,
  minCloakDistance       = 75,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[trifighter.s3o]],
  script                 = [[gunshipaa.lua]],
  seismicSignature       = 0,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rapiermuzzle]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 660,
  smoothAnim             = true,
  turnRate               = 0,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[AA_MISSILE]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    AA_MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 48,
	  avoidFeature            = false,
      canattackground         = false,
      cegTag                  = [[missiletrailblue]],
	  collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
		script_reload = [[11]],
		script_burst = [[3]],
	  },

      damage                  = {
        default = 18,
        planes  = 180,
        subs    = 3.5,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_fury.s3o]],
      noSelfDamage            = true,
      range                   = 750,
      reloadtime              = 1.2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 650,
      texture2                = [[AAsmoketrail]],
	  texture3                = [[null]],
      tolerance               = 32767,
      tracks                  = true,
      turnRate                = 90000,
      twoPhase                = true,
      vlaunch                 = true,
      turret                  = false,
      weaponAcceleration      = 550,
      weaponTimer             = 0.2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 700,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Trident]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[trifighter_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
    },

    
    HEAP  = {
      description      = [[Debris - Trident]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
    },

  },

}

return lowerkeys({ gunshipaa = unitDef })
