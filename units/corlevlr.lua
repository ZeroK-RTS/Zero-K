unitDef = {
  unitname            = [[corlevlr]],
  name                = [[Leveler]],
  description         = [[Riot Vehicle]],
  acceleration        = 0.0318,
  brakeRate           = 0.124,
  buildCostEnergy     = 240,
  buildCostMetal      = 240,
  builder             = false,
  buildPic            = [[corlevlr.png]],
  buildTime           = 240,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,	
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Veículo dispersador.]],
    description_fr = [[V?hicule ?meutier]],
	description_de = [[Riotfahrzeug]],
	description_pl = [[Pojazd wsparcia]],
    helptext       = [[The Leveler's riot cannon is effective at destroying swarms of raiders and halting enemy advances. The projectile does not arc, so Levelers should avoid clumping and be arranged in a line formation wherever possible. Due to their lack of speed and range, most skirmishers are effective against them. True to its name the Leveler's cannon flattens terrain to enable allied vehicles passage over harsh terrain.]],
    helptext_bp    = [[Leveler é um tanque dispesador. com um canh?o poderoso e agilidade decente, é excelente em uma situaç?o de combate. Seus tiros tem área de efeito portanto embora sejam eficientes contra inimigos agrupados, o Leveler tamb?m tomara dano se atirar de muito perto.]],
    helptext_fr    = [[Le Leveler est un tank ?meutier. Tr?s efficace en situation de combat, il se distingue par sa manoeuvrabilit? et le tir imm?diat de son canon principal. Attention cependant, le canon ? une zone d'effet ? l'impact, le Leveler s'inflige donc parfois des d?g?ts ? lui m?me.]],
	helptext_de    = [[Seine Riotkanone ist sehr effektiv gegen größere Gruppen von Raidern und, um den gegnerischen Fortschritt aufzuhalten. Die Projektile können nicht bogenförmig abgeschoßen werden, weshalb sie nicht in einem Haufen, sondern entlang einer Frontlinie, ausgerichtet werden sollten. Durch ihren Mangel an Geschwindigkeit und Reichweite, sind sie für die meisten Skirmisher ein gefundenes Fressen.]],
	helptext_pl    = [[Dzialo Levelera skutecznie niszczy grupy lzejszych jednostek, jednak musi miec czysta linie strzalu, zatem w miare mozliwosci Levelery nalezy zawsze ustawiac w linii. Slabosciami Levelera sa niska szybkosc i zasieg. Pociski Levelera wyrownuja teren, co moze ulatwic pojazdom przejazd po nierownym terenie.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[vehicleriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 180,
  maxDamage           = 1100,
  maxSlope            = 18,
  maxVelocity         = 2.2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[corleveler_512.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX_LEVELER]],
  script              = [[corlevlr.lua]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RIOT_SHELL_L]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 347,
  smoothAnim          = true,
  trackOffset         = 7,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turninplace         = 0,
  turnRate            = 442,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[CORLEVLR_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    CORLEVLR_WEAPON = {
      name                    = [[Impulse Cannon]],
      areaOfEffect            = 144,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      craterBoost             = 1,
      craterMult              = 0.5,

      customParams            = {
	gatherradius = [[90]],
	smoothradius = [[60]],
	smoothmult   = [[0.08]],
      },
	  
      damage                  = {
        default = 220.2,
        planes  = 220.2,
        subs    = 11,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:FLASH64]],
      impulseBoost            = 30,
      impulseFactor           = 0.6,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 290,
      reloadtime              = 1.8,
      soundHit                = [[weapon/cannon/generic_cannon]],
      soundStart              = [[weapon/cannon/outlaw_gun]],
      soundStartVolume        = 3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 750,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Leveler]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1100,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 96,
      object           = [[leveler_d.dae]],
      reclaimable      = true,
      reclaimTime      = 96,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Leveler]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 96,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 96,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Leveler]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 48,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 48,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corlevlr = unitDef })
