unitDef = {
  unitname            = [[armmerl]],
  name                = [[Impaler]],
  description         = [[Kinetic Missile Artillery]],
  acceleration        = 0.042,
  brakeRate           = 0.08,
  buildCostEnergy     = 700,
  buildCostMetal      = 700,
  builder             = false,
  buildPic            = [[ARMMERL.png]],
  buildTime           = 700,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Lançador de mísseis crusadores móvel]],
    description_fr = [[Lanceur de Missile de Croisi?re Mobile]],
    description_pl = [[Mobilna Wyrzutnia Rakiet Manewruj?cych]],
	description_de = [[Mobile Marschflugkörperabschussrampe]],
    helptext       = [[The Impaler fires vertically a high damage, high accuracy kinetic missile at long range. Its high arc makes it able to fire over any obstacle, however that makes the flight time so high that it's useless against moving targets. Use the Impaler to kill specific buildings.]],
    helptext_bp    = [[Impaler dispara verticalmente um míssel de grande precis?o, dano e alcançe. Seu alto ângulo disparo o faz capaz de atirar sobre qualquer obstáculo, mas como consequ?ncia o tempo de voo é t?o longo que é quase impossível acertar alvos móveis. Use-o para matar construç?es específicas. ]],
    helptext_fr    = [[Le Impaler tire verticallement des missiles de croisi?res qui retombent exactement sur leur cible, causant de puissant dommages sur une tr?s petite zone. Cependant le temps de voyage des missiles le rends inefficace contre les unit?s mobiles. ]],
    helptext_pl    = [[Impaler jest wyrzutni? ci?kich rakiet artyleryjskich du?ego zasi?gu. Po wystrzeleniu rakieta wznosi si? wysoko w powietrze, a nast?pnie opada na wcze?niej wyznaczony punkt. Pozwala to omin?? wi?kszo?? przeszk?d i uderzy? z du?? moc? w konkretny budynek. Niestety Impaler jest absolutnie bezu?yteczny przeciwko mobilnym jednostkom.]],
	helptext_de    = [[Der Impaler feuert seine Ballistgeschoss senkrecht ab. Ihn zeichnen seine hohe Präzision und die lange Reichweite seiner Flugkörper, sowie die Möglichkeit über Hindernisse zu schießen, aus. Die große Flugzeit macht ihn aber nutzlos gegenüber sich bewegenden Einheiten. Nutze den Impaler, um spezielle Einheiten/Gebäude zu zerstören.]],
  },

  explodeAs           = [[BIG_UNITEX_MERL]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[vehiclelrarty]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 278,
  maxDamage           = 1100,
  maxSlope            = 18,
  maxVelocity         = 2.25,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SWIM LAND SHIP GUNSHIP HOVER]],
  objectName          = [[core_diplomat.s3o]],
  script              = [[armmerl.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX_MERL]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:NONE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  trackOffset         = 15,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 40,
  turninplace         = 0,
  turnRate            = 460,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[CORTRUCK_ROCKET]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    CORTRUCK_ROCKET = {
      name                    = [[Kinetic Missile]],
      areaOfEffect            = 24,
      cegTag                  = [[raventrail]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage         = {
        default = 800,
        planes  = 800,
        subs    = 4,
      },
      
      customParams = {
		trail_burnout = 64, -- two seconds of vertical ascension
		trail_burnout_ceg = [[missiletrailredsmall]],
      },
      
	  texture1=[[null.tga]],
	  texture2=[[null.tga]],
	  texture3=[[null.tga]],
	  texture4=[[null.tga]],
	  
      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:DOT_Merl_Explo]],
      fireStarter             = 100,
      flighttime              = 100,
	  impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[wep_merl.s3o]],
      noSelfDamage            = true,
      range                   = 1500,
      reloadtime              = 10,
      selfprop                = true,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startsmoke              = [[1]],
      tolerance               = 4000,
      weaponAcceleration      = 315,
      weaponTimer             = 2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 8000,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Impaler]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1100,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 280,
      object           = [[core_diplomat_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 280,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Impaler]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 280,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 280,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Impaler]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 140,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armmerl = unitDef })
