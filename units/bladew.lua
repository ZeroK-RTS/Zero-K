unitDef = {
  unitname            = [[bladew]],
  name                = [[Gnat]],
  description         = [[Light Paralyzer Drone]],
  acceleration        = 0.264,
  brakeRate           = 0.264,
  buildCostEnergy     = 90,
  buildCostMetal      = 90,
  builder             = false,
  buildPic            = [[BLADEW.png]],
  buildTime           = 90,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[18 18 18]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[ellipsoid]],
  collide             = true,
  corpse              = [[DEAD]],
  cruiseAlt           = 78,

  customParams        = {
    airstrafecontrol = [[1]],
    description_fr = [[Drône Paralysant Léger]],
	description_de = [[Leichte, paralysierende Drohne]],
	description_pl = [[Lekki dron paralizacyjny]],
    helptext       = [[The Gnat can be used to paralyze enemy units. It makes an excellent defensive unit, and when combined with banshees or other units can halt the enemy to give you time to kill him. Offensively it can paralyze even heavily fortified areas, but dies relatively easily to defenders.]],
    helptext_fr    = [[Le Gnat peut etre utilisé pour paralyser les unités légcres. Utilisé en groupe il peut meme s'attaquer r des cibles plus grosses, mais sa fragilité rends cette tactique plus difficile.]],
	helptext_de    = [[Gnats sind kleine Einheiten, die Feinde paralysieren können. Sie erweisen sich als Verteidigungseinheiten als sehr nützlich und unter der Kombination mit Banshees oder anderen Einheiten können die Feinde so lange bewegungsunfähig gemacht werden, bis deine Einheiten diese vernichtet haben. In der Offensive können sie sogar schwerere Einheiten paralysieren, doch sterben sie relativ schnell gegen Verteidiger.]],
	helptext_pl    = [[Gnat paralizuje wrogie jednostki. Jest swietna jednostka obronna; jest w stanie efektywnie zatrzymac nawet ciezkie jednostki, jest jednak bardzo delikatny i latwo go zniszczyc.]],
	modelradius    = [[9]],
  },

  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[smallgunship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 350,
  maxVelocity         = 7.5,
  minCloakDistance    = 75,
  noChaseCategory     = [[TERRAFORM SUB]],
  objectName          = [[marshmellow.s3o]],
  script              = [[bladew.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[TINY_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:VINDIBACK]],
    },

  },

  sightDistance       = 380,
  turnRate            = 1144,
  upright             = true,

  weapons             = {

    {
      def                = [[PARALYZER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    PARALYZER = {
      name                    = [[Light Electro-Stunner]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default        = 600,
      },

      duration                = 0.01,
      explosionGenerator      = [[custom:YELLOW_LIGHTNING_BOMB]],
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 2, -- was 2.5 but can only be int
      range                   = 80,
      reloadtime              = 1.2,
      rgbColor                = [[1 1 0.25]],
      sprayAngle              = 6500,
      soundStart              = [[weapon/small_lightning]],
      soundTrigger            = false,	  
      targetborder            = 1,
      targetMoveError         = 0,
      texture1                = [[lightning]],
      thickness               = 1.2,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 800,
    },

  },
	
  featureDefs                   = {

    DEAD = {
      description      = [[Wreckage - Gnat]],
      blocking         = false,
      damage           = 350,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 36,
      object           = [[gnat_d.dae]],
      reclaimable      = true,
      reclaimTime      = 36,
    },

    HEAP = {
      description      = [[Debris - Gnat]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 350,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 18,
      object           = [[debris1x1b.s3o]],
      reclaimable      = true,
      reclaimTime      = 18,
    },

  },

}

return lowerkeys({ bladew = unitDef })
