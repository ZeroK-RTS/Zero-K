unitDef = {
  unitname               = [[aagunship]],
  name                   = [[Vesper]],
  description            = [[Air Defense Gunship]],
  acceleration           = 0.18,
  amphibious             = true,
  brakeRate              = 4.2,
  buildCostEnergy        = 400,
  buildCostMetal         = 400,
  builder                = false,
  buildPic               = [[aagunship.png]],
  buildTime              = 400,
  canAttack              = true,
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  corpse                 = [[DEAD]],
  cruiseAlt              = 180,

  customParams           = {
    airstrafecontrol = [[1]],
    --description_bp = [[Aeronave flutuadora agressora]],
    --description_fr = [[ADAV Pilleur]],
	description_de = [[Flugabwehr Hubschrauber]],
    helptext       = [[The Vesper is a moderately fast gunship that cuts down enemy aircraft with its pulse lasers.]],
    --helptext_bp    = [[A aeronave flutuante agressora leve de Logos. Seus mísseis s?o precisos e pode atingir o ar, tornando-a útil contra alvos pequenos e outras aeronaves agressoras.]],
    --helptext_fr    = [[des missiles pr?cis et une vitesse de vol appr?ciable, le Rapier saura vous d?fendre contre d'autres pilleurs ou mener des assauts rapides.]],
	--helptext_de    = [[Der Rapier ist ein leichter Raiderhubschrauber. Seine Raketen sind akkurat und treffen auch Lufteinheiten. Des Weiteren erweist er sich gegen kleine Ziele und als Gegenwehr gegen andere Raider als sehr nützlich.]],
	modelradius    = [[16]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  hoverAttack            = true,
  iconType               = [[gunship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 208,
  maxDamage              = 1250,
  maxVelocity            = 5,
  minCloakDistance       = 75,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[aagunship.s3o]],
  seismicSignature       = 0,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rapiermuzzle]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 600,
  smoothAnim             = true,
  turnRate               = 594,
  workerTime             = 0,

  weapons                = {
  
    {
      def                = [[AA_LASER]],
	  mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },
	
  },

  weaponDefs             = {
  
    AA_LASER      = {
      name                    = [[Anti-Air Laser]],
      areaOfEffect            = 16,
      beamDecay               = 0.736,
      beamTime                = 0.01,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,

      damage                  = {
        default = 3.5,
        planes  = 35,
        subs    = 1.75,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
	  projectiles             = 2,
      range                   = 700,
      reloadtime              = 0.5,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 3,
      tolerance               = 8192,
      turret                  = false,
      weaponType              = [[BeamLaser]],
    },
	
  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Vesper]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1250,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[aagunship_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
    },

    
    HEAP  = {
      description      = [[Debris - Vesper]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1250,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
    },

  },

}

return lowerkeys({ aagunship = unitDef })
