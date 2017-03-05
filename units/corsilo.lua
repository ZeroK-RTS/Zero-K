unitDef = {
  unitname                      = [[corsilo]],
  name                          = [[Silencer]],
  description                   = [[Strategic Nuclear Launcher, Drains 18 m/s, 3 minute stockpile]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 8000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 10,
  buildingGroundDecalSizeY      = 10,
  buildingGroundDecalType       = [[corsilo_aoplane.dds]],
  buildPic                      = [[CORSILO.png]],
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Lance Missile Ballistique Intercontinental Nucl?aire (Nuke)]],
	description_de = [[Abschuß für atomare Interkontinentalraketen, Benötigt 18 M/s und 3 Minuten zum Bevorraten]],
    helptext       = [[The Silencer launches devastating nuclear missiles that can obliterate entire bases. However, it is easily defeated by enemy anti-nuke systems, which must be removed from the desired target area beforehand.]],
    helptext_fr    = [[Le Silencer est long a construire, et il faut qui plus est, ordonner la creation de missiles une fois celui-ci construit. Et pourtant, quel bonheur de r?duire tous vos ennemis en poussi?re en une seconde! Pensez ? v?rifier la pr?sence d'une contre mesure AntiNuke.]],
	helptext_de    = [[Der Silencer verschießt verwüstende, atomare Raketen, die ganze Basen in Schutt und Asche legen können. Trotzdem kann es von einem feindlichen Anti-Atomsystem geschlagen werden. Aus diesem Grund solltest du dieses zunächst vernichten, bevor du deine Raketen abschießt.]],
	stockpiletime  = [[180]],
	stockpilecost  = [[3240]],
	priority_misc  = 1, -- Medium
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 6,
  footprintZ                    = 8,
  iconType                      = [[nuke]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 5000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[Silencer.s3o]],
  script                        = [[corsilo.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardmap                       = [[oooooooooooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {

    {
      def                = [[CRBLMSSL]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs                    = {

    CRBLMSSL = {
      name                    = [[Strategic Nuclear Missile]],
      areaOfEffect            = 1920,
      cegTag                  = [[NUCKLEARMINI]],
      collideFriendly         = false,
      collideFeature          = false,
      commandfire             = true,
      craterBoost             = 6,
      craterMult              = 6,

	  customParams        	  = {
		light_color = [[2.92 2.64 1.76]],
		light_radius = 3000,
	  },

      damage                  = {
        default = 11501.1,
      },

      edgeEffectiveness       = 0.3,
      explosionGenerator      = [[custom:LONDON]],
      fireStarter             = 0,
      flightTime              = 180,
      impulseBoost            = 0.5,
      impulseFactor           = 0.2,
      interceptedByShieldType = 65,
      model                   = [[crblmsslr.s3o]],
      noSelfDamage            = false,
      range                   = 72000,
      reloadtime              = 5,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_ultra8]],
      startVelocity           = 800,
      stockpile               = true,
      stockpileTime           = 10^5,
      targetable              = 1,
      texture1                = [[null]], --flare
      tolerance               = 4000,
      weaponAcceleration      = 0,
      weaponTimer             = 10,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 800,
    },

  },


  featureDefs                   = {

    DEAD  = {
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 8,
      object           = [[silencer_dead.s3o]],
    },

    HEAP  = {
      footprintX       = 6,
      footprintZ       = 8,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ corsilo = unitDef })
