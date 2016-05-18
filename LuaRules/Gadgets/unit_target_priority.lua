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

local targetTable, radarWobblePenalty, captureWeaponDefs, gravityWeaponDefs, proximityWeaponDefs, transportMult = 
	include("LuaRules/Configs/target_priority_defs.lua")

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

-- Remebered mass of the target, negative if it is immune to impulse (nanoframes)
local remScaledMass = {}

--// Fairly unchanging values
local remAllyTeam = {}
local remUnitDefID = {}
local remStatic = {}

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)

	--Spring.Echo("TARGET CHECK")
	
	if (not targetID) or (not unitID) or (not attackerWeaponDefID) then
		return true, 7
	end
	
	local allyTeam = remAllyTeam[unitID]
	
	if (not allyTeam) then
		return true, 7
	end
	
	--// Get whether the unit type is identified. 
	-- If it is unidentified then the target priority should not occur.
	if not (remVisible[allyTeam] and remVisible[allyTeam][targetID]) then
		if not remVisible[allyTeam] then
			remVisible[allyTeam] = {}
		end
		local visibilityTable = spGetUnitLosState(targetID,allyTeam,false)
		if visibilityTable then
			if visibilityTable.los then
				remVisible[allyTeam][targetID] = 2 -- In LoS
			elseif visibilityTable.typed then
				remVisible[allyTeam][targetID] = 1 -- Known type
			else
				remVisible[allyTeam][targetID] = 0
			end
		else
			remVisible[allyTeam][targetID] = 0
		end
	end
	
	--// Unit type visiblity check
	local visiblity = remVisible[allyTeam][targetID]
	if visiblity == 0 then
		-- Cannot see enemy unit type so there is nothing more to base priority on.
		return true, 7 + (radarWobblePenalty[attackerWeaponDefID] or 0)
	end
	
	local enemyUnitDef = remUnitDefID[targetID]
	if not enemyUnitDef then
		return true, 7 + (radarWobblePenalty[attackerWeaponDefID] or 0)
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
	
	--// Check whether the unit is in LoS
	if visiblity ~= 2 then
		-- A unit which is identified but not visible cannot have priority based on health or other status effects.
		-- 0.2 is added to make this target less good looking than a visible healthy unit.
		return true, defPrio + 0.2 + ((remStatic[enemyUnitDef] and radarWobblePenalty[attackerWeaponDefID]) or 0)
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
	
	--// Gravity weapon special handling.
	-- Prioritize low mass units, do not target nanoframes.
	if gravityWeaponDefs[attackerWeaponDefID] then
		if not remScaledMass[targetID] then
			local _,_,inbuild = spGetUnitIsStunned(targetID)
			if inbuild then
				remScaledMass[targetID] = -1
			else
				-- Glaive = 1.46, Zeus = 5.24, Reaper = 9.48
				remScaledMass[targetID] = 0.02 * UnitDefs[remUnitDefID[targetID]].mass
			end
		end
		if remScaledMass[targetID] > 0 then
			return true, remScaledMass[targetID] + defPrio * 0.3
		else
			return false
		end
	end
	
	--// Proximity weapon special handling (heatrays).
	-- Prioritize nearby units.
	if proximityWeaponDefs[attackerWeaponDefID] then
		local unitSaperation = spGetUnitSeparation(unitID,targetID,true)
		local distAdd = (unitSaperation/WeaponDefs[attackerWeaponDefID].range) * 5
		return true, (hpAdd + defPrio)*0.5 + distAdd
	end
	
	--// All weapons without special handling.
	return true, hpAdd + defPrio -- bigger value have lower priority
end

function gadget:GameFrame(f)
	if f%16 == 8 then -- f%16 == 0 happens just before AllowWeaponTarget
		remHealth = {}
		remCaptureHealth = {}
		remTransportiee = {}
		remVisible = {}
		remScaledMass = {}
		remStunnedOrOverkill = {}
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	remUnitDefID[unitID] = unitDefID
	remAllyTeam[unitID] = spGetUnitAllyTeam(unitID)
	remStatic[unitID] = (unitDefID and not Spring.Utilities.getMovetype(UnitDefs[unitDefID]))
end

function gadget:UnitDestroyed(unitID, unitDefID)
	remUnitDefID[unitID] = nil
	remAllyTeam[unitID] = nil
	remStatic[unitID] = nil
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
