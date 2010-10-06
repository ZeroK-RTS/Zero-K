unitDef = {
  unitname              = [[armmine1]],
  name                  = [[Iso]],
  description           = [[Trap Mine]],
  acceleration          = 0,
  activateWhenBuilt     = false,
  bmcode                = [[0]],
  brakeRate             = 0,
  buildCostEnergy       = 200,
  buildCostMetal        = 200,
  builder               = false,
  buildPic              = [[novheavymine.png]],
  buildTime             = 200,
  canAttack             = false,
  canGuard              = false,
  canMove               = false,
  canPatrol             = false,
  canstop               = [[0]],
  category              = [[FLOAT]],
  cloakCost             = 0,

  customParams          = {
    dontCount = [[1]],
  },

  defaultmissiontype    = [[Standby_Mine]],
  explodeAs             = [[MINE_ARM]],
  footprintX            = 1,
  footprintZ            = 1,
  iconType              = [[mine]],
  idleAutoHeal          = 10,
  idleTime              = 300,
  initCloaked           = true,
  kamikaze              = true,
  kamikazeDistance      = 30,
  mass                  = 2.5,
  maxDamage             = 200,
  maxSlope              = 255,
  maxVelocity           = 0,
  minCloakDistance      = 50,
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName            = [[novmine2.s3o]],
  onoffable             = false,
  seismicSignature      = 16,
  selfDestructAs        = [[MINE_ARM]],
  selfDestructCountdown = 0,
  side                  = [[ARM]],
  sightDistance         = 0,
  smoothAnim            = true,
  stealth               = true,
  TEDClass              = [[SPECIAL]],
  turnRate              = 0,
  waterline             = 1,
  workerTime            = 0,
  yardMap               = [[o]],

  weapons               = {

    {
      def                = [[BOGUS_MISSILE]],
      onlyTargetCategory = [[NONE]],
    },

  },


  weaponDefs            = {

    BOGUS_MISSILE = {
      name                    = [[Missiles]],
      areaOfEffect            = 50,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 0,
      },

      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      metalpershot            = 0,
      range                   = 120,
      reloadtime              = 0.5,
      renderType              = 1,
      startVelocity           = 450,
      tolerance               = 9000,
      turnRate                = 33000,
      turret                  = true,
      weaponAcceleration      = 101,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 650,
    },

  },

}

return lowerkeys({ armmine1 = unitDef })
