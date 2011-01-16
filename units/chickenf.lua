unitDef = {
  unitname            = [[chickenf]],
  name                = [[Talon]],
  description         = [[Flying Spike Spitter]],
  acceleration        = 0.8,
  airHoverFactor      = 0,
  amphibious          = true,
  bmcode              = [[1]],
  brakeRate           = 0.4,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenf.png]],
  buildTime           = 450,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  cruiseAlt           = 150,

  customParams        = {
    description_fr = [[Lanceur de pikes volant]],
    helptext       = [[It's a flying chicken! The Talon is a lethal predator that takes down enemy aircraft with its spikes, but will also happily employ them on ground targets. It can be defeated like any other air unit, however.]],
    helptext_fr    = [[Un poulet volant ! Le talon est un pr?dateur mortel qui peut d?truire un avion adverse avec ses dards ainsi que les employer sur des cibles terrestres. Il reste dependant vuln?rable ? toute d?fense ? capacit? anti a?rienne.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[NOWEAPON]],
  floater             = true,
  footprintX          = 1,
  footprintZ          = 1,
  iconType            = [[chickenf]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[64000]],
  mass                = 231,
  maxDamage           = 1200,
  maxSlope            = 18,
  maxVelocity         = 10,
  minCloakDistance    = 75,
  moverate1           = [[32]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName          = [[chickenf.s3o]],
  power               = 450,
  seismicSignature    = 0,
  selfDestructAs      = [[NOWEAPON]],
  separation          = [[0.2]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 512,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[VTOL]],
  turnRate            = 6000,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM SUB FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Spike]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      cegTag                  = [[small_green_goo]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 160,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[spike.s3o]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 400,
      reloadtime              = 1.5,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[chickens/spike_hit]],
      soundStart              = [[chickens/chickenflyerbig1]],
      startVelocity           = 400,
      subMissile              = 1,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 100,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

}

return lowerkeys({ chickenf = unitDef })
