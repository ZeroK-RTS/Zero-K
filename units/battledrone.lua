unitDef = {
  unitname            = [[battledrone]],
  name                = [[Viper]],
  description         = [[Advanced Battle Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  amphibious          = true,
  brakeRate           = 0.3,
  buildCostEnergy     = 120,
  buildCostMetal      = 120,
  builder             = false,
  buildPic            = [[battledrone.png]],
  buildTime           = 120,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  cruiseAlt           = 100,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[gunship]],
  mass                = 84,
  maxDamage           = 430,
  maxVelocity         = 5,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[battledrone.s3o]],
  reclaimable         = false,
  script              = [[battledrone.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[SMALL_BUILDINGEX]],
  
  customParams        = {
	description_de = [[Kampfdrohne]],
	description_fr = [[Drone de combat avancé]],
	description_pl = [[Dron bojowy]],
	helptext       = [[The Viper is an advanced battle drone similar to the Firefly but equipped with a Disruptor Pulse Beam, slowing its targets more with each hit.]],
	helptext_de    = [[Der Viper ist eine Kampfdrohne, die seinen Besitzer schutzt und feindliche Einheiten verlangsamt.]],
	helptext_fr    = [[Le Viper est un drone de combat agile similair au Firefly mais équipé d'un canon à électrons endommageant non seulement ses cibles mais les ralentissant progressivement, les rendant à chaque tir plus vulnérables.]],
	helptext_pl    = [[Viper to zaawansowany dron bojowy, ktory chroni wlasciciela swoim promieniem spowalniajacym.]],

	is_drone = 1,
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
    },

  },

  side                = [[ARM]],
  sightDistance       = 500,
  stealth             = true,
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 20,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    DISRUPTOR      = {
      name                    = [[Disruptor Pulse Beam]],
      areaOfEffect            = 24,
      beamdecay 				= 0.9,
      beamTime                = 0.03,
      beamttl                 = 50,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
  
      customParams			= {
	    timeslow_damagefactor = [[2]],
      },
	  
      damage                  = {
	    default = 200,
      },
  
      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 2,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/heavy_laser5]],
      soundStartVolume        = 3,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = false,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
  },

}

return lowerkeys({ battledrone = unitDef })
