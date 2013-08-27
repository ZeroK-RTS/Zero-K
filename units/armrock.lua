unitDef = {
  unitname               = [[armrock]],
  name                   = [[Rocko]],
  description            = [[Skirmisher Bot (Direct-Fire)]],
  acceleration           = 0.32,
  brakeRate              = 0.2,
  buildCostEnergy        = 90,
  buildCostMetal         = 90,
  buildPic               = [[ARMROCK.png]],
  buildTime              = 90,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[26 39 26]],
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô escaramuçador]],
    description_fi = [[Kahakoitsijarobotti]],
    description_fr = [[Robot Tirailleur]],
    description_it = [[Robot Da Scaramuccia]],
    description_es = [[Robot Escaramuzador]],
	description_de = [[Skirmisher Roboter (Direkt-Feuer)]],
    helptext       = [[The Rocko's low damage, low speed unguided rockets are redeemed by their range. They are most effective in a line formation, firing at maximum range and kiting the enemy. Counter them by attacking them with fast units which can close range and dodge their missiles.]],
    helptext_bp    = [[Rocko é o robô escaramuçador básico de Nova. Seu pouco poder de fogo e a baixa velocidade de seus foguetes s?o compensados por seu alcançe. Eles sao mais efetivos posicionados em linha, atirando da distância máxima. Se protega deles atacando-os com unidades rápidas ou construindo uma barreira a frente de suas defesas.]],
    helptext_es    = [[El bajo da?o y la baja velocidad de los cohetes sin gu?a del Rocko son redimidos por su alcance.  Son m?s efectivos en una l?nea, disparando al m?ximo alcance. Se contrastan atac?ndolos con unidades r?pidas o poiniendo tus defensas detr?s de un muro de terraform.]],
    helptext_fi    = [[Rockon hitaat, ohjaamattomat ja suhteellisen heikot raketit hy?tyv?t pitk?st? kantamastaan. Rockot ovat tehokkaimmillaan riviss?, kaukaisia kohteita ampuessaan. Torju nopealiikkeisill? yksik?ill? tai muokkaamalla maastoa puolustuslinjojen edest?.]],
    helptext_fr    = [[La faible puissance de feux et la lenteur des roquettes non guid?s du Rocko son conpens?es par sa port?e de tire. Ils sont le plus ?fficace en formation de ligne, en tirant ? port?e maximale. Contrez le en attaquant avec des unit?s rapide ou bien placer vos d?fenses derriere un mure t?rraform?.]],
    helptext_it    = [[Il basso danno e la bassa velocita dei razzi non guidati del Rocko riscattati dal suo raggio. Sono al meglio in una linea, attaccando dal suo raggio massimo. Si contrastano attaccandoli con unita veloci, o mettendo le tue difese dietro di un muro di terraform.]],
	helptext_de    = [[Rockos geringer Schaden und die geringe Geschwindigkeit der Raketen wird durch seine Reichweite aufgehoben. Sie sind an Fronten sehr effektiv, da sie dort mit maximaler Reichweite agieren können. Kontere sie, indem du schnelle Einheiten schickst oder Verteidigung hinter einer Terraformmauer baust.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 480,
  maxSlope               = 36,
  maxVelocity            = 2.2,
  maxWaterDepth          = 20,
  minCloakDistance       = 75,
  modelCenterOffset      = [[0 6 0]],
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[sphererock.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rockomuzzle]],
    },

  },

  sightDistance          = 523,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2200,
  upright                = true,

  weapons                = {

    {
      def                = [[BOT_ROCKET]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    BOT_ROCKET = {
      name                    = [[Rocket]],
      areaOfEffect            = 48,
      burnblow                = true,
      cegTag                  = [[missiletrailredsmall]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 180,
        planes  = 180,
        subs    = 9,
      },

      fireStarter             = 70,
      flightTime              = 2.1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_ajax.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 460,
      reloadtime              = 3.8,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/sabot_hit]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startVelocity           = 200,
      texture2                = [[darksmoketrail]],
      tracks                  = false,
      turret                  = true,
      weaponAcceleration      = 190,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 200,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Rocko]],
      blocking         = true,
      damage           = 480,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 36,
      object           = [[rocko_d.3ds]],
      reclaimable      = true,
      reclaimTime      = 36,
    },

    HEAP  = {
      description      = [[Debris - Rocko]],
      blocking         = false,
      damage           = 480,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 18,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 18,
    },

  },

}

return lowerkeys({ armrock = unitDef })
