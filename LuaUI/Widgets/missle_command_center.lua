--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "command center: missiles",
    desc      = "Add missile commands to command center",
    author    = "Amnykon",
    date      = "2021-07-30",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    handler   = true,
    enabled   = false,
  }
end

function widget:Initialize()
  WG.missileTotalCount = 0
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include(LUAUI_DIRNAME.."Widgets/Utilities/engine_blast_radius.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function getMouseTargetPosition()
  local mx, my = Spring.GetMouseState()
  local mouseTargetType, mouseTarget = Spring.TraceScreenRay(mx, my, false, true, false, true)

  if (mouseTargetType == "ground") then
    return mouseTarget[1], mouseTarget[2], mouseTarget[3], true
  elseif (mouseTargetType == "unit") then
    return Spring.GetUnitPosition(mouseTarget)
  elseif (mouseTargetType == "feature") then
    local _, coords = Spring.TraceScreenRay(mx, my, true, true, false, true)
    if coords and coords[3] then
      return coords[1], coords[2], coords[3], true
    else
      return Spring.GetFeaturePosition(mouseTarget)
    end
  else
    return nil
  end
end

local function distance3(x1, y1, z1, x2, y2, z2)
  return (x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)+(z1-z2)*(z1-z2)
end

local function distance(x1,z1,x2,z2)
  return (x1-x2)*(x1-x2)+(z1-z2)*(z1-z2)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function missle_class()
  local self = {}

  self.cmdType = CMDTYPE.ICON_MAP

  function self:getOrderableUnits()
    local teamUnits = Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}
    local units = {}

    for _, unitID in ipairs(teamUnits) do
      if self:canGiveOrder(unitID) then
         units[#units + 1] = unitID
       end
     end

    return units
   end

  function self:getNumberOfQueueLaunches(unit)
    local unitDefID = Spring.GetUnitDefID(unit)
    if not unitDefID then return 0 end

    local unitType = self.launchableTypes[unitDefID]
    if not unitType then return 0 end

    local numStockpiled = unitType.getStockpile(unit)
    if not numStockpiled or numStockpiled == 0 then return 0 end

    local cmdQueue = Spring.GetUnitCommands(unit, 100)
    if not cmdQueue then return 0 end

    local numQueued = 0
    for _, cmd in ipairs(cmdQueue) do
      if cmd and cmd.id == unitType.launchCmd then numQueued = numQueued + 1 end
    end

    return numQueued
  end

  function self:getCount()
    local count = 0
    for _, unit in ipairs(self:getOrderableUnits()) do
      if not Spring.GetUnitIsDead(unit) then
        local unitDefID = Spring.GetUnitDefID(unit)
        if unitDefID then
          local type = self.launchableTypes[unitDefID]
          if type then
            local stockpile = type.getStockpile(unit)
            if stockpile then
              count = count + stockpile - self:getNumberOfQueueLaunches(unit)
            end
          end
        end
      end
    end
    return count
  end

  function self:getMaxBuildProgress()
    local maxProgress = 0
    local allUnits = Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}

    for _, unitID in ipairs(allUnits) do
      if not Spring.GetUnitIsDead(unitID) then
        local unitDefID = Spring.GetUnitDefID(unitID)
        if unitDefID and self.launchableTypes[unitDefID] then
          local _, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
          if buildProgress and buildProgress < 1 then
            maxProgress = math.max(maxProgress, buildProgress)
          end
        end
      end
    end
    return maxProgress
  end

  function self:canGiveOrder(unit)
    local _, _, _, _, build = Spring.GetUnitHealth(unit)
    local type = self.launchableTypes[Spring.GetUnitDefID(unit)]
    if not type then return false end

    local count = type.getStockpile(unit)
        - self:getNumberOfQueueLaunches(unit)

    return build == 1 and count ~= 0
  end

  function self:perferedUnit(unit1, unit2, params)
    local unit2x, _, unit2z = Spring.GetUnitPosition(unit2)
    if not unit2x then return unit1 end

    local type2 = self.launchableTypes[Spring.GetUnitDefID(unit2)]
    if not type2 then return unit1 end

    local unit2Dist = distance(params.x, params.z, unit2x, unit2z)
    local weaponDef2 = WeaponDefs[UnitDefs[Spring.GetUnitDefID(unit2)].weapons[type2.weaponId].weaponDef]
    if not weaponDef2 then return unit1 end

    local range = weaponDef2.range

    if unit2Dist > range * range then return unit1 end

    if not unit1 then return unit2 end

    local type1 = self.launchableTypes[Spring.GetUnitDefID(unit1)]
    if not type1 then return unit2 end

    local weaponDef1 = WeaponDefs[UnitDefs[Spring.GetUnitDefID(unit1)].weapons[type1.weaponId].weaponDef]
    if not weaponDef1 then return unit2 end

    local unit1Silo = Spring.GetUnitRulesParam(unit1, "missile_parentSilo")
    local unit1Selected = params.selectedUnits[unit1] or (unit1Silo and params.selectedUnits[unit1Silo])

    local unit2Silo = Spring.GetUnitRulesParam(unit2, "missile_parentSilo")
    local unit2Selected = params.selectedUnits[unit2] or (unit2Silo and params.selectedUnits[unit2Silo])

    if unit1Selected and not unit2Selected then
      return unit1
    elseif unit2Selected and not unit1Selected then
      return unit2
    end

    local queueDelta = self:getNumberOfQueueLaunches(unit1) - self:getNumberOfQueueLaunches(unit2)

    if queueDelta > 0 then
      return unit2
    elseif queueDelta < 0 then
      return unit1
    end

    local _, reloaded1, _ = Spring.GetUnitWeaponState(unit1, type1.weaponId)
    local _, reloaded2, _ = Spring.GetUnitWeaponState(unit2, type2.weaponId)

    if reloaded1 and not reloaded2 then
      return unit1
    elseif not reloaded1 and reloaded2 then
      return unit2
    end

    local unit1x, _, unit1z = Spring.GetUnitPosition(unit1)
    local unit1Dist = distance(params.x, params.z, unit1x, unit1z)

    local unit2x, _, unit2z = Spring.GetUnitPosition(unit2)
    local unit2Dist = distance(params.x, params.z, unit2x, unit2z)

    if unit1Dist < unit2Dist then
        return unit1
    end

    if unit2Dist < unit1Dist then
        return unit2
    end

    return unit1
  end


  function self:getPerferedUnit(params)
    local units = self:getOrderableUnits()

    params.selectedUnits = {}
    for _, unit in ipairs(Spring.GetSelectedUnits() or {}) do
      params.selectedUnits[unit] = true
    end

    local perferedUnit

    for _, unitID in ipairs(units) do
      if self:canGiveOrder(unitID) then
         perferedUnit = self:perferedUnit(perferedUnit, unitID, params)
      end
    end

    return perferedUnit
  end

  function self:commandsChanged()
    local customCommands = widgetHandler.customCommands

    customCommands[#customCommands+1] = {
      id      = self.cmd,
      type    = self.cmdType,
      hidden  = true,
      cursor  = 'Attack',
    }
  end

  function self:commandNotify(cmdID, cmdParams, cmdOptions)
    if cmdID == self.cmd then
      local x,y,z
      if #cmdParams == 1 then
        x,y,z = Spring.GetUnitPosition(cmdParams[1])
      else
        x,y,z = cmdParams[1], cmdParams[2], cmdParams[3]
      end
      local unit = self:getPerferedUnit{x = x, z = z}
      if not unit then return true end
      local unitType = self.launchableTypes[Spring.GetUnitDefID(unit)]
      if not unitType then return true end

      Spring.GiveOrderToUnit(unit, CMD.INSERT, {0, unitType.launchCmd, CMD.OPT_SHIFT, unpack(cmdParams)}, CMD.OPT_ALT)
      return true
    end
  end

  function self:action(x, y, mouse)
    if self:getCount() == 0 then return else end

    local cmdIndex = Spring.GetCmdDescIndex(self.cmd)
    if not cmdIndex then return end

    local left, right = true, false
    local alt, ctrl, meta, shift = Spring.GetModKeyState()
    Spring.SetActiveCommand(cmdIndex, 1, left, right, alt, ctrl, meta, shift)
  end

  function self:drawWorld()
    local _, activeCmd, _ = Spring.GetActiveCommand()
    if activeCmd ~= self.cmd then return end

    local mx, my, mz = getMouseTargetPosition()
    if not mx or not mz then return end
    local unit = self:getPerferedUnit{x = mx, z = mz}
    if not unit then return end

    local ux, uy, uz = Spring.GetUnitPosition(unit)
    if not ux then return end

    local unitDefID = Spring.GetUnitDefID(unit)
    if not unitDefID then return end

    local unitType = self.launchableTypes[unitDefID]
    if not unitType then return end

    local unitDef = UnitDefs[unitDefID]
    if not unitDef or not unitDef.weapons then return end

    local weapon = unitDef.weapons[unitType.weaponId]
    if not weapon then return end

    local weaponDef = WeaponDefs[weapon.weaponDef]
    if not weaponDef then return end

    local dist = distance(mx, mz, ux, uz)
    local range = weaponDef.range
    if dist > range * range then return end

    drawBlastRadius(mx, my, mz, weaponDef)
    drawLine(ux, uy, uz, mx, my, mz)
  end


  return self
end

local function EOS_controller_class()
  local self = missle_class()
  self.x = 438
  self.y = 38
  self.name = "tacnuke"
  self.cmd = 39610

  self.launchableTypes = {
    [UnitDefNames["tacnuke"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         if Spring.GetUnitIsDead(unit) then return 0 end

         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if not silo or Spring.GetUnitIsDead(silo) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

         if not x1 or not x2 then return 0 end

         if distance3(x1, y1, z1, x2, y2, z2) > 600 then return 0 end

         return 1
       end
    },
    [UnitDefNames["subtacmissile"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         return Spring.GetUnitStockpile(unit)
       end
    }
  }

  return self
end

local function seismic_controller_class()
  local self = missle_class()
  self.x = 482
  self.y = 38
  self.name = "seismic"
  self.cmd = 39611

  self.launchableTypes = {
    [UnitDefNames["seismic"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         if Spring.GetUnitIsDead(unit) then return 0 end

         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if not silo or Spring.GetUnitIsDead(silo) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

         if not x1 or not x2 then return 0 end

         if distance3(x1, y1, z1, x2, y2, z2) > 600 then return 0 end

         return 1
       end
    },
  }

  return self
end

local function shockley_controller_class()
  local self = missle_class()
  self.x = 526
  self.y = 38
  self.name = "empmissile"
  self.cmd = 39612

  self.launchableTypes = {
    [UnitDefNames["empmissile"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         if Spring.GetUnitIsDead(unit) then return 0 end

         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if not silo or Spring.GetUnitIsDead(silo) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

         if not x1 or not x2 then return 0 end

         if distance3(x1, y1, z1, x2, y2, z2) > 600 then return 0 end

         return 1
       end
    },
  }

  return self
end

local function inferno_controller_class()
  local self = missle_class()
  self.x = 570
  self.y = 38
  self.name = "napalmmissile"
  self.cmd = 39613

  self.launchableTypes = {
    [UnitDefNames["napalmmissile"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         if Spring.GetUnitIsDead(unit) then return 0 end

         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if not silo or Spring.GetUnitIsDead(silo) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

         if not x1 or not x2 then return 0 end

         if distance3(x1, y1, z1, x2, y2, z2) > 600 then return 0 end

         return 1
       end
    },
  }

  return self
end

local function slow_missile_controller_class()
  local self = missle_class()
  self.x = 614
  self.y = 38
  self.name = "missileslow"
  self.cmd = 39616

  self.launchableTypes = {
    [UnitDefNames["missileslow"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         if Spring.GetUnitIsDead(unit) then return 0 end

         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if not silo or Spring.GetUnitIsDead(silo) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

         if not x1 or not x2 then return 0 end

         if distance3(x1, y1, z1, x2, y2, z2) > 600 then return 0 end

         return 1
       end
    },
  }

  return self
end

local function reef_missile_controller_class()
  local self = missle_class()
  self.x = 394
  self.y = 38
  self.name = "shipcarrier"
  self.cmd = 39614
  self.cmdType = CMDTYPE.ICON_UNIT_OR_MAP

  self.launchableTypes = {
    [UnitDefNames["shipcarrier"].id] = {
       launchCmd = CMD.MANUALFIRE,
       weaponId = 2,
       getStockpile = function(unit)
         return Spring.GetUnitStockpile(unit)
       end
    },
  }

  return self
end

local function trinity_missile_controller_class()
  local self = missle_class()
  self.x = 350
  self.y = 38
  self.name = "staticnuke"
  self.cmd = 39615

  self.launchableTypes = {
    [UnitDefNames["staticnuke"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         return Spring.GetUnitStockpile(unit)
       end
    },
  }

  return self
end

local commands = {
  EOS = EOS_controller_class(),
  seismic = seismic_controller_class(),
  shockley = shockley_controller_class(),
  inferno = inferno_controller_class(),
  slowMissile = slow_missile_controller_class(),
  reefMissile = reef_missile_controller_class(),
  trinityMissile = trinity_missile_controller_class(),
}

local UPDATE_FREQUENCY = 0.25
local timer = UPDATE_FREQUENCY + 1
local buttonCache = {}

local missileCommandIDs = {
  [39610] = true,
  [39611] = true,
  [39612] = true,
  [39613] = true,
  [39614] = true,
  [39615] = true,
  [39616] = true,
}

local function findButtonsByCommand()
  local screen = WG.Chili.Screen0
  if not screen then return end

  local function searchChildren(control)
    if not control then return end

    if control.cmdID and missileCommandIDs[control.cmdID] then
      buttonCache[control.cmdID] = control
    end

    if control.children then
      for _, child in ipairs(control.children) do
        searchChildren(child)
      end
    end
  end

  if screen.children then
    for _, child in ipairs(screen.children) do
      searchChildren(child)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandsChanged()
  for _, command in pairs(commands) do
    command:commandsChanged()
  end
end

function widget:Update(dt)
  timer = timer + dt
  if timer < UPDATE_FREQUENCY then
    return
  end
  timer = 0

  findButtonsByCommand()

  local totalMissileCount = 0

  for _, command in pairs(commands) do
    local count = command:getCount()
    local buildProgress = command:getMaxBuildProgress()
    local customCommands = widgetHandler.customCommands

    totalMissileCount = totalMissileCount + count

    for i = 1, #customCommands do
      if customCommands[i].id == command.cmd then
        local displayName = ""
        if count > 0 then
          displayName = "x" .. count
        end
        if buildProgress > 0 then
          local progressPercent = math.floor(buildProgress * 100)
          if displayName ~= "" then
            displayName = displayName .. " (" .. progressPercent .. "%)"
          else
            displayName = progressPercent .. "%"
          end
        end
        customCommands[i].name = displayName

        -- Disable button if no missiles available
        customCommands[i].disabled = (count == 0)

        -- Update visual progress bar on button
        local button = buttonCache[command.cmd]
        if button and button.SetProgressBar then
          button:SetProgressBar(buildProgress)
        end
        break
      end
    end
  end

  -- Export total count for tab badge
  WG.missileTotalCount = totalMissileCount
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
  for _, command in pairs(commands) do
    if command:commandNotify(cmdID, cmdParams, cmdOptions) then return true end
  end
end


function widget:DrawWorld()
  for _, command in pairs(commands) do
    command:drawWorld()
  end
end

