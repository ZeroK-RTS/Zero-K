unitDef = {
  unitname               = [[reef]],
  name                   = [[Reef]],
  description            = [[Aircraft Carrier (Bombardment) & Anti-Nuke]],
  acceleration           = 0.0354,
  activateWhenBuilt      = true,
  brakeRate              = 0.0466,
  buildCostEnergy        = 3500,
  buildCostMetal         = 3500,
  builder                = true,
  buildPic               = [[ARMCARRY.png]],
  buildTime              = 3500,
  canAssist              = false,
  canMove                = true,
  canReclaim             = false,
  canRepair              = false,
  canRestore             = false,
  cantBeTransported      = true,
  category               = [[SHIP]],
  CollisionSphereScale   = 0.6,
  collisionVolumeOffsets = [[10 -10 0]],
  collisionVolumeScales  = [[90 70 240]],
  collisionVolumeTest	 = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Flugzeugträger (Bomber) & Anti-Nuke]],
    description_fr = [[Porte-Avion Bombardier & Anti-Nuke]],
    description_pl = [[Lotniskowiec z tarcza antyrakietowa]],
    helptext       = [[The most versatile ship on the high seas, the carrier serves several functions. It is equpped with cruise missiles for long range bombardment. Its anti-missile system safeguards the fleet from the threat of nuclear missiles, and it also serves as a mobile repair base for friendly aircraft. Perhaps most notably, the carrier provides its own complement of surface attack drones to engage targets.]],
    helptext_de    = [[Das vielseitigste Schiff auf hoher See, der Träger bietet verschiedenste Funktionen. Er ist mit Marschflugkörpern für weitreichendes Bombardement ausgerüstet. Sein antinukleares System schützt die Flotte vor Atomraketen. Außerdem dient es auch als mobile Reperaturbasis für befreundete Flugzeuge. Vielleicht am nenenswertesten: der Träger besitzt sein eigenes Geschwader an Kampfdrohnen.]],
    helptext_fr    = [[C'est le plus polyvalent des Navires possibles, le Reef peut tirer des missiles de croisicre longue portée pour des frappes chirurgicales, tirer des antimissiles pour contrer tout missile nucléaire, servir de station de réparation et de rechargement pour les planeurs alliés ou encore utiliser ses nombreux drones.]],
    helptext_pl    = [[Najbardziej wielozadaniowy sposrod okretow. Posiada rakiety dalekiego zasiegu i tarcze antyrakietowa, a jego pokład sluzy jako stacja naprawy i dozbrajania samolotow. Ponadto jest w stanie automatycznie produkowac wlasne drony bojowe.]],
	midposoffset   = [[0 -10 0]],
    modelradius    = [[30]],
  },

  energyUse              = 1.5,
  explodeAs              = [[ATOMIC_BLASTSML]],
  floater                = true,
  footprintX             = 6,
  footprintZ             = 6,
  iconType               = [[carrier]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 7500,
  maxVelocity            = 2.75,
  minCloakDistance       = 75,
  movementClass          = [[BOAT6]],
  objectName             = [[lmcarrier.dae]],
  script                 = [[reef.lua]],
  radarDistance          = 1200,
  seismicSignature       = 4,
  selfDestructAs         = [[ATOMIC_BLASTSML]],
  showNanoSpray          = false,
  sightDistance          = 1105,
  turninplace            = 0,
  turnRate               = 233,
  waterline              = 10,

  weapons                = {

    {
      def                = [[carriertargeting]],
      badTargetCategory  = [[SINK]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

    {
      def                = [[ARMMSHIP_ROCKET]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

    {
      def = [[CARRIER_AMD_ROCKET]],
    },

  },

  weaponDefs             = {

    ARMMSHIP_ROCKET    = {
      name                    = [[Cruise Missile]],
      areaOfEffect            = 96,
      cegTag                  = [[cruisetrail]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 900,
        subs    = 45,
      },

      explosionGenerator      = [[custom:STARFIRE]],
      fireStarter             = 100,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[wep_m_kickback.s3o]],
      noSelfDamage            = true,
      range                   = 1550,
      reloadtime              = 6,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      tolerance               = 4000,
      turnrate                = 18000,
      weaponAcceleration      = 355,
      weaponTimer             = 2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 10000,
    },

    CARRIER_AMD_ROCKET = {
      name                    = [[Anti-Nuke Missile]],
      areaOfEffect            = 420,
      collideFriendly         = false,
      coverage                = 1200,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1500,
        subs    = 75,
      },

      explosionGenerator      = [[custom:ANTINUKE]],
      fireStarter             = 100,
      flighttime              = 100,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      interceptor             = 1,
      model                   = [[antinukemissile.s3o]],
      noSelfDamage            = true,
      range                   = 3500,
      reloadtime              = 12,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startVelocity           = 400,
      tolerance               = 4000,
      turnrate                = 65535,
      weaponAcceleration      = 400,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1300,
    },

    carriertargeting   = {
      name                    = [[Fake Targeting Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 1600,
      reloadtime              = 1.25,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 1000000000,
      turret                  = true,
      weaponAcceleration      = 20000,
      weaponTimer             = 0.5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 20000,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Reef]],
      blocking         = false,
      damage           = 7500,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      metal            = 1400,
      object           = [[reef_d.3ds]],
      reclaimable      = true,
      reclaimTime      = 1400,
    },

    HEAP  = {
      description      = [[Debris - Reef]],
      blocking         = false,
      damage           = 7500,
      energy           = 0,
      footprintX       = 6,
      footprintZ       = 6,
      metal            = 700,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 700,
    },

  },

}

return lowerkeys({ reef = unitDef })
