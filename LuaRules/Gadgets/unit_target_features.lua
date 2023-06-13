--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name    = "Target Features",
		desc    = "Sets units to not avoid features when targeting the ground. This allows them to kill features.",
		author  = "GoogleFrog",
		date    = "3 March 2018",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local spGetUnitWeaponState   = Spring.GetUnitWeaponState
local spSetUnitWeaponState   = Spring.SetUnitWeaponState

local featureFlag = Game.collisionFlags.noFeatures
local groundFlag = Game.collisionFlags.noGround

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config

local UPDATE_FREQUENCY = 10

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local weaponUnits = IterableMap.New()
local weaponCounts = {}
local ignoreGroundWeapons = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local weapons = ud.weapons
	if weapons and #weapons > 0 then
		weaponCounts[i] = #weapons
		local ignoreGround
		for j = 1, #weapons do
			local weaponDefID = weapons[j].weaponDef
			local weaponParam = WeaponDefs[weaponDefID].customParams or {}
			if weaponParam.force_ignore_ground then
				ignoreGround = ignoreGround or {}
				ignoreGround[j] = true
			end
		end
		ignoreGroundWeapons[i] = ignoreGround
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Target Handling

local function WantAttackGround(unitID)
	if GG.GetUnitTargetGround(unitID) then
		return true
	end
	
	local cmdID, _, _, _, _, cp_3 = Spring.GetUnitCurrentCommand(unitID)
	if not cmdID then
		return false, true
	end
	return (cmdID == CMD.ATTACK) and cp_3
end

local function UpdateTargets(unitID, unitData)
	local attackGround, doRemove = WantAttackGround(unitID)
	--Spring.Utilities.UnitEcho(unitID, attackGround and 1 or 0)
	if attackGround == unitData.attackGround then
		return
	end
	unitData.attackGround = attackGround
	
	local weapons = unitData.weaponData
	for i = 1, weapons.count do
		unitData.oldFlags = unitData.oldFlags or {}
		unitData.needFeature = unitData.needFeature or {}
		if not unitData.oldFlags[i] then
			local state = spGetUnitWeaponState(unitID, i, "avoidFlags")
			if state then
				unitData.oldFlags[i] = state
				unitData.needFeature[i] = ((state%(featureFlag*2)) < featureFlag)
				if weapons.ignoreGround and weapons.ignoreGround[i] then
					unitData.needGround = unitData.needGround or {}
					unitData.needGround[i] = ((state%(groundFlag*2)) < groundFlag)
				end
			end
		end
		
		local feature = unitData.needFeature[i]
		local ground = (unitData.needGround and unitData.needGround[i])
		if feature or ground then
			if attackGround then
				spSetUnitWeaponState(unitID, i, "avoidFlags", unitData.oldFlags[i] + ((feature and featureFlag) or 0)  + ((ground and groundFlag) or 0))
			else
				spSetUnitWeaponState(unitID, i, "avoidFlags", unitData.oldFlags[i])
			end
		end
	end
	
	return doRemove
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function gadget:GameFrame(n)
	local totalUnits = IterableMap.GetIndexMax(weaponUnits)
	if totalUnits > n%UPDATE_FREQUENCY then
		local thisFrame = math.ceil(totalUnits/UPDATE_FREQUENCY)
		for i = 1, thisFrame do
			local unitID, unitData = IterableMap.Next(weaponUnits)
			if UpdateTargets(unitID, unitData) then
				IterableMap.Remove(weaponUnits, unitID)
			end
		end
	end
end

local function AddUnit(unitID, unitDefID)
	IterableMap.Add(weaponUnits, unitID, {
		weaponData = {
			count = weaponCounts[unitDefID],
			ignoreGround = ignoreGroundWeapons[unitDefID],
		},
		attackGround = false
	})
end

function GG.UnitSetGroundTarget(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID and weaponCounts[unitDefID] and not IterableMap.Get(weaponUnits, unitID) then
		AddUnit(unitID, unitDefID)
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD.ATTACK] = true, [CMD.INSERT] = true}
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if not weaponCounts[unitDefID] then
		return true
	end
	
	if cmdID == CMD.ATTACK and #cmdParams > 2 and not IterableMap.Get(weaponUnits, unitID) then
		AddUnit(unitID, unitDefID)
	end
	
	if cmdID == CMD.INSERT and cmdParams and cmdParams[2] == CMD.ATTACK and #cmdParams == 5 then
		AddUnit(unitID, unitDefID)
	end
	return true
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if weaponCounts[unitDefID] then
		IterableMap.Remove(weaponUnits, unitID)
	end
end
