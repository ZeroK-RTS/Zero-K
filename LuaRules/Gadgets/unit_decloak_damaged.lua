--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Decloak when damaged",
    desc      = "Decloaks units when they are damged",
    author    = "Google Frog",
    date      = "Nov 25, 2009", -- Major rework 12 Feb 2014
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local CMD_CLOAK = CMD.CLOAK

local unitWantCloakCommandDesc = {
	id      = CMD_WANT_CLOAK,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Cloak State',
	action  = 'wantcloak',
	tooltip	= 'Unit cloaking state',
	params 	= {0, 'Decloaked', 'Cloaked'}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local alliedTrueTable = {allied = true}

local Spring = Spring
local spAreTeamsAllied = Spring.AreTeamsAllied

local spSetUnitCloak = Spring.SetUnitCloak
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitIsDead = Spring.GetUnitIsDead

local recloakUnit = {}

local noFFWeaponDefs = {}
for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.customParams and wd.customParams.nofriendlyfire then
		noFFWeaponDefs[i] = true
	end
end

local DEFAULT_DECLOAK_TIME = 100
local UPDATE_FREQUENCY = 10

local cloakUnitDefID = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.canCloak then
		cloakUnitDefID[i] = true
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function PokeDecloakUnit(unitID, duration)
	if recloakUnit[unitID] then
		recloakUnit[unitID] = duration or DEFAULT_DECLOAK_TIME
	else
		spSetUnitRulesParam(unitID, "cannotcloak", 1, alliedTrueTable)
		spSetUnitCloak(unitID, 0)
		recloakUnit[unitID] = duration or DEFAULT_DECLOAK_TIME
	end

end

GG.PokeDecloakUnit = PokeDecloakUnit

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	if damage > 0 and
		not (attackerTeam and
		weaponID and
		noFFWeaponDefs[weaponID] and
		attackerID ~= unitID and
		spAreTeamsAllied(unitTeam, attackerTeam)) then
		
		PokeDecloakUnit(unitID)
	end
end

function gadget:GameFrame(n)
	if n%UPDATE_FREQUENCY == 2 then
		for unitID, frames in pairs(recloakUnit) do
			if frames <= UPDATE_FREQUENCY then
				local wantCloakState = spGetUnitRulesParam(unitID, "wantcloak")
				local areaCloaked = spGetUnitRulesParam(unitID, "areacloaked")
				spSetUnitRulesParam(unitID, "cannotcloak", 0, alliedTrueTable)
				if wantCloakState == 1 or areaCloaked == 1 then
					spSetUnitCloak(unitID, 1)
				end
				recloakUnit[unitID] = nil
			else
				recloakUnit[unitID] = frames - UPDATE_FREQUENCY
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetWantedCloaked(unitID, state)
	if (not unitID) or spGetUnitIsDead(unitID) then
		return 
	end
	
	local wantCloakState = spGetUnitRulesParam(unitID, "wantcloak")
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_WANT_CLOAK)
	if (cmdDescID) then
		Spring.EditUnitCmdDesc(unitID, cmdDescID, { params = {state, 'Decloaked', 'Cloaked'}})
	end
	
	if state == 1 and wantCloakState ~= 1 then
		local cannotCloak = spGetUnitRulesParam(unitID, "cannotcloak")
		local areaCloaked = spGetUnitRulesParam(unitID, "areacloaked")
		if cannotCloak ~= 1 and areaCloaked ~= 1 then
			spSetUnitCloak(unitID, 1)
		end
		spSetUnitRulesParam(unitID, "wantcloak", 1, alliedTrueTable)
	elseif state == 0 and wantCloakState == 1 then
		local areaCloaked = spGetUnitRulesParam(unitID, "areacloaked")
		if areaCloaked ~= 1 then
			spSetUnitCloak(unitID, 0)
		end
		spSetUnitRulesParam(unitID, "wantcloak", 0, alliedTrueTable)
	end
end

GG.SetWantedCloaked = SetWantedCloaked

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_CLOAK] = true, [CMD_WANT_CLOAK] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_WANT_CLOAK then
		if cloakUnitDefID[unitDefID] then
			SetWantedCloaked(unitID,cmdParams[1])
		end
		return false
	elseif cmdID == CMD_CLOAK then
		return false
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	if ud.canCloak then
		local cloakDescID = Spring.FindUnitCmdDesc(unitID, CMD_CLOAK)
		if cloakDescID then
			Spring.InsertUnitCmdDesc(unitID, unitWantCloakCommandDesc)
			Spring.RemoveUnitCmdDesc(unitID, cloakDescID)
			spSetUnitRulesParam(unitID, "wantcloak", 0, alliedTrueTable)
			if ud.customParams.initcloaked then
				SetWantedCloaked(unitID,1)
			end
		end
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
