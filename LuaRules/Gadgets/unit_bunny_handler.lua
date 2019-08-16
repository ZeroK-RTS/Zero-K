
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Bunny Handler",
		desc      = "Handlers the bunny weapon",
		author    = "quantum",
		date      = "Dec 2010",
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- shortcuts
local spAreTeamsAllied             = Spring.AreTeamsAllied
local spGetUnitTeam                = Spring.GetUnitTeam
local spGetUnitDefID               = Spring.GetUnitDefID
local spValidUnitID                = Spring.ValidUnitID
local spGetGroundHeight            = Spring.GetGroundHeight
local spGetUnitPosition            = Spring.GetUnitPosition
local spGetGameFrame               = Spring.GetGameFrame
local spSetUnitNoDraw              = Spring.SetUnitNoDraw
local spSetUnitNoMinimap           = Spring.SetUnitNoMinimap
local spSetUnitPosition            = Spring.SetUnitPosition
local spSetUnitBlocking            = Spring.SetUnitBlocking
local spAddUnitDamage              = Spring.AddUnitDamage
local spDestroyUnit                = Spring.DestroyUnit
local spGiveOrderToUnit            = Spring.GiveOrderToUnit
local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData

local spMoveCtrlEnable      = Spring.MoveCtrl.Enable
local spMoveCtrlDisable     = Spring.MoveCtrl.Disable
local spMoveCtrlSetPosition = Spring.MoveCtrl.SetPosition

local CMD_WAIT = CMD.WAIT

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local wantedList = {}

local bunnyDefID
local bunnyWeaponID
local bunnyLosRadius

local cannotBeDamage = {}
local stuckBunnyWorkaround = {}

local bunnyGoodPosition = {}

local hiddenBunny = {}

local function HideBunny(unitID)
	--Spring.Echo("Hide " .. unitID)
	hiddenBunny[unitID] = true
	-- send the bunny to the stratosphere, cloak it
	spMoveCtrlEnable(unitID)
	local x, _, z = spGetUnitPosition(unitID)
	local y = spGetGroundHeight(x,z)
	spMoveCtrlSetPosition(unitID, x, y - 10, z)
	--Spring.SetUnitCloak(unitID, 4)
	--Spring.SetUnitSensorRadius(unitID, "los", 0)
	--Spring.SetUnitStealth(unitID, true)
	spSetUnitNoDraw(unitID, true)
	spSetUnitCollisionVolumeData(unitID, 20, 20, 20, 0, -3000, 0, 0, 1, 0)
	--Spring.SetUnitNoSelect(unitID, true)
	spSetUnitNoMinimap(unitID, true)
	--spGiveOrderToUnit(unitID, CMD.STOP, {}, 0)

	local frame = spGetGameFrame() + 450
	cannotBeDamage[unitID] = cannotBeDamage[unitID] or frame
	stuckBunnyWorkaround[frame] = stuckBunnyWorkaround[frame] or {count = 0, data = {}}
	stuckBunnyWorkaround[frame].count = stuckBunnyWorkaround[frame].count + 1
	stuckBunnyWorkaround[frame].data[stuckBunnyWorkaround[frame].count] = unitID
end


local function RestoreBunny(unitID, x, y, z)
	--Spring.SetUnitCloak(unitID, false)
	--Spring.Echo("RestoreBunny " .. unitID)
	if not hiddenBunny[unitID] then
		local frame = spGetGameFrame() + 1
		stuckBunnyWorkaround[frame] = stuckBunnyWorkaround[frame] or {count = 0, data = {}}
		stuckBunnyWorkaround[frame].count = stuckBunnyWorkaround[frame].count + 1
		stuckBunnyWorkaround[frame].data[stuckBunnyWorkaround[frame].count] = unitID
		cannotBeDamage[unitID] = cannotBeDamage[unitID] or frame
		bunnyGoodPosition[unitID] = bunnyGoodPosition[unitID] or {x = x, y = y, z = z}
		return
	end
	--Spring.Echo("RestoreBunny DONE")
	hiddenBunny[unitID] = nil
	spSetUnitPosition(unitID, x, z) -- fixes rectangle selection
	spMoveCtrlSetPosition(unitID, x, y, z)
	spSetUnitBlocking(unitID, false, false)	-- allows it to clip into wrecks (workaround for puppies staying in heaven)
	spMoveCtrlDisable(unitID)
	spSetUnitBlocking(unitID, true, true)	-- restores normal state once they land
	-- Spring.SetUnitSensorRadius(unitID, "los", bunnyLosRadius)
	-- Spring.SetUnitStealth(unitID, false)
	spSetUnitNoDraw(unitID, false)
	spSetUnitCollisionVolumeData(unitID, 20, 20, 20, 0, 0, 0, 0, 1, 0)
	cannotBeDamage[unitID] = false
	spAddUnitDamage(unitID, 15, 0, -1, WeaponDefNames["jumpscout_missile"].id) -- prevent bunny fountain
	-- Spring.SetUnitNoSelect(unitID, false)
	spSetUnitNoMinimap(unitID, false)
	spGiveOrderToUnit(unitID,CMD_WAIT, {}, 0)
	spGiveOrderToUnit(unitID,CMD_WAIT, {}, 0)
	GG.WaitWaitMoveUnit(unitID)
	-- spGiveOrderToUnit(unitID, CMD.STOP, {}, 0)
end

function GG.BunnyHandler_IsHidden(unitID)
	return (unitID and cannotBeDamage[unitID] and true) or false
end

function GG.BunnyHandler_Shot(unitID)
	-- the bunny fired its weapon, hide it
	HideBunny(unitID)
end

function gadget:Initialize()
	local bunnyDef =  UnitDefNames.jumpscout
	bunnyDefID = bunnyDef.id
	bunnyWeaponID = bunnyDef.weapons[1].weaponDef
	bunnyLosRadius = bunnyDef.losRadius
	wantedList = {bunnyWeaponID}
	if Script.SetWatchExplosion then
		Script.SetWatchExplosion(bunnyWeaponID, true)
	else
		Script.SetWatchWeapon(bunnyWeaponID, true)
	end
end

-- in event of shield impact, gets data about both units and passes it to UnitPreDamaged
function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile)
	local attackerTeam, attackerDefID, defenderTeam, defenderDefID
	if spValidUnitID(proOwnerID) then
		attackerDefID = spGetUnitDefID(proOwnerID)
		if attackerDefID ~= bunnyDefID then return false end	-- nothing to do with us, exit
		attackerTeam = spGetUnitTeam(proOwnerID)
	end
	if spValidUnitID(shieldCarrierUnitID) then
		defenderTeam = spGetUnitTeam(shieldCarrierUnitID)
		defenderDefID = spGetUnitDefID(shieldCarrierUnitID)
	end
	-- we don't actually have the weaponID, but can assume it is bunnyWeaponID
	gadget:UnitPreDamaged(shieldCarrierID, defenderDefID, defenderTeam, 0, false, bunnyWeaponID, proOwnerID, attackerDefID, attackerTeam, proID)
	return false
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return {bunnyWeaponID}
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam,projectileID)
	if weaponDefID == bunnyWeaponID and attackerID and spValidUnitID(attackerID) then
		if attackerTeam and unitTeam then
			-- attacker and attacked units are known (both units are alive)
			if spAreTeamsAllied(unitTeam, attackerTeam) then
				-- attacked unit is an ally
				if unitDefID == bunnyDefID then
					-- attacked unit is an allied bunny, cancel damage
					--Spring.Echo("UnitPreDamaged " .. attackerID)
					return 0
				end
			else
				-- attacked unit is an enemy, self-destruct the bunny
				spDestroyUnit(attackerID, false, true)
				return damage
			end
		end
	end

	return damage
end

function gadget:UnitDestroyed(unitID)
	cannotBeDamage[unitID] = nil
end

function gadget:UnitCreated(unitID)
	cannotBeDamage[unitID] = nil
end

function gadget:GameFrame(frame)
	if stuckBunnyWorkaround[frame] then
		for i = 1, stuckBunnyWorkaround[frame].count do
			local unitID = stuckBunnyWorkaround[frame].data[i]
			if cannotBeDamage[unitID] and cannotBeDamage[unitID] == frame and spValidUnitID(unitID) then
				local x, z
				if bunnyGoodPosition[unitID] then
					x,z = bunnyGoodPosition[unitID].x, bunnyGoodPosition[unitID].z
				else
					x,_,z = spGetUnitPosition(unitID)
				end
				local y = spGetGroundHeight(x,z)
				RestoreBunny(unitID, x, y, z)
			end
		end
		stuckBunnyWorkaround[frame] = nil
	end
end

function gadget:Explosion_GetWantedWeaponDef()
	return wantedList
end

function gadget:Explosion(weaponID, px, py, pz, ownerID)
	if weaponID == bunnyWeaponID and ownerID and spValidUnitID(ownerID) then
		-- the bunny landed
		RestoreBunny(ownerID, px, py, pz)
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
