-- $Id: unit_nano_buttons.lua 3171 2008-11-06 09:06:29Z det $
function gadget:GetInfo()
  return {
    name      = "NanoCommands",
    desc      = "Improves nano layout commands.",
    author    = "author: BigHead",
    date      = "September 13, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false -- loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then 

local ON, OFF = 1, 0

local defaultRepair = ON
local defaultReclaim = ON
local defaultAssist = ON
local defaultAttack = ON

local showRepair = true
local showReclaim = true
local showAssist = true
local showAttack = true

local nanos = {}
local nanoDefs = {}

local nanoCount = 0
local nanosChanged = false

local aiTeams = {}

local addCommands = {}

local CMD_AUTOREPAIR = 33250
local CMD_AUTORECLAIM = CMD_AUTOREPAIR + 1
local CMD_AUTOASSIST = CMD_AUTOREPAIR + 2
local CMD_AUTOATTACK = CMD_AUTOREPAIR + 3

local autoRepairCmd = {
  show          = showRepair,
  onTooltip = 'on',
  offToolip = 'off',
  
  action = 'repair',
  cmdDesc = {
    id      = CMD_AUTOREPAIR,
    type    = CMDTYPE.ICON_MODE,
    name    = 'Automatic repair',
    cursor  = 'autorepair',
    action  = 'autorepair',
    tooltip = '',
    params  = { '0', 'Repair OFF', 'Repair ON'}
  }
}

local autoReclaimCmd = {
  show          = showReclaim,
  onTooltip = 'on',
  offToolip = 'off',

  action = 'reclaim',
  cmdDesc = {
    id      = CMD_AUTORECLAIM,
    type    = CMDTYPE.ICON_MODE,
    name    = 'Automatic reclaim',
    cursor  = 'autoreclaim',
    action  = 'autoreclaim',
    tooltip = '',
    params  = { '0', 'Reclaim OFF', 'Reclaim ON'}
  }
}

local autoAssistCmd = {
  show          = showAssist,
  onTooltip = 'on',
  offToolip = 'off',

  action = 'assist',
  cmdDesc = {
    id      = CMD_AUTOASSIST,
    type    = CMDTYPE.ICON_MODE,
    name    = 'Automatic assist',
    cursor  = 'autoassist',
    action  = 'autoassist',
    tooltip = '',
    params  = { '0', 'Assist OFF', 'Assist ON'}
  }
}

local autoAttackCmd = {
  show          = showAttack,
  onTooltip = 'on',
  offToolip = 'off',

  action = 'attack',
  cmdDesc = {
    id      = CMD_AUTOATTACK,
    type    = CMDTYPE.ICON_MODE,
    name    = 'Automatic attack',
    cursor  = 'autoattack',
    action  = 'autoattack',
    tooltip = '',
    params  = { '0', 'Attack OFF', 'Attack ON'}
  }
}

-- speedups
local EMPTYTABLE = {}

local GetTeamUnits = Spring.GetTeamUnits
local GetUnitDefID = Spring.GetUnitDefID
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetUnitPosition = Spring.GetUnitPosition
local GetUnitHealth = Spring.GetUnitHealth
local GetGroundHeight = Spring.GetGroundHeight
local GetCommandQueue = Spring.GetCommandQueue
local Echo = Spring.Echo
local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local InsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local EditUnitCmdDesc = Spring.EditUnitCmdDesc
local AreTeamsAllied = Spring.AreTeamsAllied
local GetUnitTeam = Spring.GetUnitTeam
local GetFeatureResources = Spring.GetFeatureResources
local GetFeaturePosition = Spring.GetFeaturePosition
local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local GetFeatureTeam = Spring.GetFeatureTeam
local RemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc

local insert = table.insert

local CMD_STOP = CMD.STOP
local CMD_RECLAIM = CMD.RECLAIM
local CMD_REPAIR = CMD.REPAIR
local CMD_GUARD = CMD.GUARD

local magicalFeatureConstant = 5000

function addButtons(unitID, nano)
  local insertID = FindUnitCmdDesc(unitID, CMD.STOP) or 1
    
  removeButton(unitID, CMD.ATTACK)
  removeButton(unitID, CMD.MOVE)
  removeButton(unitID, CMD.FIGHT)
  removeButton(unitID, CMD.PATROL)
  --removeButton(unitID, CMD.REPEAT)
  removeButton(unitID, CMD.MOVE_STATE)
  removeButton(unitID, CMD.FIRE_STATE)
  
  updateCommandDesc(unitID, autoAttackCmd, nano.attack, insertID)
  updateCommandDesc(unitID, autoAssistCmd, nano.assist, insertID)
  updateCommandDesc(unitID, autoReclaimCmd, nano.reclaim, insertID)  
  updateCommandDesc(unitID, autoRepairCmd, nano.repair, insertID)  
end

function updateCommandDesc(unitID, command, status, insertID)
  if not command.show then
    return
  end
  
  local cmdDesc = command.cmdDesc
  
  cmdDesc.params[1] = status
  
  if status == 0 then
    cmdDesc.tooltip = command.offTooltip
  else
    cmdDesc.tooltip = command.onTooltip
  end  
  local cmdDescId = FindUnitCmdDesc(unitID, cmdDesc.id)
  if not cmdDescId then
    InsertUnitCmdDesc(unitID, insertID, cmdDesc)
  elseif EditUnitCmdDesc then
    EditUnitCmdDesc(unitID, cmdDescId, cmdDesc)
  end
end

function removeButton(unitID, ID)
  local cmdID = FindUnitCmdDesc(unitID, ID)
  if cmdID then
    RemoveUnitCmdDesc(unitID, cmdID)
  end
end

function gadget:Initialize()  
  local teams = Spring.GetTeamList()
  for _, teamID in ipairs(teams) do
    local _, _, _, _, isAiTeam = Spring.GetTeamInfo(teamID)
    if isAiTeam then
      aiTeams[teamID] = true
    end
    for _, unitID in ipairs(GetTeamUnits(teamID)) do
      local unitDefID = GetUnitDefID(unitID)
      registerUnit(unitID, unitDefID, teamID)    
    end
  end
end

function registerUnit(unitID, unitDefID, unitTeam)
  local ud = UnitDefs[unitDefID]
  if not (ud.builder and not ud.canMove) then
    return
  end
  
  local nanoDef = nanoDefs[unitDefID]
  if not nanoDef then
    local dims = Spring.GetUnitDefDimensions(unitDefID)
    nanoDef = UnitDefs[unitDefID].buildDistance + dims.radius - 5
    nanoDefs[unitDefID] = nanoDef
  end
  local nano = {}

  nano.teamID = unitTeam
  nano.unitDefID = unitDefID
  
  nano.range = nanoDef    
  nano.x, nano.y, nano.z = GetUnitPosition(unitID)
  
  if not aiTeams[unitTeam] then
    nano.repair = defaultRepair
    nano.reclaim = defaultReclaim
    nano.assist = defaultAssist
    nano.attack = defaultAttack
  else
    nano.repair = ON
    nano.reclaim = ON
    nano.assist = ON
    nano.attack = ON
  end
  
  addButtons(unitID, nano)

  local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(unitID)  
  if build == 1 then
    nano.finished = true
    if #GetCommandQueue(unitID, 1) == 0 then
      nano.idle = true
    end
  else
    nano.finished = false
  end
  
  nanoCount = nanoCount + 1
  nanosChanged = true
  nanos[unitID] = nano
end

function deregisterUnit(unitID, unitDefID, unitTeam)
  if nanos[unitID] then
    nanoCount = nanoCount - 1
    nanosChanged = true
    nanos[unitID] = nil
  end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  registerUnit(unitID, unitDefID, unitTeam)
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  registerUnit(unitID, unitDefID, unitTeam)
end

function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  deregisterUnit(unitID, unitDefID, unitTeam)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam) 
  deregisterUnit(unitID, unitDefID, unitTeam)
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  local nano = nanos[unitID]
  if not nano then
    return true
  end
  if cmdOptions.shift and cmdID >= CMD_AUTOREPAIR and cmdID <= CMD_AUTOATTACK then
    updateCommand(unitID, nano, autoRepairCmd, cmdParams[1])
    updateCommand(unitID, nano, autoReclaimCmd, cmdParams[1])
    updateCommand(unitID, nano, autoAssistCmd, cmdParams[1])
    updateCommand(unitID, nano, autoAttackCmd, cmdParams[1])
    return false
    
  elseif cmdID == CMD_AUTOREPAIR then
    updateCommand(unitID, nano, autoRepairCmd, cmdParams[1])
    return false
    
  elseif cmdID == CMD_AUTORECLAIM then
    updateCommand(unitID, nano, autoReclaimCmd, cmdParams[1])
    return false
    
  elseif cmdID == CMD_AUTOASSIST then
    updateCommand(unitID, nano, autoAssistCmd, cmdParams[1])
    return false

  elseif cmdID == CMD_AUTOATTACK then
    updateCommand(unitID, nano, autoAttackCmd, cmdParams[1])
    return false
    
  else
    return true
  end
end

function updateCommand(unitID, nano, cmd, newStatus)
  if not cmd.show then
    return
  end

  local status = nano[cmd.action]
  
  nano[cmd.action] = newStatus
  
  updateCommandDesc(unitID, cmd, newStatus)

  if not nano.finished or newStatus == status then
    return
  end
  local currentAction = getNanoAction(unitID)
  if newStatus == ON then
    if currentAction == "idle" then
      doSomething(unitID, nano)
    end
  else
    if currentAction == cmd.action then
      if not doSomething(unitID, nano) then
        addCommands[unitID] = {cmd = CMD_STOP, params = EMPTYTABLE}
      end
    end
  end
end

function getNanoAction(unitID)
  local commands = GetCommandQueue(unitID, 1)
  if #commands == 0 then
    return "idle"
  end
  local cmd = commands[1]
  local targetID = cmd.params[1]
  
  if cmd.id == CMD_RECLAIM then
    if targetID >= magicalFeatureConstant then
      return "reclaim"
    else
      return "attack"
    end
    
  elseif cmd.id == CMD_REPAIR then
    local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(targetID)
    if build < 1 then
      return "assist"
    else
      return "repair"
    end
  end
  
  return "other"
end

function gadget:UnitIdle(unitID, unitDefID, unitTeam)
  local nano = nanos[unitID]
  if nano then
    doSomething(unitID, nano)
  end  
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam) 
  local nano = nanos[unitID]
  if nano then
    nano.finished = true
    doSomething(unitID, nano)
  end  
end

function doSomething(nanoID, nano)  
  nano.idle = false
  
  -- speedups
  local repair = nano.repair == ON
  local assist = nano.assist == ON
  local attack = nano.attack == ON
  local nano_x = nano.x
  local nano_z = nano.z
  local nano_range = nano.range
  local nano_teamID = nano.teamID
  
  local bestBuildTime = nil
  local bestBuildUnitID = nil
  
  local bestHealth = nil
  local bestHealthUnitID = nil
  
  local bestTargetUnitID = nil
  local bestTargetHealth = nil
  
  if repair or assist then
    local units = CallAsTeam(nano_teamID, function () return GetUnitsInCylinder(nano_x, nano_z, nano_range) end)
    for _, unitID in ipairs(units) do
      if unitID ~= nanoID then
        if AreTeamsAllied(nano_teamID, GetUnitTeam(unitID)) then
          local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(unitID)
          
          if assist and build < 1 then
            local buildTime = (1 - build) * UnitDefs[GetUnitDefID(unitID)].buildTime
            if not bestBuildTime or buildTime < bestBuildTime then
              bestBuildTime = buildTime
              bestBuildUnitID = unitID
            end
          end
          
          if repair and build == 1 and health < maxHealth then
            local percentualHealth = health / maxHealth
            if not bestHealth or percentualHealth < bestHealth then
              bestHealth = percentualHealth
              bestHealthUnitID = unitID
            end
          end       
           
        elseif attack then
          local unitMaxHealth = UnitDefs[GetUnitDefID(unitID)]
          if not bestTarget or unitMaxHealth < bestTargetHealth then
            bestTargetUnitID = unitID
            bestTargetHealth = unitMaxHealth
          end
        end
      end
    end
  end

  local bestFeatureMetal = nil
  local bestFeatureEnergy = nil
  local bestFeatureID = nil
  
  if nano.reclaim == ON then
    local features = GetFeaturesInRectangle(nano_x - nano_range, nano_z - nano_range, nano_x + nano_range, nano_z + nano_range)
    for _, featureID in ipairs(features) do
      local metal, _, energy = GetFeatureResources(featureID)

      if (metal > 0 or energy >0) and (not bestFeatureID or (metal > bestFeatureMetal or (metal == bestFeatureMetal and energy > bestFeatureEnergy))) then
        if not AreTeamsAllied(nano_teamID, GetFeatureTeam(featureID)) then
          local x, y, z = GetFeaturePosition(featureID)
          
          if getDistance(nano_x, nano_z, x, z) < nano_range then
            bestFeatureMetal = metal
            bestFeatureEnergy = energy
            bestFeatureID = featureID
          end
        end
      end
    end
  end
  
  if nano.attack and bestTargetUnitID then
    addCommands[nanoID] = {cmd = CMD_RECLAIM, params = {bestTargetUnitID}}
    
  elseif nano.repair and bestHealthUnitID then
    addCommands[nanoID] = {cmd = CMD_REPAIR, params = {bestHealthUnitID}}
  
  elseif nano.reclaim and bestFeatureID then
    addCommands[nanoID] = {cmd = CMD_RECLAIM, params = {magicalFeatureConstant + bestFeatureID}}
    
  elseif nano.assist and bestBuildUnitID then
    addCommands[nanoID] = {cmd = CMD_REPAIR, params = {bestBuildUnitID}}
  
  else
    nano.idle = true
    return false
  end
  
  return true
end

function getDistance(x1, y1, x2, y2)
  return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

local currentFrame = 0
local frameNanos = {}

function gadget:GameFrame(n)
  currentFrame = n % 32
  if nanosChanged then
    frameNanos = {}
    local frameAdd = 31 / (nanoCount + 1)
    local frame = 0
    local roundedFrame, nanoList = 0
    for unitID, _ in pairs(nanos) do
      frame = frame + frameAdd
      roundedFrame = math.floor(frame)
      nanoList = frameNanos[roundedFrame]
      if not nanoList then
        nanoList = {}
        frameNanos[roundedFrame] = nanoList
      end
      insert(nanoList, unitID)
    end
    nanosChanged = false
      
    if roundedFrame > 31 then
      --Spring.Echo("Wrong nanos allocation!!!")
    end      
  elseif frameNanos[currentFrame] then
    for _, unitID in ipairs(frameNanos[currentFrame]) do
      local nano = nanos[unitID]
      
      if nano.idle then      
        doSomething(unitID, nano)
        
      elseif nano.finished then
        local commands = GetCommandQueue(unitID, 1)
        if #commands > 0 then
          local cmd = commands[1]          
          if cmd.id == CMD_REPAIR or cmd.id == CMD_RECLAIM or cmd.id == CMD_GUARD then
            local targetID = cmd.params[1]
            if targetID < magicalFeatureConstant then
              local x, y, z = GetUnitPosition(targetID)            
              if not x or getDistance(x, z, nano.x, nano.z) > nano.range then
                doSomething(unitID, nano)
              end
            end
          end
        elseif not addCommands[unitID] then
          --Echo("Wrong wrong wrong")
        end
      end
      
    end
  end
  
  for unitID, data in pairs(addCommands) do
    GiveOrderToUnit(unitID, data.cmd, data.params, EMPTYTABLE)
  end
  addCommands = {}
end

end
