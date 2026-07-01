--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "command center: missle",
    desc      = "Add missle commands to command center",
    author    = "Amnykon",
    date      = "2021-07-30",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    handler   = true,
    enabled   = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include(LUAUI_DIRNAME.."Widgets/lib/floatingCommand.lua")
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

local function assign(table, field, value)
  table[field] = value
  return value
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
    local unitType = self.launchableTypes[Spring.GetUnitDefID(unit)]
    local numStockpiled = unitType.getStockpile(unit)

    local numQueued = 0
    if (numStockpiled or 0) ~= 0 then
      local cmdQueue = Spring.GetUnitCommands(unit, numStockpiled);

      for _, cmd in ipairs(cmdQueue) do
        if cmd.id == unitType.launchCmd then numQueued = numQueued + 1 end
      end

    end
    return numQueued
  end

  function self:getCount()
    local count = 0
    for _, unit in ipairs(self:getOrderableUnits()) do
      if not Spring.GetUnitIsDead(unit) then
        local type = self.launchableTypes[Spring.GetUnitDefID(unit)]
        if type then
          count = count
            + type.getStockpile(unit)
            - self:getNumberOfQueueLaunches(unit)
        end
      end
    end
    return count
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
    local unit2Dist = distance(params.x, params.z, unit2x, unit2z)

    local type2 = self.launchableTypes[Spring.GetUnitDefID(unit2)]
    local weaponDef2 = WeaponDefs[UnitDefs[Spring.GetUnitDefID(unit2)].weapons[type2.weaponId].weaponDef]

    local range = weaponDef2.range

    if unit2Dist > range * range then return unit1 end

    if not unit1 then return unit2 end

    local type1 = self.launchableTypes[Spring.GetUnitDefID(unit1)]
    local weaponDef1 = WeaponDefs[UnitDefs[Spring.GetUnitDefID(unit1)].weapons[type1.weaponId].weaponDef]

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

  function self:initialize()
    floatingCommand{
      name = "launch " .. self.name,
      x = self.x,
      y = self.y,
      action = function()
        self:action()
      end,
      contents = {
         assign(self, "bottomLabel",
            WG.Chili.Label:New {
              x = 0,
              y = 0,
              right = 5,
              bottom = 5,
              align = "right",
              valign = "bottom",
              caption = caption,
              fontSize = 16,
              autosize = false,
              fontShadow = true,
            }
          ),
        WG.Chili.Image:New {
          x = "5%",
          y = "5%",
          right = "5%",
          bottom = "5%",
          file = "#" .. UnitDefNames[self.name].id,
          keepAspect = false,
        },
      },
    }
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

      if self.markerMessage then
        Spring.MarkerAddPoint (x, y, z , self.markerMessage, false)
      end

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
    local dist = distance(mx, mz, ux, uz)

    local weaponDefId = self.launchableTypes[Spring.GetUnitDefID(unit)].weaponId
    local weaponDef = WeaponDefs[UnitDefs[Spring.GetUnitDefID(unit)].weapons[weaponDefId].weaponDef]

    local range = weaponDef.range
    if dist > range * range then return end

    drawBlastRadius(mx, my, mz, weaponDef)
    drawLine(ux, uy, uz, mx, my, mz)
  end

  function self:update()
    self.bottomLabel:SetCaption(self:getCount())
  end

  return self
end

local function EOS_controller_class()
  local self = missle_class()
  self.x = 438
  self.y = 38
  self.name = "tacnuke"
  self.cmd = 39610
  self.markerMessage = "Launching EOS"

  self.launchableTypes = {
    [UnitDefNames["tacnuke"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if Spring.GetUnitIsDead(unit) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

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
         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if Spring.GetUnitIsDead(unit) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

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
  self.markerMessage = "Launching Shockley"

  self.launchableTypes = {
    [UnitDefNames["empmissile"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if Spring.GetUnitIsDead(unit) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

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
  self.markerMessage = "Launching Inferno"

  self.launchableTypes = {
    [UnitDefNames["napalmmissile"].id] = {
       launchCmd = CMD.ATTACK,
       weaponId = 1,
       getStockpile = function(unit)
         local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
         if Spring.GetUnitIsDead(unit) then return 0 end

         local x1, y1, z1 = Spring.GetUnitPosition(silo)
         local x2, y2, z2 = Spring.GetUnitPosition(unit)

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
  self.markerMessage = "Launching reef missile"

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
  self.markerMessage = "Launching trinity missile"

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
  reefMissile = reef_missile_controller_class(),
  trinityMissile = trinity_missile_controller_class(),
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandsChanged()
  for _, command in pairs(commands) do
    command:commandsChanged()
  end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
  for _, command in pairs(commands) do
    if command:commandNotify(cmdID, cmdParams, cmdOptions) then return true end
  end
end

function widget:Initialize()
  for _, command in pairs(commands) do
    command:initialize()
  end
end

function widget:DrawWorld()
  for _, command in pairs(commands) do
    command:drawWorld()
  end
end

local UPDATE_FREQUENCY = 0.25
local timer = UPDATE_FREQUENCY + 1
function widget:Update(dt)
  timer = timer + dt
  if timer < UPDATE_FREQUENCY then
    return
  end
  timer = 0

  for _, command in pairs(commands) do
    command:update()
  end
end
