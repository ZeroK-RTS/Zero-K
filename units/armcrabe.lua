unitDef = {
  unitname               = [[armcrabe]],
  name                   = [[Crabe]],
  description            = [[Heavy Riot/Skirmish Spider - Curls into Armored Form When Stationary]],
  acceleration           = 0.22,
  bmcode                 = [[1]],
  brakeRate              = 0.18,
  buildCostEnergy        = 1600,
  buildCostMetal         = 1600,
  builder                = false,
  buildPic               = [[armcrabe.png]],
  buildTime              = 1600,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[60 48 60]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô dispersador pesado.]],
    description_es = [[Unidad pesante de alborote/escaramuzador]],
    description_fi = [[Raskas mellakka/kahakoitsijarobotti]],
    description_fr = [[Marcheur Émeutier Lourd]],
    description_it = [[Unita pesante da rissa/scaramucciatore]],
	description_de = [[Schwere Riot/Skirmish Spinne - Zieht sich bei Stillstand in seine Panzerung zurück]],
	helptext_de    = [[Die große Panzerung kann auch große Gruppen von billigen Einheiten wegstecken, sowie grundlegende Verteidigung. Sobald die Spinne zum Stillstand kommt, zieht sie sich in die gepanzerte Form zurück: ein gewaltiger Verteidigungsturm. Der Nachteil ist die große Bewegungseinschränkung.]],
    helptext       = [[The Crabe's huge shells obliterate large swarms of cheap units, and can also outrange basic defenses. When it stops walking, Crabe curls up into armored form reducing incoming damage to a third. The Crabe's main weakness is its lack of mobility.]],
    helptext_bp    = [[]],
    helptext_es    = [[Las balas enormes del Crabe arrasan pelotones de unidades baratas enemigas, y tienes alcance mayor que muchas defensas básicas. Cuando para de caminar, Crabe se enrosca en su forma acorazada. La debilidad principal del Crabe es su falta de movilidad.]],
    helptext_fi    = [[Craben massiiviset plasma-ammukset vahingoittavat yksik?it? laajalla alueella. Pys?htyess??n Crabe linnoittautuu v?hent?en itseens? kohdistuvaa vahinkoa.]],
    helptext_fr    = [[Les gros obus du Crabe peuvent erradiqués les hordes d'unités enemies légere. Lorsqu'il s'arrete de marcher, le Crabe se replie sur lui meme et devient blindé.]],
    helptext_it    = [[I proiettili enrmi del crabe obliterano sciami di unita economiche, e ha un raggio maggiore di molte difese basiche. Quando smette di camminare, Crabe si raggomitola nella sua forma corazzata. La deboleza principale del crabe é la mancanza di mobilitá.]],
  },

  damageModifier         = 0.33,
  defaultmissiontype     = [[Standby]],
  designation            = [[ARM-CRABE]],
  explodeAs              = [[BIG_UNIT]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3spiderriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maneuverleashlength    = [[640]],
  mass                   = 445,
  maxDamage              = 4000,
  maxSlope               = 36,
  maxVelocity            = 1.35,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  modelCenterOffset      = [[0 -6 0]],
  movementClass          = [[TKBOT4]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING GUNSHIP]],
  objectName             = [[ARMCRABE]],
  pushResistant          = 1,
  script                 = [[armcrabe.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNIT]],

  sfxtypes               = {

    explosiongenerators = {
    --  [[custom:ARMCRABE_FLARE]],
	  [[custom:LARGE_MUZZLE_FLASH_FX]],
      [[custom:ARMCRABE_FLASH]],
      [[custom:ARMCRABE_WhiteLight]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 660,
  smoothAnim             = true,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[crossFoot]],
  trackWidth             = 50,
  turnRate               = 600,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[ARM_CRABE_GAUSS]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    ARM_CRABE_GAUSS = {
      name                    = [[Heavy Plasma Cannon]],
      areaOfEffect            = 200,
      craterBoost             = 0,
      craterMult              = 0.5,

      damage                  = {
        default = 600,
        planes  = 600,
        subs    = 30,
      },

      edgeEffectiveness       = 0.3,
      explosionGenerator      = [[custom:ARMCRABE_EXPLOSION]],
      impulseBoost            = 0,
      impulseFactor           = 0.32,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-20]],
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 4,
      renderType              = 4,
      shakeduration           = [[1]],
      shakemagnitude          = [[2]],
      soundHit                = [[weapon/cannon/cannon_hit3]],
      soundStart              = [[weapon/cannon/heavy_cannon2]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 290,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Crabe]],
      blocking         = true,
      category         = [[arm_corpses]],
      damage           = 4000,
      featureDead      = [[DEAD2]],
      featurereclamate = [[smudge01]],
      footprintX       = 5,
      footprintZ       = 4,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 640,
      object           = [[armcrabe_dead]],
      reclaimable      = true,
      reclaimTime      = 640,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Crabe]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4000,
      featureDead      = [[HEAP]],
      featurereclamate = [[smudge01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 640,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 640,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Crabe]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4000,
      featurereclamate = [[smudge01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 320,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armcrabe = unitDef })
