unitDef = {
  unitname               = [[spiderassault]],
  name                   = [[Hermit]],
  description            = [[All Terrain Assault Bot]],
  acceleration           = 0.18,
  brakeRate              = 0.22,
  buildCostEnergy        = 160,
  buildCostMetal         = 160,
  buildPic               = [[spiderassault.png]],
  buildTime              = 160,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -3 0]],
  collisionVolumeScales  = [[24 30 24]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Geländegängige Sturmspinne]],
    description_bp = [[Rob?assaltante]],
    description_es = [[Robot de Asalto]],
    description_fr = [[Robot d'assaut arachnide]],
    description_it = [[Robot d'assalto]],
    description_pl = [[Pajak szturmowy]],
    helptext       = [[The Hermit can take an incredible beating, and is useful as a shield for the weaker, more-damaging Recluses.]],
    helptext_bp    = [[Hermit ?um rob?assaultante. Pode resistir muito dano, e ?útil como um escudo para os mais fracos porém mais potentes Recluses.]],
    helptext_es    = [[El Hermit es increiblemente resistente, y es útil como esudo para los Recluse que hacen más da?o]],
    helptext_fr    = [[Le Hermit est extraordinairement résistant pour sa taille. Si son canon ?plasma n'a pas la précision requise pour abattre les cibles rapides il reste néanmoins un bouclier parfait pour des unités moins solides telles que les Recluses.]],
    helptext_it    = [[Il Hermit ?incredibilmente resistente, ed e utile come scudo per i Recluse che fanno pi?danno]],
	helptext_de    = [[Der Hermit kann unglaublich viel Pr?el einstecken und ist als Schutzschild f? schwächere, oder zu schonende Einheiten, hervorragend geeignet.]],
	helptext_pl    = [[Hermit jest niesamowicie wytrzymaly, dzieki czemu jest uzyteczny do przejmowania na siebie obrazen, aby chronic lzejsze pajaki.]],
	modelradius    = [[12]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[spiderassault]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1400,
  maxSlope               = 36,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[hermit.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  script                = [[spiderassault.lua]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance          = 420,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 30,
  turnRate               = 1600,

  weapons                = {

    {
      def                = [[THUD_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    THUD_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 36,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 140,
        planes  = 140,
        subs    = 7,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 2.6,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 280,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Hermit]],
      blocking         = true,
      damage           = 1400,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 64,
      object           = [[hermit_wreck.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
    },

    HEAP  = {
      description      = [[Debris - Hermit]],
      blocking         = false,
      damage           = 1400,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 32,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
    },

  },

}

return lowerkeys({ spiderassault = unitDef })
