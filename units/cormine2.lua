unitDef = {
  unitname              = [[cormine2]],
  name                  = [[Bantam]],
  description           = [[Medium Mine]],
  acceleration          = 0,
  activateWhenBuilt     = false,
  bmcode                = [[0]],
  brakeRate             = 0,
  buildCostEnergy       = 30,
  buildCostMetal        = 30,
  builder               = false,
  buildPic              = [[CORMINE2.png]],
  buildTime             = 30,
  canAttack             = false,
  canGuard              = false,
  canMove               = false,
  canPatrol             = false,
  canstop               = [[0]],
  category              = [[FLOAT]],

  customParams          = {
    dontCount = [[1]],
  },

  defaultmissiontype    = [[Standby_Mine]],
  explodeAs             = [[MINE_MEDIUM]],
  footprintX            = 1,
  footprintZ            = 1,
  iconType              = [[mine]],
  idleAutoHeal          = 10,
  idleTime              = 300,
  kamikaze              = true,
  kamikazeDistance      = 15,
  mass                  = 7.5,
  maxDamage             = 20,
  maxSlope              = 255,
  maxVelocity           = 0,
  minCloakDistance      = 0,
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName            = [[logmine.s3o]],
  onoffable             = false,
  seismicDistance       = 80,
  seismicSignature      = 16,
  selfDestructAs        = [[MINE_MEDIUM]],
  selfDestructCountdown = 0,
  side                  = [[CORE]],
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
      range                   = 50,
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

return lowerkeys({ cormine2 = unitDef })
