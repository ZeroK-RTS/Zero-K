unitDef = {
  unitname               = [[armkam]],
  name                   = [[Banshee]],
  description            = [[Raider Gunship]],
  acceleration           = 0.18,
  brakeRate              = 0.2,
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
  canStop                = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  corpse                 = [[DEAD]],
  cruiseAlt              = 100,

  customParams           = {
    airstrafecontrol = [[1]],
    description_bp = [[Aeronave agressora]],
    description_fr = [[ADAV Pilleur]],
	description_de = [[Plünder Kampfhubschrauber]],
	description_pl = [[Lekki statek powietrzny]],
    helptext       = [[The Banshee is a light gunship. Its high speed and decent damage makes it excellent for quickly taking out enemy economy or inaccurate units like assaults. However, it flies close to the ground and has a short range, meaning even other raiders can engage it on an equal footing. Like any raider, the Banshee should avoid riots and static defense.]],
    helptext_bp    = [[Banshee é a aeronave agressora leve de Nova. Tem uma resist?ncia decente mas causa pouco dano. Funciona bem contra poderio anti-aério pouco resistente, sendo capaz de destruílo e ent?o atacar o resto do inimigo com impunidade por algum tempo, mas funciona mal contra poderio anti-aéreo pesado como metralhadoras anti-aéreas. Pode facilmente acertar unidades móveis e constitui defesa excelente contra inimigos que n?o incluem unidades anti-aéreas em seus grupos de ataque.]],
    helptext_fr    = [[Le Banshee est un ADAV l?ger, un blindage l?ger et peu de d?g?ts en font la hantise des d?buts de conflits. Envoy? dans une base non pr?par?e ou contre une arm?e sans d?fense Anti Air, son attaque rapide est bien souvent fatale.]],
	helptext_de    = [[Der Banshee ist ein leichter Kampfhubschrauber. Er besitzt nur wenig Ausdauer und macht wenig DPS. Er ist gut für direkte Attacken auf die Verteidiger (z.B. um Luftabwehr auszuschalten). Er trifft bewegte Einheiten sehr gut und erweist sich auch bei Verteidigung gegen Gegner ohne Luftabwehr als sehr nützlich.]],
	helptext_pl    = [[Banshee ma bardzo duza predkosc i dosc dobre obrazenia, co pozwala na szybkie najazdy w celu zniszczenia budynkow ekonomicznych przeciwnika lub niecelnych jednostek, na przyklad szturmowych. Pulap lotu Banshee jest jednak na tyle niski, ze moze zostac ostrzelana nawet przez jednostki o krotszym zasiegu.]],
	modelradius    = [[18]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  hoverAttack            = true,
  iconType               = [[gunship]],
  idleAutoHeal           = 10,
  idleTime               = 150,
  maxDamage              = 860,
  maxVelocity            = 6.5,
  minCloakDistance       = 75,
  noChaseCategory        = [[TERRAFORM SUB]],
  objectName             = [[banshee.s3o]],
  script                 = [[armkam.lua]],
  seismicSignature       = 0,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:VINDIBACK]],
    },

  },

  sightDistance          = 500,
  --stealth                = true,
  turnRate               = 693,

  weapons                = {

    {
      def                = [[LASER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
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
	  --cylinderTargeting	  = 1,

      damage                  = {
        default = 6.83,
        subs    = 0.315,
      },

      explosionGenerator      = [[custom:flash1red]],
	  --heightMod				  = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 2,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 0.11,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/laser_burn9]],
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
      damage           = 860,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 88,
      object           = [[banshee_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
    },

    HEAP  = {
      description      = [[Debris - Banshee]],
      blocking         = false,
      damage           = 860,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 44,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
    },

  },

}

return lowerkeys({ armkam = unitDef })
