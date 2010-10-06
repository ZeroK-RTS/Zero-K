unitDef = {
  unitname              = [[cormine_impulse]],
  name                  = [[Impulse Mine]],
  description           = [[Impulse Mine]],
  acceleration          = 0,
  activateWhenBuilt     = false,
  bmcode                = [[0]],
  brakeRate             = 0,
  buildCostEnergy       = 10,
  buildCostMetal        = 10,
  builder               = false,
  buildPic              = [[CORMINE1.png]],
  buildTime             = 10,
  canAttack             = false,
  canGuard              = false,
  canMove               = false,
  canPatrol             = false,
  canstop               = [[0]],
  category              = [[FLOAT]],
  cloakCost             = 0.1,

  customParams          = {
    dontCount = [[1]],
  },

  defaultmissiontype    = [[Standby_Mine]],
  explodeAs             = [[MINE_IMPULSE]],
  footprintX            = 1,
  footprintZ            = 1,
  iconType              = [[mine]],
  idleAutoHeal          = 10,
  idleTime              = 300,
  initCloaked           = true,
  kamikaze              = true,
  kamikazeDistance      = 45,
  mass                  = 2.5,
  maxDamage             = 100,
  maxSlope              = 255,
  maxVelocity           = 0,
  minCloakDistance      = 8,
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName            = [[CORMINE1]],
  onoffable             = false,
  seismicSignature      = 16,
  selfDestructAs        = [[MINE_IMPULSE]],
  selfDestructCountdown = 0,
  side                  = [[CORE]],
  sightDistance         = 80,
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
      areaOfEffect            = 48,
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
      range                   = 100,
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

return lowerkeys({ cormine_impulse = unitDef })
