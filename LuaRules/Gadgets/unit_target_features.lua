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
local spGetUnitWeaponTarget  = Spring.GetUnitWeaponTarget
local spGetCommandQueue      = Spring.GetCommandQueue

local featureFlag = Game.collisionFlags.noFeatures

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config

local UPDATE_FREQUENCY = 10

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local weaponUnits = IterableMap.New()
local weaponCounts = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	weaponCounts[i] = (ud.weapons and #ud.weapons > 0 and #ud.weapons)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Target Handling

local function WantAttackGround(unitID)
	if GG.GetUnitTargetGround(unitID) then
		return true
	end
	
	local cQueue = spGetCommandQueue(unitID, 1)
	if not (cQueue and #cQueue > 0) then
		return false, true
	end
	return (cQueue[1].id == CMD.ATTACK) and (#cQueue[1].params > 2)
end

local function UpdateTargets(unitID, unitData)
	local attackGround, doRemove = WantAttackGround(unitID)
	--Spring.Utilities.UnitEcho(unitID, attackGround and 1 or 0)
	if attackGround == unitData.attackGround then
		return
	end
	unitData.attackGround = attackGround
	
	for i = 1, unitData.weapons do
		unitData.oldFlags = unitData.oldFlags or {}
		unitData.needChange = unitData.needChange or {}
		if not unitData.oldFlags[i] then
			local state = spGetUnitWeaponState(unitID, i, "avoidFlags")
			if state then
				unitData.oldFlags[i] = state
				unitData.needChange[i] = ((state%(featureFlag*2)) < featureFlag)
			end
		end
		
		if unitData.needChange[i] then
			if attackGround then
				spSetUnitWeaponState(unitID, i, "avoidFlags", unitData.oldFlags[i] + featureFlag)
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
	local totalUnits = weaponUnits.GetIndexMax()
	if totalUnits > n%UPDATE_FREQUENCY then
		local thisFrame = math.ceil(totalUnits/UPDATE_FREQUENCY)
		for i = 1, thisFrame do
			local unitID, unitData = weaponUnits.Next()
			if UpdateTargets(unitID, unitData) then
				weaponUnits.Remove(unitID)
			end
		end
	end
end

local function AddUnit(unitID, unitDefID)
	weaponUnits.Add(unitID, {
		weapons = weaponCounts[unitDefID],
		attackGround = false
	})
end

function GG.UnitSetGroundTarget(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID and weaponCounts[unitDefID] then
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
	
	if cmdID == CMD.ATTACK and #cmdParams > 2 and not weaponUnits.Get(unitID) then
		AddUnit(unitID, unitDefID)
	end
	
	if cmdID == CMD.INSERT and cmdParams and cmdParams[2] == CMD.ATTACK and #cmdParams == 5 then
		AddUnit(unitID, unitDefID)
	end
	return true
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if weaponCounts[unitDefID] then
		weaponUnits.Remove(unitID)
	end
end
