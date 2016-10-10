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

local targetTable, captureWeaponDefs, gravityWeaponDefs, proximityWeaponDefs, lowVelWeaponDefs, radarWobblePenalty, transportMult = 
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

-- The number of radar wobble reductions that apply to each ally team.
local remHalfWobble = {}
local targetingUpgrades = {}

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
				-- Unidentified radar dots have no params to base priority on, but are generally bad targets.
				if remHalfWobble[allyTeam] and remHalfWobble[allyTeam] > 0 then
					-- don't add wobble penalty if the team has more than 1 half wobble mod
					if lowVelWeaponDefs[attackerWeaponDefID] then
						local _,_,_,vl = Spring.GetUnitVelocity(targetID)
						if vl > lowVelWeaponDefs[attackerWeaponDefID] then
							-- for fast stuff vs slow projectiles: only when wobble reduction is applied
							return true, 25 + (15 * (vl/lowVelWeaponDefs[attackerWeaponDefID]))
						end
					end
					return true, 25
				else
					return true, 25 + (radarWobblePenalty[attackerWeaponDefID] or 0)
				end
			end
		else
			remVisible[allyTeam][targetID] = 0
		end
	end
	
	--// Unit type visiblity params
	local visiblity = remVisible[allyTeam][targetID]
	local enemyUnitDef = remUnitDefID[targetID]
	
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
		-- Mobile units get a penalty for radar wobble. Identified statics experience no wobble.
		if not remStatic[enemyUnitDef] then
			-- if half wobble bonuses basically eliminate wobble
			if remHalfWobble[allyTeam] and remHalfWobble[allyTeam] > 0 then
				if lowVelWeaponDefs[attackerWeaponDefID] then
					local _,_,_,vl = Spring.GetUnitVelocity(targetID)
					if vl > lowVelWeaponDefs[attackerWeaponDefID] then
						-- for fast stuff vs slow projectiles
						return true, defPrio+(15 * (vl/lowVelWeaponDefs[attackerWeaponDefID]))
					end
				end
				-- for everything else, exclude radar wobble penalty if wobble is reduced to nothing
				return true, defPrio
			else
				if lowVelWeaponDefs[attackerWeaponDefID] then
					if UnitDefs[enemyUnitDef].speed > lowVelWeaponDefs[attackerWeaponDefID] then
						-- for fast stuff vs slow projectiles, assume the unit is moving at max speed since we can't tell without cheating
						return true, defPrio + (radarWobblePenalty[attackerWeaponDefID] or 0) + (15 * (vl/lowVelWeaponDefs[attackerWeaponDefID]))
					end
				end
				return true, defPrio + (radarWobblePenalty[attackerWeaponDefID] or 0)
			end
		else
			-- for radar dots of identified statics
			return true, defPrio
		end
	end

	--// Get priority modifier based on disabling.
	if not remStunnedOrOverkill[targetID] then
		local disarmed = (spGetUnitRulesParam(targetID, "disarmed") == 1)
		local overkill = GG.OverkillPrevention_IsDoomed(targetID)
		local disarmExpected = GG.OverkillPrevention_IsDisarmExpected(targetID)
		remStunnedOrOverkill[targetID] = ((overkill or disarmed or disarmExpected) and 1) or 0
	end

	if remStunnedOrOverkill[targetID] == 1 then
		defPrio = defPrio + 20
	end
	
	-- de-prioritize nanoframes relative to how close they are to being finished.
	local local _,_,nanoframe = spGetUnitIsStunned(unitID)
	if nanoframe then
		local _,_,_,_, buildProgress = Spring.GetUnitHealth(unitID)
		defPrio = defPrio + (5 * (1 - buildProgress))
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
				hpAdd = (hp/maxHP) --0.0 to 1.0
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
				hpAdd = (hp/maxHP) --0.0 to 1.0
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
		local unitSeparation = spGetUnitSeparation(unitID,targetID,true)
		local distAdd = 20 * (unitSeparation/WeaponDefs[attackerWeaponDefID].range)
		return true, hpAdd + defPrio + distAdd
	end
	
	-- lowVel Weapon defs, for weapons with slow projectiles
	if lowVelWeaponDefs[attackerWeaponDefID] then
		local _,_,_,vl = Spring.GetUnitVelocity(targetID)
		if vl > lowVelWeaponDefs[attackerWeaponDefID]
			return defPrio + hpAdd + (15 * (vl/lowVelWeaponDefs[attackerWeaponDefID]))
		end
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
		
		-- update radar wobble status
		-- first zero all half-wobble counts
		for key, value in pairs(remHalfWobble) do
		remHalfWobble[key] = 0
		end
	
		--then sort through extant radar upgrade units and add those which are complete to the ally teams they belong to
		for unitID, _ in pairs(targetingUpgrades) do
			local valid = Spring.ValidUnitID(unitID)
			if not valid then
				targetingUpgrades[unitID] = nil
			else
				local stunned_or_inbuild,_,_ = spGetUnitIsStunned(unitID) -- determine if it's still under construction
				local disarmed = (spGetUnitRulesParam(targetID, "disarmed") == 1)
				local allyTeam = spGetUnitAllyTeam(unitID)
				if not stunned_or_inbuild and not disarmed then
					remHalfWobble[allyTeam] = (remHalfWobble[allyTeam] or 0) + 1
				end
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	remUnitDefID[unitID] = unitDefID
	local allyTeam = spGetUnitAllyTeam(unitID)
	remAllyTeam[unitID] = allyTeam
	remStatic[unitID] = (unitDefID and not Spring.Utilities.getMovetype(UnitDefs[unitDefID]))
	
	if UnitDefs[unitDefID].targfac then
		targetingUpgrades[unitID] = true
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	remUnitDefID[unitID] = nil
	remStatic[unitID] = nil
	remAllyTeam[unitID] = nil
	targetingUpgrades[unitID] = nil
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
