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

local spGetUnitLosState = Spring.GetUnitLosState
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitIsStunned = Spring.GetUnitIsStunned 
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitSeparation = Spring.GetUnitSeparation

local targetTable, captureWeaponDefs, transportMult = include("LuaRules/Configs/target_priority_defs.lua")

-- Low return number = more worthwhile target
-- This seems to override everything, will need to reimplement emp things, badtargetcats etc...
-- Callin occurs every 16 frames

--// Values that reset every slow update
-- Priority added based on health and capture for non-capture weapons
local remHealth = {} 

 -- Priority added based on health and capture for capture weapons
 -- The disinction is because capture weapons need to prioritize partially captured things
local remCaptureHealth = {}

-- UnitDefID of unit carried in a transport. Used to override transporter unitDefID
local remTransportiee = {}

-- Priority to add based on disabled state.
local remStunnedOrOverkill = {}

-- Whether the enemy unit is visible.
local remVisible = {}

--// Fairly unchanging values
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
	
	--// Get Base priority of unit. Transporting unit for transports.
	local defPrio
	if transportMult[enemyUnitDef] then
		if not remTransportiee[targetID] then
			local carryList = Spring.GetUnitIsTransporting(targetID)
			local carryID = carryList and carryList[1]
			if carryID and remUnitDefID[carryID] then
				remTransportiee[targetID] = remUnitDefID[carryID]
			else
				remTransportiee[targetID] = -1
			end
		end
		if remTransportiee[targetID] == -1 then
			defPrio = targetTable[enemyUnitDef][attackerWeaponDefID] or 5
		else
			defPrio = (targetTable[remTransportiee[targetID]][attackerWeaponDefID] or 5)*transportMult[enemyUnitDef]
		end
	else
		defPrio = targetTable[enemyUnitDef][attackerWeaponDefID] or 5
	end

	--// Get priority modifier based on disabling.
	if not remStunnedOrOverkill[targetID] then
		local stunnedOrInbuild = spGetUnitIsStunned(targetID) or (spGetUnitRulesParam(targetID, "disarmed") == 1)
		local overkill = GG.OverkillPrevention_IsDoomed(targetID)
		local disarmExpected = GG.OverkillPrevention_IsDisarmExpected(targetID)
		remStunnedOrOverkill[targetID] = ((stunnedOrInbuild or overkill or disarmExpected) and 1) or 0
	end

	if remStunnedOrOverkill[targetID] == 1 then
		defPrio = defPrio + 25
	end
	
	--// Get priority modifier for health and capture progress.
	local hpAdd
	if captureWeaponDefs[attackerWeaponDefID] then
	
		if remCaptureHealth[targetID] then
			hpAdd = remCaptureHealth[targetID]
		else
			local armored = Spring.GetUnitArmored(targetID)	
			local hp, maxHP, paralyze, capture, build = spGetUnitHealth(targetID)
			if hp and maxHP then
				hpAdd = (hp/maxHP)*0.1 --0.0 to 0.1
			else
				hpAdd = 0
			end
			
			if armored then
				hpAdd = hpAdd + 2
			end
			
			if capture > 0 then
				-- Really prioritize partially captured units
				hpAdd = hpAdd - 6*capture
			end
			
			remCaptureHealth[targetID] = hpAdd
		end
	else
		
		if remHealth[targetID] then
			hpAdd = remHealth[targetID]
		else
			local armored = Spring.GetUnitArmored(targetID)	
			local hp, maxHP, paralyze, capture, build = spGetUnitHealth(targetID)
			if hp and maxHP then
				hpAdd = (hp/maxHP)*0.1 --0.0 to 0.1
			else
				hpAdd = 0
			end
			
			if armored then
				hpAdd = hpAdd + 2
			end
			
			if capture > 0 then
				-- Deprioritize partially captured units.
				hpAdd = hpAdd + 0.2*capture
			end
			
			remHealth[targetID] = hpAdd
		end
	end
	
	local distAdd = 0 --reimplementing proximityPriority weapon tag
	if WeaponDefs[attackerWeaponDefID].proximityPriority then
		local unitSaperation = spGetUnitSeparation(unitID,targetID,true)
		distAdd = (unitSaperation/WeaponDefs[attackerWeaponDefID].range)*0.1*WeaponDefs[attackerWeaponDefID].proximityPriority --0.0 to 0.1 multiplied by proximityPriority
	end
	
	local newPriority = hpAdd + defPrio + distAdd
	
	return true, newPriority --bigger value have lower priority
end

function gadget:GameFrame(f)
	if f%16 == 8 then -- f%16 == 0 happens just before AllowWeaponTarget
		remHealth = {}
		remCaptureHealth = {}
		remTransportiee = {}
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
	-- in some future version.
	for weaponID,_ in pairs(WeaponDefs) do
		Script.SetWatchWeapon(weaponID, true)
	end
end
