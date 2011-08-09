--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Paralysis",
    desc      = "Handels paralysis system and adds extra_damage to lightning weapons",
    author    = "Google Frog",
    date      = "Apr, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth
local spGetUnitDefID  = Spring.GetUnitDefID

local extraNormalDamageList = {}

for i=1,#WeaponDefs do
	if WeaponDefs[i].customParams and WeaponDefs[i].customParams.extra_damage then 
		extraNormalDamageList[i] = WeaponDefs[i].customParams.extra_damage
	end
end 

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	
	if paralyzer then -- the weapon deals paralysis damage
		
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		if extraNormalDamageList[weaponID] then
			attackerID = attackerID or -1
			-- be careful; this line can cause recursion! don't make it do paralyzer damage
			Spring.AddUnitDamage(unitID, extraNormalDamageList[weaponID], 0, attackerID)
		end
		if health and maxHealth and health ~= 0 then -- taking no chances.
			return damage*maxHealth/health
		end
	end
	
	return damage
end


--[[
Below is code that entirely replaces the inbuilt paralysis system with a new one.
It can stay here as SVN can be a pain and we may want to change EMP behaviour in 
the future. It can also be reused for any other status effect with sharp state 
changes as that is what it is good for. Check 2346 for other changes.


local FRAMES_PER_SECOND = 30

local DECAY_FRAMES = 1200 -- time in frames it takes to decay 100% para to 0 

local partialUnits = {}
local paraUnits = {}
-- structure of the above tables.
-- table[frameID] = {count = x, data = {[1] = unitID, [2] = unitID, ... [x] = unitID}
-- They hold the units in a frame that change state
-- paraUnits are those that unparalyse on frame frameID
-- partialUnits are those that lose all paralysis damage on frame frameID
-- Elements are NOT REMOVED from table[frameID].data, only set to nil as the table does not need to be reused.

local partialUnitID = {}
local paraUnitID = {}
-- table[unitID] = {frameID = x, index = y}
-- stores current frame and index of unitID in their respective tables

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local f = 0 -- frame, set in game frame

local function addUnitID(unitID, byFrame, byUnitID, frame, extraParamFrames)
	byFrame[frame] = byFrame[frame] or {count = 0, data = {}}
	byFrame[frame].count = byFrame[frame].count + 1
	byFrame[frame].data[byFrame[frame].count] = unitID
	byUnitID[unitID] = {frameID = frame, index = byFrame[frame].count}
	
	Spring.SetUnitRulesParam(unitID, "paralysis", frame + extraParamFrames)
end

local function removeUnitID(unitID, byFrame, byUnitID)
	byFrame[byUnitID[unitID].frameID].data[byUnitID[unitID].index] = nil
	byUnitID[unitID] = nil
end

-- move a unit from one frame to another
local function moveUnitID(unitID, byFrame, byUnitID, frame, extraParamFrames)
	byFrame[byUnitID[unitID].frameID].data[byUnitID[unitID].index] = nil
	
	byFrame[frame] = byFrame[frame] or {count = 0, data = {}}
	byFrame[frame].count = byFrame[frame].count + 1
	byFrame[frame].data[ byFrame[frame].count] = unitID
	byUnitID[unitID] = {frameID = frame, index = byFrame[frame].count}
	
	Spring.SetUnitRulesParam(unitID, "paralysis", frame + extraParamFrames)
end

local function addParalysisDamageToUnit(unitID, damage, pTime)
	local health = Spring.GetUnitHealth(unitID)
	local extraTime = math.floor(damage/health*DECAY_FRAMES) -- time that the damage would add
	if partialUnitID[unitID] then -- if the unit is partially paralysed
		local newPara = partialUnitID[unitID].frameID+extraTime
		if newPara - f > DECAY_FRAMES then -- the new para damage exceeds 100%
			removeUnitID(unitID, partialUnits, partialUnitID) -- remove from partial table
			newPara = newPara - DECAY_FRAMES -- take away the para used to get 100%
			if pTime and pTime < newPara - f then -- prevent weapon goind over para timer
				newPara = math.floor(pTime) + f
			end
			addUnitID(unitID, paraUnits, paraUnitID, newPara, DECAY_FRAMES)
			Spring.SetUnitHealth(unitID, { paralyze = 1.0e8 }) -- stun unit
			--return 10000000 does not work, obeys para timer
		else
			moveUnitID(unitID, partialUnits, partialUnitID, newPara, 0)
		end
	elseif paraUnitID[unitID] then -- the unit is fully paralysed, just add more damage
		local newPara = paraUnitID[unitID].frameID
		if (not pTime) or pTime > newPara - f then -- if the para time on the unit is less than this weapons para timer
			newPara = newPara+extraTime
			if pTime and pTime < newPara - f then -- prevent going over para time
				newPara = math.floor(pTime) + f
			end
			moveUnitID(unitID, paraUnits, paraUnitID, newPara, DECAY_FRAMES)
		end
	else -- unit is not paralysed at all
		if extraTime > DECAY_FRAMES then -- if the new paralysis puts it over 100%
			local newPara = extraTime + f
			newPara = newPara - DECAY_FRAMES
			if pTime and pTime < newPara - f then -- prevent going over para time
				newPara = math.floor(pTime) + f
			end
			addUnitID(unitID, paraUnits, paraUnitID, newPara, DECAY_FRAMES)
			Spring.SetUnitHealth(unitID, { paralyze = 1.0e8 }) -- stun unit
			--return 10000000 does not work, obeys para timer
		else
			addUnitID(unitID, partialUnits, partialUnitID, extraTime+f, 0)
		end
	end
end

GG.addParalysisDamageToUnit = addParalysisDamageToUnit -- morph uses this

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	
	if paralyzer then -- the weapon deals paralysis damage
		
		addParalysisDamageToUnit(unitID, damage, WeaponDefs[weaponID].damages.paralyzeDamageTime*FRAMES_PER_SECOND)
		
		if extraNormalDamageList[weaponID] then
			attackerID = attackerID or -1
			Spring.AddUnitDamage(unitID, extraNormalDamageList[weaponID], 0, attackerID)
		end
		return 0
	end
	
	return damage
end

function gadget:GameFrame(n)
	f = n
	
	if paraUnits[n] then
		for i = 1, paraUnits[n].count do
			local unitID = paraUnits[n].data[i]
			if unitID then
				local morph = Spring.GetUnitRulesParam(unitID, "morphing")
				if not morph or morph == 0 then
					Spring.SetUnitHealth(unitID, { paralyze = -1})
					-- the unit script needs to be reminded that it is moving
					Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0) 
					Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0)
				end
				paraUnitID[unitID] = nil
				addUnitID(unitID, partialUnits, partialUnitID, DECAY_FRAMES+n, 0)
			end
		end
		paraUnits[n] = nil
	end

	if partialUnits[n] then
		for i = 1, partialUnits[n].count do
			local unitID = partialUnits[n].data[i]
			if unitID then
				partialUnitID[unitID] = nil
				Spring.SetUnitRulesParam(unitID, "paralysis", -1)
			end
		end
		partialUnits[n] = nil
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if partialUnitID[unitID] then
		removeUnitID(unitID, partialUnits, partialUnitID)
	end
	if paraUnitID[unitID] then
		removeUnitID(unitID, paraUnits, paraUnitID)
	end
end
--]]