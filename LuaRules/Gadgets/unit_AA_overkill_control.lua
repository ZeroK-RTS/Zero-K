local versionNumber = "v0.1"

function gadget:GetInfo()
  return {
    name      = "AA overkill control",
    desc      = versionNumber .. " Managed Allowed Weapon Target for Defender, Hacksaw, Chainsaw and Artemis to prevent overkill",
    author    = "Jseah",
    date      = "03/05/13",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false	--  loaded by default?
  }
end

if (not gadgetHandler:IsSyncedCode()) then
  return
end
--SYNCED--

include("LuaRules/Configs/customcmds.h.lua")

local unitAICmdDesc = {
  id      = CMD_UNIT_AI,
  type    = CMDTYPE.ICON_MODE,
  name    = 'Unit AI',
  action  = 'unitai',
  tooltip    = 'Toggles smart unit AI for the unit',
  params     = {1, 'AI Off','AI On'}
}

local GetTarget          = Spring.GetProjectileTarget
local GetUnitDefID       = Spring.GetUnitDefID
local GetHP              = Spring.GetUnitHealth

local FindUnitCmdDesc    = Spring.FindUnitCmdDesc
local EditUnitCmdDesc    = Spring.EditUnitCmdDesc
local GetUnitCmdDesc     = Spring.GetUnitCmdDescs
local InsertUnitCmdDesc  = Spring.InsertUnitCmdDesc

local airtargets         = {} -- {id = unitID, incoming = {shotID}, receivingdamage = int}

local shot               = {} -- {id = shotID, unitID = ownerunitID, target = targetunitID, damage = int)

local AAunittypes        = {["turretmissile"] = 1, ["turretaaclose"] = 1, ["turretaafar"] = 1, ["turretaaheavy"] = 1} -- number = shot damage
local IsAA = {
	[UnitDefNames.turretmissile.id] = true,
	[UnitDefNames.turretaaclose.id] = true,
	[UnitDefNames.turretaafar.id] = true,
	[UnitDefNames.turretaaheavy.id] = true
}

local Isair = {}
for i=1,#UnitDefs do
  if UnitDefs[i].canFly then
	Isair[i] = true
  end
end

local remUnitDefID = {}

local Echo = Spring.Echo

-------------------FUNCTIONS------------------

function IsMicroCMD(unitID)
if unitID ~= nil then
  local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
  local cmdDesc = GetUnitCmdDesc(unitID, cmdDescID, cmdDescID)
  local nparams = cmdDesc[1].params
  if nparams[1] == '1' then
    return true
  end
end
  return false
end

function AddShot(shotID, unitID, target, damage)
  --Echo("Added shot", shotID, unitID, target, damage)
  if target ~= nil then
    shot[shotID] = {id = shotID, owner = unitID, target = target, damage = damage}
	if airtargets[target] ~= nil then
	  airtargets[target].incoming[shotID] = shotID
	  airtargets[target].receivingdamage = airtargets[target].receivingdamage + damage
	end
  end
end

function RemoveShot(shotID)
  --Echo("Removed shot", shotID)
  local target = shot[shotID].target
  if airtargets[target] ~= nil then
    airtargets[target].incoming[shotID] = nil
    airtargets[target].receivingdamage = airtargets[target].receivingdamage - shot[shotID].damage
  end
  shot[shotID] = nil
end

function AddAir(unitID, ud)
  --Echo("Added air unit", unitID)
  airtargets[unitID] = {id = unitID, incoming = {}, receivingdamage = 0}
end

function removeAir(unitID)
  --Echo("Removed air unit", unitID)
  for shotID in pairs(airtargets[unitID].incoming) do
    --Echo("Overkill shot removed", shotID)
    RemoveShot(shotID)
  end
  airtargets[unitID] = nil
end

-------------------CALL INS-------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  remUnitDefID[unitID] = unitDefID
  if IsAA[unitDefID] then
    local ud = UnitDefs[unitDefID]
	InsertUnitCmdDesc(unitID, unitAICmdDesc)
    local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
    EditUnitCmdDesc(unitID, cmdDescID, {params = {0, 'AI Off','AI On'}})
  end
  if Isair[unitDefID] then
    AddAir(unitID, ud)
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  local ud = UnitDefs[unitDefID]
  remUnitDefID[unitID] = unitDefID
  if Isair[unitDefID] then
    removeAir(unitID)
  end
end

function gadget:Initialize()
  Echo("AA overkill control Gadget Enabled")
  for unitname in pairs(AAunittypes) do
	local damage = 0
    for i = 1,#WeaponDefs do
	  local wd = WeaponDefs[i]
	  if wd.name:find(unitname) then
		for j = 1, #wd.damages do
		  if damage < wd.damages[j] then
		    damage = wd.damages[j]
		  end
		end
	  end
	end
	AAunittypes[unitname] = damage
  end
  for _, unitID in pairs(Spring.GetAllUnits()) do
	local unitDefID = Spring.GetUnitDefID(unitID)
	gadget:UnitCreated(unitID, unitDefID)
  end
end

function gadget:ProjectileCreated(projID, unitID)
  local unitDefID = GetUnitDefID(unitID)
  local ud = UnitDefs[unitDefID]
  --Echo(ud.name)
  if IsAA[unitDefID] then
    AddShot(projID, unitID, GetTarget(projID), AAunittypes[ud.name])
  end
end

function gadget:ProjectileDestroyed(projID)
  if shot[projID] ~= nil then
    RemoveShot(projID)
  end
end

function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
  local unitDefID = remUnitDefID[attackerID]
  if IsAA[unitDefID] and IsMicroCMD(attackerID) then
	local ud = UnitDefs[unitDefID]
    --Echo(attackerID, targetID)
    local tunitDefID = Spring.GetUnitDefID(targetID)
    local tud = UnitDefs[tunitDefID]
    if Isair[tunitDefID] then
	  hp = GetHP(targetID)
	  if hp < airtargets[targetID].receivingdamage then
	    --Echo("preventing overkill")
	    return false, 1
	  end
    end
  end
  return true, 1
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return IsAA
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  local ud = UnitDefs[unitDefID]
  if IsAA[unitDefID] then
    if cmdID == CMD_UNIT_AI then
	  local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
	  if cmdParams[1] == 0 then
	    nparams = {0, 'AI Off','AI On'}
	  else
	    nparams = {1, 'AI Off','AI On'}
	  end
	  EditUnitCmdDesc(unitID, cmdDescID, {params = nparams})
	end
  end
  return true
end
