unitDef = {
  unitname               = [[spherepole]],
  name                   = [[Scythe]],
  description            = [[Cloaking Raider Bot]],
  acceleration           = 0.5,
  brakeRate              = 0.3,
  buildCostEnergy        = 250,
  buildCostMetal         = 250,
  buildPic               = [[spherepole.png]],
  buildTime              = 250,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[28 36 28]],
  collisionVolumeType    = [[cylY]],
  cloakCost              = 0.2,
  cloakCostMoving        = 1,
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô agressor]],
	description_de = [[Getarnter Raider Roboter]],
    description_es = [[Robot de invasi?n]],
    description_fi = [[Hy?kk??j?robotti]],
    description_fr = [[Robot Pilleur]],
    description_it = [[Robot d'invasione]],
    description_pl = [[Kosynier]],
    helptext       = [[The Scythe isn't particularly tough in a stand-up fight, but its cloaking device lets it slip past enemy defenses to stab at the enemy's economy. Damaged Scythes can quickly regenerate when out of combat.]],
	helptext_de    = [[Der Scythe ist nicht sehr zäh im Standkampf, aber seine Tarnfähigkeit ermöglicht es ihm hinter die feindliche Verteidigung zu gelangen und so die gegnerische Ökonomie zu beeinträchtigen.]],
	helptext_pl    = [[Scythe to jednostka do walki w zwarciu. Posiada maskowanie, ktore pozwala mu zblizyc sie do wrogich jednostek lub je ominac i zajac sie niszczeniem wrogiej bazy. Uszkodzony Scythe po wyjsciu z walki samoczynnie naprawia sie.]],
	modelradius    = [[14]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[stealth]],
  idleAutoHeal           = 20,
  idleTime               = 300,
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 800,
  maxSlope               = 36,
  maxVelocity            = 3,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[spherepole.s3o]],
  script				 = [[spherepole.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance          = 425,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2200,
  upright                = true,

  weapons                = {

    {
      def                = [[Blade]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    Blade = {
      name                    = [[Blade]],
      areaOfEffect            = 8,
      beamTime                = 0.13,
      beamWeapon              = true,
      canattackground         = true,
      cegTag                  = [[orangelaser]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
        planes  = 200,
        subs    = 15,
      },

      explosionGenerator      = [[custom:BEAMWEAPON_HIT_ORANGE]],
      fireStarter             = 90,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      lodDistance             = 10000,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 1.4,
      renderType              = 0,
      rgbColor                = [[1 0.25 0]],
      soundStart              = [[BladeSwing]],
      targetborder            = 1,
      targetMoveError         = 0.2,
      thickness               = 0,
      tolerance               = 10000,
      turret                  = true,
      waterweapon             = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2000,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Scythe]],
      blocking         = false,
      damage           = 800,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 100,
      object           = [[scythe_d.dae]],
      reclaimable      = true,
      reclaimTime      = 100,
    },

    HEAP  = {
      description      = [[Debris - Scythe]],
      blocking         = false,
      damage           = 800,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 50,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
    },

  },

}

return lowerkeys({ spherepole = unitDef })
