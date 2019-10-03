local versionNumber = "v0.1"

function gadget:GetInfo()
  return {
    name      = "AA anti-bait",
    desc      = versionNumber .. " Managed Allowed Weapon Target for Hacksaw and Artemis to ignore bait when other AA is present nearby",
    author    = "Jseah",
    date      = "04/26/13",
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

local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitPosition    = Spring.GetUnitPosition

local GetUnitDefID       = Spring.GetUnitDefID

local FindUnitCmdDesc    = Spring.FindUnitCmdDesc
local EditUnitCmdDesc    = Spring.EditUnitCmdDesc
local GetUnitCmdDesc     = Spring.GetUnitCmdDescs
local InsertUnitCmdDesc  = Spring.InsertUnitCmdDesc

local hpthreshold        = 650 -- maxhp below which an air unit is considered bait
local baitexceptions     = {["phoenix"] = {["turretaaclose"] = 1, ["turretaaheavy"] = 1}} -- units which are never considered bait, "name" = 1 means that tower will consider the target to be part of this category
local alwaysbait         = {["planeheavyfighter"] = {["turretaaclose"] = 1, ["turretaaheavy"] = 1}} -- units which are always considered bait

local AAunittypes        = {["turretaaclose"] = 100, ["turretaaheavy"] = 300} -- what is valid for anti-bait behaviour
-- number is the threshold of "points" above which a turret is considered escorted if it has at least that amount within half range
local AAescort           = {  -- points of how much each AA unit is worth
["turretmissile"] = 100,
["turretaafar"] = 350,
["turretaalaser"] = 250,
["turretaaflak"] = 350,

["planeheavyfighter"] = 100,
["planefighter"] = 80,
["gunshipskirm"] = 100,

["cloakaa"] = 60,
["shieldaa"] = 80,
["vehaa"] = 60,
["jumpaa"] = 250,
["corarch"] = 250,
["tankaa"] = 250}

local AA                 = {} -- {id = unitID, escorted = boolean, range = maxrange, threshold = integer from unittypes}
local AAcount            = 1
local AAref              = {} -- {[unitID] = index in AA table}
local updatespeed        = 30 -- frames over which the escort states will be updated
local updatecount        = 1

local remUnitDefID = {}

local Echo = Spring.Echo

local IsAA = {
	[UnitDefNames.turretaaclose.id] = true,
	[UnitDefNames.turretaaheavy.id] = true,
}

-------------------FUNCTIONS------------------

function Isair(ud)
  return ud.canFly or false
end

function IsBait(AAname, unitDef)
  if not Isair(unitDef) then
    return false
  end
  if unitDef.health < 650 then
    if baitexceptions[unitDef.name] == nil then
	  return true
	end
	--Echo(baitexceptions[unitDef.name][AAname])
	if baitexceptions[unitDef.name][AAname] == nil then
	  return true
	end
  end
  if alwaysbait[unitDef.name] ~= nil then
	--Echo(alwaysbait[unitDef.name][AAname])
    if alwaysbait[unitDef.name][AAname] ~= nil then
	  return true
	end
  end
  return false
end

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

function AddAA(unitID, ud)
  AA[AAcount] = {id = unitID, escorted = false, range = ud.maxWeaponRange, threshold = AAunittypes[ud.name]}
  AAref[unitID] = AAcount
  AAcount = AAcount + 1
end

function removeAA(unitID)
  local index = AAref[unitID]
  AA[index] = AA[AAcount - 1]
  AAref[AA[index].id] = index
  AA[AAcount] = nil
  AAcount = AAcount - 1
  AAref[unitID] = nil
end

function updateAA(AAunitID, index)
  local range = AA[index].range
  local x, y, z = GetUnitPosition(AAunitID)
  local units = GetUnitsInCylinder(x, z, range / 2)
  local threshold = AA[index].threshold
  AA[index].escorted = false
  for _, unitID in pairs(units) do
    local unitDefID = GetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
    if AAescort[ud.name] ~= nil then
	  threshold = threshold - AAescort[ud.name] --ud.metalCost
	  if threshold <= 0 then
	    AA[index].escorted = true
	    return nil
	  end
	end
  end
end

-------------------CALL INS-------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  local ud = UnitDefs[unitDefID]
  remUnitDefID[unitID] = unitDefID
  if IsAA(ud.name) then
    InsertUnitCmdDesc(unitID, unitAICmdDesc)
    local cmdDescID = FindUnitCmdDesc(unitID, CMD_UNIT_AI)
    EditUnitCmdDesc(unitID, cmdDescID, {params = {0, 'AI Off','AI On'}})
	AddAA(unitID, ud)
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  local ud = UnitDefs[unitDefID]
  remUnitDefID[unitID] = nil
  if IsAA(ud.name) then
    removeAA(unitID)
  end
end

function gadget:Initialize()
  Echo("AA anti-bait Gadget Enabled")
  for _, unitID in pairs(Spring.GetAllUnits()) do
	local unitDefID = Spring.GetUnitDefID(unitID)
	gadget:UnitCreated(unitID, unitDefID)
  end
end

function gadget:GameFrame()
  ----Echo("update")
  for i = 1, AAcount - 1 do
    if math.fmod(i, updatespeed) == updatecount then
	  updateAA(AA[i].id, i)
	end
  end
  updatecount = updatecount + 1
  if updatecount > updatespeed then
    updatecount = 1
  end
end

function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
  local unitDefID = remUnitDefID[attackerID]
  if IsAA[unitDefID] and IsMicroCMD(attackerID) and AA[AAref[attackerID]].escorted then
	local ud = UnitDefs[unitDefID]
	--Echo(AA[AAref[attackerID]].escorted)
    local tunitDefID = Spring.GetUnitDefID(targetID)
    local tud = UnitDefs[tunitDefID]
    if IsBait(ud.name, tud) then
	  --Echo("bait")
	  return false, 1
    end
  end
  return true, 1
end

function gadget:AllowCommand_GetWantedCommand()	return
	{[CMD_UNIT_AI] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  local ud = UnitDefs[unitDefID]
  if IsAA(ud.name) then
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
