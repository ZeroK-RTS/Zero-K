
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
if (gadgetHandler:IsSyncedCode()) then --SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitLosState = Spring.GetUnitLosState
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitIsStunned = Spring.GetUnitIsStunned 
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitSeparation = Spring.GetUnitSeparation

local targetTable = include("LuaRules/Configs/target_priority_defs.lua")

-- Low return number = more worthwhile target
-- This seems to override everything, will need to reimplement emp things, badtargetcats etc...
-- Callin occurs every 16 frames

local remHealth = {}
local remStunned = {}
local remAllyTeam = {}
local remUnitDefID = {}
local remVisible = {}

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
	
	if not remStunned[targetID] then
		local stunnedOrInbuild = spGetUnitIsStunned(targetID) or (spGetUnitRulesParam(unitID, "disarmed") == 1)
		remStunned[targetID] = (stunnedOrInbuild and 1) or 0
	end

	if remStunned[targetID] == 1 then
		defPrio = defPrio + 25
	end
	
	local hpAdd
	if remHealth[targetID] then
		hpAdd = remHealth[targetID]
	else
		local hp, maxHP = spGetUnitHealth(targetID)
		if hp and maxHP then
			hpAdd = (hp/maxHP)*0.1 --0.0 to 0.1
		else
			hpAdd = 0
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
	
	--GG.UnitEcho(targetID, newPriority)
	
	return true, newPriority --bigger value have lower priority
end

function gadget:GameFrame(f)
	if f%16 == 8 then -- f%16 == 0 happens just before AllowWeaponTarget
		remHealth = {}
		remVisible = {}
		remStunned = {}
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
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end -- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
