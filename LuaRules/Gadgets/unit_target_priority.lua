--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
	name 	= "Target Priority",
	desc	= "Controls target priority because the engine seems to be based on random numbers.",
	author	= "Google Frog",
	date	= "September 25 2011", --update: 9 January 2014
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local reverseCompat = (Game.version:find('91.0') == 1)

local spGetUnitLosState = Spring.GetUnitLosState
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitIsStunned = Spring.GetUnitIsStunned 
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitSeparation = Spring.GetUnitSeparation

local targetTable, captureWeaponDefs = include("LuaRules/Configs/target_priority_defs.lua")

-- Low return number = more worthwhile target
-- This seems to override everything, will need to reimplement emp things, badtargetcats etc...
-- Callin occurs every 16 frames

-- Values reset every slow update
local remHealth = {}
local remStunnedOrOverkill = {}
local remVisible = {}

-- Fairly unchanging values
local remAllyTeam = {}
local remUnitDefID = {}

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)

	--Spring.Echo("TARGET CHECK")
	
	if (not targetID) or (not unitID) or (not attackerWeaponDefID) then
		return true, 5
	end
	
	local allyTeam = remAllyTeam[unitID]
	
	if (not allyTeam) then
		return true, 5
	end
	
	local los
	if remVisible[allyTeam] and remVisible[allyTeam][targetID] then
		los = remVisible[allyTeam][targetID] == 1
	else
		los = spGetUnitLosState(targetID,allyTeam,false)
		if los then
			los = los.los
		end
		if not remVisible[allyTeam] then
			remVisible[allyTeam] = {}
		end
		remVisible[allyTeam][targetID] = (los and 1) or 0
	end
	
	if not los then
		return true, 5
	end
	
	local enemyUnitDef = remUnitDefID[targetID]
	
	if not enemyUnitDef then
		return true, 5
	end
	
	local defPrio = targetTable[enemyUnitDef][attackerWeaponDefID] or 5
	
	if not remStunnedOrOverkill[targetID] then
		local stunnedOrInbuild = spGetUnitIsStunned(targetID) or (spGetUnitRulesParam(targetID, "disarmed") == 1)
		local overkill = GG.OverkillPrevention_IsDoomed(targetID)
		remStunnedOrOverkill[targetID] = ((stunnedOrInbuild or overkill) and 1) or 0
	end

	if remStunnedOrOverkill[targetID] == 1 then
		defPrio = defPrio + 25
	end
	
	local hpAdd
	if remHealth[targetID] then
		hpAdd = remHealth[targetID]
	else
		local armor = select(2,Spring.GetUnitArmored(unitID)) or 1		
		local hp, maxHP, paralyze, capture, build = spGetUnitHealth(targetID)
		hp = hp/armor
		maxHP = maxHP/armor
		
		if hp and maxHP then
			hpAdd = (hp/maxHP)*0.1 --0.0 to 0.1
		else
			hpAdd = 0
		end
		
		if capture > 0 then
			if captureWeaponDefs[attackerWeaponDefID] then
				-- Really prioritize capturing partially captured units.
				hpAdd = hpAdd - 5*capture
			else
				-- Deprioritize partially captured units.
				hpAdd = hpAdd + 0.2*capture
			end
		end
		
		remHealth[targetID] = hpAdd
	end
	
	--Note: included toned down engine priority (maybe have desired behaviour?).
	local miscAdd = 0
	miscAdd = defPriority*0.00000005 --toned down to be around 0.0 to 0.1 (no guarantee)
	
	local distAdd = 0 --reimplementing proximityPriority weapon tag
	if WeaponDefs[attackerWeaponDefID].proximityPriority then
		local unitSaperation = spGetUnitSeparation(unitID,targetID,true)
		distAdd = (unitSaperation/WeaponDefs[attackerWeaponDefID].range)*0.1*WeaponDefs[attackerWeaponDefID].proximityPriority --0.0 to 0.1 multiplied by proximityPriority
	end
	
	local newPriority = hpAdd + defPrio + miscAdd + distAdd
	
	return true, newPriority --bigger value have lower priority
end

function gadget:GameFrame(f)
	if f%16 == 8 then -- f%16 == 0 happens just before AllowWeaponTarget
		remHealth = {}
		remVisible = {}
		remStunnedOrOverkill = {}
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	remUnitDefID[unitID] = unitDefID
	remAllyTeam[unitID] = spGetUnitAllyTeam(unitID)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	remUnitDefID[unitID] = nil
	remAllyTeam[unitID] = nil
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	local _,_,_,_,_,newAllyTeam = spGetTeamInfo(teamID)
	remAllyTeam[unitID] = newAllyTeam
end

function gadget:Initialize()
	for _, unitID in ipairs(spGetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
	-- Hopefully not all weapon callins will need to be watched
	-- http://springrts.com/mantis/view.php?id=4479
	if not reverseCompat then
		for weaponID,_ in pairs(WeaponDefs) do
			Script.SetWatchWeapon(weaponID, true)
		end
	end
end
