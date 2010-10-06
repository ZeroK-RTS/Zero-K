function gadget:GetInfo()
  return {
    name      = "CA Capture",
    desc      = "implements capture weapon",
    author    = "SirMaverick",
    date      = "2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then

local spGetUnitHealth   = Spring.GetUnitHealth
local spSetUnitHealth   = Spring.SetUnitHealth
local spTransferUnit    = Spring.TransferUnit
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitTeam     = Spring.GetUnitTeam
local spAreTeamsAllied  = Spring.AreTeamsAllied
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local CMD_ATTACK = CMD.ATTACK
local CMD_FIGHT = CMD.FIGHT

local captureUnitDefIDs = {}
local captureUnits = {}
local weaponIsCapture = {}

local function hasCaptureWeapon(unitDef)
  local weapons = unitDef.weapons
  for _,weapon in ipairs(weapons) do
    if weaponIsCapture[weapon.weaponDef] then
      return true
    end
  end
  return false
end

function gadget:Initialize()

  for id,weaponDef in pairs(WeaponDefs) do
    if weaponDef.customParams and weaponDef.customParams.capture then
      weaponIsCapture[weaponDef.id] = true
    end
  end

  for id,unitDef in pairs(UnitDefs) do
     if hasCaptureWeapon(unitDef) then
       captureUnitDefIDs[unitDef.id] = true
     end
   end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
  if captureUnitDefIDs[unitDefID] then
    captureUnits[unitID] = true
  end
end

function gadget:UnitDestroyed(unitID, unitDefID)
  if captureUnitDefIDs[unitDefID] then
    captureUnits[unitID] = nil
  end
end

function gadget:GameFrame(n)
  if n % 16 < 0.1 then
    for unit,_ in pairs(captureUnits) do
      local cmds = spGetUnitCommands(unit, 1)
      if cmds and cmds[1] then
        local cmd = cmds[1]
        if cmd.id == CMD_ATTACK or cmd.id == CMD_FIGHT then
          local target = cmd.params[1]
          if #cmd.params < 2 then -- 1 parameter = unitid
            local team = spGetUnitTeam(unit)
            local targetteam = Spring.GetUnitTeam(target)
            if spAreTeamsAllied(team, targetteam) then
              spGiveOrderToUnit(unit, CMD.REMOVE, {cmd.tag}, {} )
            end
          end
        end
      end
    end
  end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if weaponIsCapture[weaponID] then

      local health,maxHealth,_,captureProgress,_ = spGetUnitHealth(unitID)
      local capInc = damage/maxHealth
      local newCaptureProgress = captureProgress + capInc
      if newCaptureProgress > health/maxHealth then
        spSetUnitHealth(unitID, {capture = 0})
        spTransferUnit(unitID, attackerTeam, false)
      else
        spSetUnitHealth(unitID, {capture = newCaptureProgress})
      end
      return 0
  end
  return damage

end

else -- UNSYNCED

end

