unitDef = {
  unitname               = [[armkam]],
  name                   = [[Banshee]],
  description            = [[Raider Gunship]],
  acceleration           = 0.154,
  amphibious             = true,
  bankscale              = [[1]],
  brakeRate              = 3.75,
  buildCostEnergy        = 220,
  buildCostMetal         = 220,
  builder                = false,
  buildPic               = [[ARMKAM.png]],
  buildTime              = 220,
  canAttack              = true,
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  collisionVolumeOffsets = [[0 0 -5]],
  collisionVolumeScales  = [[42 24 42]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 100,

  customParams           = {
    description_bp = [[Aeronave agressora]],
    description_fr = [[ADAV Pilleur]],
	description_de = [[Plünder Kampfhubschrauber]],
    helptext       = [[The Banshee is a light gunship. Its high speed and good upfront damage makes it excellent for quickly taking out enemy economy or inaccurate units like assaults. However, it flies close to the ground and has a short range, meaning even other raiders can engage it on an equal footing, so like any raider, the Banshee should avoid riots and static defense.]],
    helptext_bp    = [[Banshee é a aeronave agressora leve de Nova. Tem uma resist?ncia decente mas causa pouco dano. Funciona bem contra poderio anti-aério pouco resistente, sendo capaz de destruílo e ent?o atacar o resto do inimigo com impunidade por algum tempo, mas funciona mal contra poderio anti-aéreo pesado como metralhadoras anti-aéreas. Pode facilmente acertar unidades móveis e constitui defesa excelente contra inimigos que n?o incluem unidades anti-aéreas em seus grupos de ataque.]],
    helptext_fr    = [[Le Banshee est un ADAV l?ger, un blindage l?ger et peu de d?g?ts en font la hantise des d?buts de conflits. Envoy? dans une base non pr?par?e ou contre une arm?e sans d?fense Anti Air, son attaque rapide est bien souvent fatale.]],
	helptext_de    = [[Der Banshee ist ein leichter Kampfhubschrauber. Er besitzt nur wenig Ausdauer und macht wenig DPS. Er ist gut für direkte Attacken auf die Verteidiger (z.B. um Luftabwehr auszuschalten). Er trifft bewegte Einheiten sehr gut und erweist sich auch bei Verteidigung gegen Gegner ohne Luftabwehr als sehr nützlich.]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  hoverAttack            = true,
  iconType               = [[gunship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 164,
  maxDamage              = 860,
  maxVelocity            = 6.5,
  minCloakDistance       = 75,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[banshee.s3o]],
  scale                  = [[1]],
  seismicSignature       = 0,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:VINDIBACK]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 500,
  smoothAnim             = true,
  turnRate               = 693,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LASER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    LASER = {
      name                    = [[Light Laserbeam]],
      areaOfEffect            = 8,
      avoidFeature            = false,
      beamlaser               = 1,
      beamTime                = 0.12,
      collideFriendly         = false,
      coreThickness           = 0.3,
      craterBoost             = 0,
      craterMult              = 0,
	  --cylinderTargetting	  = 1,

      damage                  = {
        default = 6,
        subs    = 0.3,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:flash1red]],
	  --heightMod				  = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 2,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      pitchtolerance          = [[12000]],
      range                   = 250,
      reloadtime              = 0.11,
      renderType              = 0,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/laser_burn9]],
      startsmoke              = [[0]],
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 2,
      tolerance               = 2000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Banshee]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1100,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[banshee_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Banshee]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 50,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armkam = unitDef })
