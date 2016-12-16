unitDef = {
  unitname            = [[chickenc]],
  name                = [[Basilisk]],
  description         = [[All-Terrain Riot]],
  acceleration        = 0.36,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenc.png]],
  buildTime           = 520,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],

  customParams        = {
    description_fr = [[Anti ?meute tout terrain]],
	description_de = [[Gel�ndeg�ngige Rioteinheit]],
    helptext       = [[The Basilisk climbs walls like a spider to surprise the enemy with its highly acidic spit. Only a vigilant watch keeps these critters from sauntering over hills to wreck your base from unexpected directions. Gunships are the best solution to Basilisk incursions.]],
    helptext_fr    = [[Le Basilisk grimpe le long des murs comme un l?zard pour surprend l'enemi avec ses attaques hautement corrosives. Seule une surveillance de tout les instants peut emp?cher ces bestioles d'arriver des chemins cru inpassables. Les VTOLs sont la meilleure r?ponse ? offrir aux incursions de Basilisks.]],
	helptext_de    = [[Der Basilisk erklettert W�nde wie eine Spinne und kann somit den Gegner mit seiner hoch �tzenden Spucke �berraschen. Nur ein wachsames Auge h�lt diese Viecher von deiner Basis fern. Kampfhubschrauber sind die beste L�sung gegen die Basiliskeneinf�lle.]],
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[chickenc]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 1800,
  maxSlope            = 72,
  maxVelocity         = 2.2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[ATKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB STUPIDTARGET]],
  objectName          = [[chickenc.s3o]],
  power               = 520,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 512,
  sonarDistance       = 450,
  trackOffset         = 0.5,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = [[ChickenTrackPointy]],
  trackWidth          = 70,
  turninplace         = 0,
  turnRate            = 806,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT GUNSHIP SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Blob]],
      areaOfEffect            = 128,
      burst                   = 4,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 140,
        planes  = 140,
        subs    = 7,
      },

      explosionGenerator      = [[custom:green_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 400,
      reloadtime              = 3,
      rgbColor                = [[0.2 0.6 0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[chickens/acid_hit]],
      soundStart              = [[chickens/acid_fire]],
      sprayAngle              = 1024,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

  },

}

return lowerkeys({ chickenc = unitDef })
