--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name    = "Target Priority",
		desc    = "Controls target priority because the engine seems to be based on random numbers.",
		author  = "Google Frog",
		date    = "September 25 2011", --update: 9 January 2014
		license = "GNU GPL, v2 or later",
		layer   = 0,
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
local spGetGameFrame = Spring.GetGameFrame

local floor = math.floor

local targetTable, disarmWeaponTimeDefs, disarmPenaltyDefs, captureWeaponDefs, gravityWeaponDefs, proximityWeaponDefs, velocityPenaltyDefs, radarWobblePenalty, radarDotPenalty, transportMult, highAlphaWeaponDamages, DISARM_BASE, DISARM_ADD, DISARM_ADD_TIME = include("LuaRules/Configs/target_priority_defs.lua")

local DISARM_DECAY_FRAMES = 1200
local DISARM_TOTAL = DISARM_BASE + DISARM_ADD
local DISARM_TIME_FACTOR = DISARM_DECAY_FRAMES + DISARM_ADD_TIME

-- Low return number = more worthwhile target
-- This seems to override everything, will need to reimplement emp things, badtargetcats etc...
-- Callin occurs every 16 frames

--// Values that reset every slow update
-- Priority added based on health and capture for non-capture weapons
local remNormalPriorityModifier = {}
local remUnitHealth = {} -- used for overkill avoidance
local remUnitHealthPriority = {}
local remSpeed = {}

 -- Priority added based on health and capture for capture weapons
 -- The disinction is because capture weapons need to prioritize partially captured things
local remCapturePriorityModifer = {}

-- UnitDefID of unit carried in a transport. Used to override transporter unitDefID
local remTransportiee = {}

-- Priority to add based on disabled state.
local remStunned = {}
local remBuildProgress = {}
local remStunAttackers = {}

-- Whether the enemy unit is visible.
local remVisible = {}

-- Remebered mass of the target, negative if it is immune to impulse (nanoframes)
local remScaledMass = {}

--// Fairly unchanging values
local remAllyTeam = {}
local remUnitDefID = {}
local remStatic = {}

 -- If there are more than STUN_ATTACKERS_IDLE_REQUIREMENT fire-at-will Racketeers or Cutters
 -- set targeted on a unit then the extra ones will attack other targets.
local STUN_ATTACKERS_IDLE_REQUIREMENT = 3

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility Functions

local function GetUnitSpeed(unitID)
	if not remSpeed[unitID] then
		local _,_,_,vl = Spring.GetUnitVelocity(unitID)
		remSpeed[unitID] = vl
	end
	return remSpeed[unitID]
end

local function GetUnitVisibility(unitID, allyTeam)
	if not (remVisible[allyTeam] and remVisible[allyTeam][unitID]) then
		if not remVisible[allyTeam] then
			remVisible[allyTeam] = {}
		end
		local visibilityBits = spGetUnitLosState(unitID,allyTeam,true)
		if not visibilityBits then
			remVisible[allyTeam][unitID] = 0
		elseif visibilityBits % 2 == 1 then
			remVisible[allyTeam][unitID] = 2 -- In LoS
		elseif floor(visibilityBits / 4) % 4 == 3 then
			remVisible[allyTeam][unitID] = 1 -- Known type
		else
			remVisible[allyTeam][unitID] = 0
		end
	end
	
	return remVisible[allyTeam][unitID]
end

local function GetUnitTransportieeDefID(unitID)
	if not remTransportiee[unitID] then
		local carryList = Spring.GetUnitIsTransporting(unitID)
		local carryID = carryList and carryList[1]
		if carryID and remUnitDefID[carryID] then
			remTransportiee[unitID] = remUnitDefID[carryID]
		else
			remTransportiee[unitID] = -1
		end
	end
	return remTransportiee[unitID]
end

local function GetUnitStunnedOrInBuild(unitID)
	if not remStunned[unitID] then
		local bla, stunned, nanoframe = spGetUnitIsStunned(unitID)
		
		if stunned then
			remStunned[unitID] = 1
		else
			local disarmed = (spGetUnitRulesParam(unitID, "disarmed") == 1)
			local disarmExpected = GG.OverkillPrevention_IsDisarmExpected(unitID)
			
			if disarmed or disarmExpected then
				if disarmExpected then
					remStunned[unitID] = DISARM_TOTAL
				else
					local disarmframe = spGetUnitRulesParam(unitID, "disarmframe") or -1
					if disarmframe == -1 then
						-- Should be impossible to reach this branch.
						remStunned[unitID] = DISARM_TOTAL
					else
						local gameFrame = spGetGameFrame()
						local frames = disarmframe - gameFrame - DISARM_DECAY_FRAMES
						remStunned[unitID] = DISARM_BASE + math.max(0, math.min(DISARM_ADD, frames/DISARM_TIME_FACTOR))
					end
				end
			else
				remStunned[unitID] = 0
			end
		end
		
		if nanoframe or remStunned[unitID] >= 1 then
			local _, maxHealth, paralyzeDamage, _, buildProgress = spGetUnitHealth(unitID)
			remBuildProgress[unitID] = buildProgress
			if remStunned[unitID] >= 1 then
				-- Long paralysis is a much worse target than one that is almost worn off.
				local paraFactor = math.min(7.5, (paralyzeDamage/maxHealth)^4)
				remStunned[unitID] = paraFactor
			end
		else
			remBuildProgress[unitID] = 1
		end
	end
	
	return remStunned[unitID], remBuildProgress[unitID]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Weapon type specific priority modifiers

local function GetCaptureWeaponPriorityModifier(unitID)
	if not remCapturePriorityModifer[unitID] then
		
		local stunned, buildProgress = GetUnitStunnedOrInBuild(unitID)
		
		local priority = stunned*2 + (30 * (1 - buildProgress))
		if buildProgress < 1 then
			priority = priority + 15
		end
		
		local overkill = GG.OverkillPrevention_IsDoomed(unitID)
		if overkill then
			priority = priority + 60
		end
		
		--// Get priority modifier for health and capture progress.
		local armored = Spring.GetUnitArmored(unitID)
		local hp, maxHP, paralyze, capture = spGetUnitHealth(unitID)
		if hp and maxHP then
			priority = priority - (hp/maxHP)*0.1 -- Capture healthy units
		end
		
		if armored then
			priority = priority + 1
		end
		
		if capture > 0 then
			-- Really prioritize partially captured units
			priority = priority - 6*capture
		end
		
		remCapturePriorityModifer[unitID] = priority
	end
	
	return remCapturePriorityModifer[unitID]
end

local function GetNormalWeaponPriorityModifier(unitID, attackerWeaponDefID)
	if not remNormalPriorityModifier[unitID] then
		
		local stunned, buildProgress = GetUnitStunnedOrInBuild(unitID)
		
		local priority = stunned*2 + (15 * (1 - buildProgress))
		if buildProgress < 1 then
			priority = priority + 3
		end
		
		local overkill = GG.OverkillPrevention_IsDoomed(unitID)
		if overkill then
			priority = priority + 60
		end
	
		local armored, armor = Spring.GetUnitArmored(unitID)
		local hp, maxHP, paralyze, capture = spGetUnitHealth(unitID)
		remUnitHealth[unitID] = hp*((armored and armor and 1/armor) or 1)
		if hp and maxHP then
			remUnitHealthPriority[unitID] = hp/maxHP
		end
		
		if armored then
			priority = priority + 2
		end
		
		if capture > 0 then
			-- Deprioritize partially captured units.
			priority = priority + 0.2*capture
		end
		remNormalPriorityModifier[unitID] = priority
	end
	
	local alphaDamage = highAlphaWeaponDamages[attackerWeaponDefID]
	if alphaDamage and remUnitHealth[unitID] and (remUnitHealth[unitID] < alphaDamage) then
		return remNormalPriorityModifier[unitID] - 0.2 + 0.2*(alphaDamage - remUnitHealth[unitID])/alphaDamage
	end
	
	return remNormalPriorityModifier[unitID] + (remUnitHealthPriority[unitID] or 0)
end

local function GetGravityWeaponPriorityModifier(unitID, attackerWeaponDefID)
	if not remScaledMass[unitID] then
		local _,_,inbuild = spGetUnitIsStunned(unitID)
		if inbuild then
			remScaledMass[unitID] = -1
		else
			-- Glaive = 1.46, Zeus = 5.24, Minotaur = 9.48
			remScaledMass[unitID] = 0.02 * UnitDefs[remUnitDefID[unitID]].mass
		end
	end
	if remScaledMass[unitID] > 0 then
		return remScaledMass[unitID] + GetNormalWeaponPriorityModifier(unitID, attackerWeaponDefID) * 0.3
	else
		return false
	end
end

local function GetDisarmWeaponPriorityModifier(unitID, attackerWeaponDefID)
	local stunned, buildProgress = GetUnitStunnedOrInBuild(unitID)
	local priority = (disarmPenaltyDefs[attackerWeaponDefID] or 10) + GetNormalWeaponPriorityModifier(unitID, attackerWeaponDefID)
	local fewAttackers = false
	if buildProgress == 1 and (remStunAttackers[unitID] or 0) < STUN_ATTACKERS_IDLE_REQUIREMENT then
		remStunAttackers[unitID] = (remStunAttackers[unitID] or 0) + 1
		priority = priority - stunned*2 -- Counteract stunned penalty in normal priority
		fewAttackers = true
	end
	if fewAttackers or stunned <= disarmWeaponTimeDefs[attackerWeaponDefID] then
		return priority
	end

	return (disarmPenaltyDefs[attackerWeaponDefID] or 10) + priority
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Priority callin
local DEF_TARGET_TOO_FAR_PRIORITY = 100000 --usually numbers are around several millions, if target is out of range

--function gadget:AllowUnitTargetRange(unitID, defRange)
--	return true, defRange
--end

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	if not defPriority then
		-- This callin is effectively script.BlockShot but for CommandAI.
		-- The engine will discard target priority information.
		return true
	end
	--Spring.Echo("TARGET CHECK")
	if defPriority > DEF_TARGET_TOO_FAR_PRIORITY then
		return true, defPriority --hope engine is not that wrong about the best target outside of the range
	end
	
	if (not targetID) or (not unitID) or (not attackerWeaponDefID) then
		return true, 25
	end
	
	local allyTeam = remAllyTeam[unitID]
	
	if (not allyTeam) then
		return true, 25
	end
	
	if GG.GetUnitTarget(unitID) == targetID then
		if disarmWeaponTimeDefs[attackerWeaponDefID] then
			if (remStunAttackers[targetID] or 0) < STUN_ATTACKERS_IDLE_REQUIREMENT then
				local stunned, buildProgress = GetUnitStunnedOrInBuild(targetID)
				if stunned ~= 0 then
					remStunAttackers[targetID] = (remStunAttackers[targetID] or 0) + 1
				end
				return true, 0 -- Maximum priority
			end
		else
			return true, 0 -- Maximum priority
		end
	end
	
	local lastShotBonus = 0
	if GG.OverkillPrevention_GetLastShot(unitID) == targetID then
		lastShotBonus = -0.3
	end
	
	local enemyUnitDefID = remUnitDefID[targetID]
	
	--// Get Velocity target penalty
	local velocityAdd = 0
	local velocityPenaltyDef = velocityPenaltyDefs[attackerWeaponDefID]
	if velocityPenaltyDef then
		local unitSpeed = GetUnitSpeed(targetID)
		if unitSpeed > velocityPenaltyDef[1] then
			velocityAdd = velocityPenaltyDef[2] + unitSpeed*velocityPenaltyDef[3]
		end
	end
	
	--// Radar dot handling. Radar dots are not handled by subsequent areas because a unit which is
	-- identified but not visible cannot have priority based on health or other status effects.
	local visiblity = GetUnitVisibility(targetID, allyTeam)

	if visiblity ~= 2 then
		local wobbleAdd = (radarDotPenalty[attackerWeaponDefID] or 0)
		-- Mobile units get a penalty for radar wobble. Identified statics experience no wobble.
		if radarWobblePenalty[attackerWeaponDefID] and (visibility == 0 or not remStatic[enemyUnitDefID]) then
			wobbleAdd = radarWobblePenalty[attackerWeaponDefID]
		end
		
		if visiblity == 0 then
			return true, 25 + wobbleAdd + velocityAdd + lastShotBonus
		elseif visiblity == 1 then
			-- If the unit type is accessible then it can be included in the priority calculation.
			return true, (targetTable[enemyUnitDefID][attackerWeaponDefID] or 5) + wobbleAdd + velocityAdd + 1.5 + lastShotBonus
		end
	end
	
	--// Get default priority for weapon type vs unit type. Includes transportation
	local defPrio
	if transportMult[enemyUnitDefID] then
		local transportiee = GetUnitTransportieeDefID(targetID)
		if transportiee then
			defPrio = targetTable[enemyUnitDefID][attackerWeaponDefID] or 5
		else
			defPrio = (targetTable[transportiee][attackerWeaponDefID] or 5)*transportMult[enemyUnitDefID]
		end
	else
		defPrio = targetTable[enemyUnitDefID][attackerWeaponDefID] or 5
	end

	--// Get priority modifier based on broad weapon type and generic unit status
	if captureWeaponDefs[attackerWeaponDefID] then
		defPrio = defPrio + GetCaptureWeaponPriorityModifier(targetID)
	elseif gravityWeaponDefs[attackerWeaponDefID] then
		local gravityPriority = GetGravityWeaponPriorityModifier(targetID, attackerWeaponDefID)
		if not gravityPriority then
			return false
		end
		defPrio = defPrio + gravityPriority
	elseif disarmWeaponTimeDefs[attackerWeaponDefID] then
		defPrio = defPrio + GetDisarmWeaponPriorityModifier(targetID, attackerWeaponDefID)
	else
		defPrio = defPrio + GetNormalWeaponPriorityModifier(targetID, attackerWeaponDefID)
	end
	
	--// Proximity weapon special handling (heatrays).
	-- Prioritize nearby units.
	if proximityWeaponDefs[attackerWeaponDefID] then
		local unitSeparation = spGetUnitSeparation(unitID,targetID,true)
		local distAdd = proximityWeaponDefs[attackerWeaponDefID] * (unitSeparation/WeaponDefs[attackerWeaponDefID].range)
		defPrio = defPrio + distAdd
	end
	
	--Spring.Utilities.UnitEcho(targetID, string.format("%.1f", defPrio))
	return true, defPrio + velocityAdd + lastShotBonus -- bigger value have lower priority
end

function gadget:GameFrame(f)
	if f%16 == 8 then -- f%16 == 0 happens just before AllowWeaponTarget
		remNormalPriorityModifier = {}
		remUnitHealth = {}
		remUnitHealthPriority = {}
		remSpeed = {}
		remCapturePriorityModifer = {}
		remTransportiee = {}
		remVisible = {}
		remScaledMass = {}
		remStunned = {}
		remStunAttackers = {}
		remBuildProgress = {}
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	remUnitDefID[unitID] = unitDefID
	local allyTeam = spGetUnitAllyTeam(unitID)
	remAllyTeam[unitID] = allyTeam
	remStatic[unitID] = (unitDefID and not Spring.Utilities.getMovetype(UnitDefs[unitDefID]))
end

function gadget:UnitDestroyed(unitID, unitDefID)
	remUnitDefID[unitID] = nil
	remStatic[unitID] = nil
	remAllyTeam[unitID] = nil
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	local _,_,_,_,_,newAllyTeam = spGetTeamInfo(teamID, false)
	remAllyTeam[unitID] = newAllyTeam
end

function gadget:Initialize()
	for _, unitID in ipairs(spGetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end

	for weaponID,wd in pairs(WeaponDefs) do
		if wd.customParams and wd.customParams.is_unit_weapon then
			Script.SetWatchAllowTarget(weaponID, true)
		end
	end
end
