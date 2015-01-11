unitDef = {
  unitname                      = [[armanni]],
  name                          = [[Annihilator]],
  description                   = [[Tachyon Projector - Requires 50 Power]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 2200,
  buildCostMetal                = 2200,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[armanni_aoplane.dds]],
  buildPic                      = [[ARMANNI.png]],
  buildTime                     = 2200,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  --collisionVolumeScales         = [[75 100 75]],
  --collisionVolumeTest           = 1,
  --collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Acc?lerateur Tachyon]],
    description_de = [[Tachyonen Beschleuniger - BenÃ¶tigt ein angeschlossenes Stromnetz von 50 Energie, um feuern zu kÃ¶nnen.]],
    description_pl = [[Projektor Tachyonow]],
    helptext       = [[Inside the heavily armored shell of the Annihilator lies the devastating Tachyon Accelerator. This fearsome weapon is capable of delivering pinpoint damage at extreme ranges, provided you keep it connected to a power source. Remember that the Annihilator is strictly a support weapon; leave it unguarded and it will be swamped with raiders. When under attack by long range artillery or bombers the main gun can retract to reduce incoming damage to a quarter.]],
    helptext_fr    = [[ProtÃ©gÃ© derri?re le blindage lourd de l'Annihilator se trouve le terrible Canon AccÃ©lerateur de Tachyon. Cette arme terrifiante est capable d'envoyer des quantitÃ©s colossales d'Ã©nergie sur un point prÃ©cis, percant tous les blindages aisÃ©ment, le tout ? une distance terrifiante. Son co?t et sa consommation d'Ã©nergie la rendent cependant difficile ? employer.]],
    helptext_de    = [[Innerhalb der hart gepanzerten HÃ¼lle befindet sich ein verheerender Tachyonen Beschleuniger. Diese furchteinregende Waffe ist imstande in einem riesigen Umkreis punktgenaue ZerstÃ¶rung nach sich zu ziehen, vorausgesetzt du verbindest es mit einer Energiequelle. Beachte aber, dass der Anniilator eine dezidierte UnterstÃ¼tzungswaffe ist; unbewacht wird er schnell von Angreifern Ã¼berrumpelt.]],
    helptext_pl    = [[Pod ciezkim pancerzem Annihilatora znajduje sie niszczycielski Projektor Tachyonow. Ta straszliwa bron pozwala na zadawanie wysokich obrazen oddalonym celom zakladajac, ze masz dosc energii, by ja zasilic - musi znajdowac sie w sieci energetycznej o mocy co najmniej 50 energii. Mimo swej mocy Annihilator nie jest odpowiedzia na wszystkie problemy - ma niska szybkostrzelnosc, co czyni go podatnym na ataki wielu lekkich jednostek. W razie ostrzalu artylerii lub nalotu mozna schowac dzialo, co nie pozwala na strzelanie, ale zmniejsza otrzymywane obrazenia czterokrotnie.]],

    keeptooltip    = [[any string I want]],

    neededlink     = 50,
    pylonrange     = 50,

    aimposoffset   = [[0 32 0]],
    midposoffset   = [[0 0 0]],
    modelradius    = [[40]],

    dontfireatradarcommand = '1',
  },

  damageModifier                = 0.25,
  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[fixedtachyon]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 6000,
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[arm_annihilator.s3o]],
  onoffable                     = true,
  script                        = [[armanni.lua]],
  seismicSignature              = 4,
  explodeAs                     = [[ESTOR_BUILDING]],
  sightDistance                 = 780,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oooo oooo oooo oooo]],

  weapons                       = {

    {
      def                = [[ATA]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },

  },

  weaponDefs                    = {

    ATA = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 20,
      avoidFeature            = false,
      avoidNeutral            = false,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        statsprojectiles = 1,
        statsdamage = 4000,
      },

      damage                  = {
        default = 810,
        subs    = 40,
      },

      explosionGenerator      = [[custom:ataalaser]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 16.94,
      minIntensity            = 1,
      noSelfDamage            = true,
      projectiles             = 5,
      range                   = 1200,
      reloadtime              = 10,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
      soundStartVolume        = 3,
      targetMoveError         = 0.3,
      texture1                = [[largelaserdark]],
      texture2                = [[flaredark]],
      texture3                = [[flaredark]],
      texture4                = [[smallflaredark]],
      thickness               = 16.94,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1400,
    },

  },

  featureDefs                   = {

    DEAD = {
      description      = [[Wreckage - Annihilator]],
      blocking         = true,
      damage           = 6000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      metal            = 880,
      object           = [[arm_annihilator_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 880,
    },


    HEAP = {
      description      = [[Debris - Annihilator]],
      blocking         = false,
      damage           = 6000,
      energy           = 0,
      footprintX       = 4,
      footprintZ       = 4,
      metal            = 440,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 440,
    },

  },

}

return lowerkeys({ armanni = unitDef })
