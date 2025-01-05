--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modoption = Spring.GetModOptions().techk
function gadget:GetInfo()
	return {
		name      = "Replace Turret",
		desc      = "Adds API for replacing turrets of units with other units",
		author    = "GoogleFrog",
		date      = "30 December 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not gadgetHandler:IsSyncedCode() then
	return
end

include("LuaRules/Configs/customcmds.h.lua")

local CMD_ATTACK = CMD.ATTACK

-- TODO.
-- Make all damage to turret turn into damage onto mount
-- Make mount immune to other sources of damage.
-- Fill out and extract the mount defs
-- Front back offset issues with vehicle turrets, for offsetting colvol and possibly target pos.

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local TURRET_OFFSET_FUDGE = 2

local updateTargetNextFrame = {}
local turrets = {} -- Indexed turretIDs (unitIDs of turrets), values are unitID of the mount holding the turret.
local mountData = IterableMap.New() -- Indexed by unitID of mounts.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- To be moved to def files

local mountDefs = {
	[UnitDefNames["cloakraid"].id] = "chest",
	[UnitDefNames["jumpraid"].id] = "low_head",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Piece Utilities

local function HidePieceAndChildren(unitID, pieceName)
	local pieceMap = Spring.GetUnitPieceMap(unitID)
	local pieceID = pieceMap[pieceName]
	local toHide = {pieceID}
	
	Spring.UnitScript.CallAsUnit(unitID, function ()
		while #toHide > 0 do
			local pieceID = toHide[#toHide]
			toHide[#toHide] = nil
			local info = Spring.GetUnitPieceInfo(unitID, pieceID)
			Spring.UnitScript.Hide(pieceID)
			if info and info.children then
				for i = 1, #info.children do
					toHide[#toHide + 1] = pieceMap[info.children[i]]
				end
			end
		end
	end)
end

local function ShowOnlyPieceAndChildren(unitID, pieceName)
	local pieceMap = Spring.GetUnitPieceMap(unitID)
	local toHide = {Spring.GetUnitRootPiece(unitID)}
	
	Spring.UnitScript.CallAsUnit(unitID, function ()
		while #toHide > 0 do
			local pieceID = toHide[#toHide]
			toHide[#toHide] = nil
			local info = Spring.GetUnitPieceInfo(unitID, pieceID)
			Spring.UnitScript.Hide(pieceID)
			if info and info.children then
				for i = 1, #info.children do
					local name = info.children[i]
					if name ~= pieceName then
						toHide[#toHide + 1] = pieceMap[name]
					end
				end
			end
		end
	end)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Setup

local function ReplaceTurret(unitID, unitDefID, teamID, builderID, turretDefID)
	local mountPiece = mountDefs[unitDefID]
	local turretPiece = mountDefs[turretDefID]
	local pieceMap = Spring.GetUnitPieceMap(unitID)
	
	-- Hide the turret of the mount, and the body of the turret.
	HidePieceAndChildren(unitID, mountPiece)
	local turretID = Spring.CreateUnit(turretDefID, 0, 0, 0, 0, teamID, false, false, builderID)
	ShowOnlyPieceAndChildren(turretID, turretPiece)
	
	-- Attach the turret to the mount, and apply an offset because the turret is being attached
	-- at its feet, but the turret needs to line up with the mount
	local turretPieceMap = Spring.GetUnitPieceMap(turretID)
	local _, turretOffset = Spring.GetUnitPiecePosition(turretID, turretPieceMap[turretPiece])
	Spring.UnitAttach(unitID, turretID, pieceMap[mountPiece])
	GG.UnitModelRescale(turretID, 1, -turretOffset + TURRET_OFFSET_FUDGE)
	
	-- The turret is responsible for projectile collision, because it needs to aim from inside
	-- where the collision volumne of the mount would be. The collision volume is taken
	-- from the mount, and offset appropriately.
	local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ,
		volumeType, testType, primaryAxis = Spring.GetUnitCollisionVolumeData(unitID)
	local _, mountOffset = Spring.GetUnitPiecePosition(unitID, pieceMap[mountPiece])
	offsetY = offsetY - mountOffset
	Spring.SetUnitRulesParam(turretID, "aimpos_offset", -turretOffset)
	GG.OverrideBaseColvol(turretID, scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ, volumeType, testType, primaryAxis)
	Spring.SetUnitBlocking(unitID, true, true, false, false)
	Spring.SetUnitBlocking(turretID, false, false, true, true)
	Spring.SetUnitNoSelect(turretID, true)
	
	-- Mount is responsible for movement, so remove weapon firing ability and set range to mount range.
	local tud = UnitDefs[turretDefID]
	local ud = UnitDefs[unitDefID]
	local turretRange = math.max(tud.maxWeaponRange or 10, 10)
	local mountRange = math.max(ud.maxWeaponRange or 10, 10)
	GG.Attributes.AddEffect(unitID, "turret_replace", {
		weaponNum = 1,
		range = turretRange / mountRange,
		reload = 0
	})
	Spring.SetUnitMaxRange(unitID, turretRange)
	
	-- De-duplicate radar dots.
	Spring.SetUnitSonarStealth(unitID, true)
	Spring.SetUnitStealth(unitID, true)
	
	turrets[turretID] = unitID
	IterableMap.Add(mountData, unitID, {turretID = turretID})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Weapon and Target Handling

local function UpdateWeaponTarget(unitID, data)
	if data.forceUpdatingTarget then
		return
	end
	local tx, ty, tz = GG.GetAnyTypeOfUserUnitTarget(unitID)
	--Spring.Utilities.UnitEcho(unitID, tx)
	if tz then
		Spring.SetUnitTarget(data.turretID, tx, ty, tz, false, true)
		data.hasUserTarget = true
	elseif tx then
		Spring.SetUnitTarget(data.turretID, tx, false, true)
		data.hasUserTarget = true
	elseif data.hasUserTarget then
		Spring.SetUnitTarget(data.turretID, nil)
		data.hasUserTarget = false
	end
end

local function QueueForWeaponCheck(unitID)
	local data = IterableMap.Get(mountData, unitID)
	if data and not data.forceUpdatingTarget then
		data.forceUpdatingTarget = true
		updateTargetNextFrame = updateTargetNextFrame or {}
		updateTargetNextFrame[#updateTargetNextFrame + 1] = unitID
	end
end

local function UpdateWeaponChecks(n)
	IterableMap.ApplyFraction(mountData, 30, n%30, UpdateWeaponTarget)
	if updateTargetNextFrame then
		for i = 1, #updateTargetNextFrame do
			local unitID = updateTargetNextFrame[i]
			local data = IterableMap.Get(mountData, unitID)
			data.forceUpdatingTarget = false
			UpdateWeaponTarget(unitID, data)
		end
		updateTargetNextFrame = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua)
	QueueForWeaponCheck(unitID)
	return true
end

function gadget:GameFrame(n)
	UpdateWeaponChecks(n)
end


function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	local data = IterableMap.Get(mountData, unitID)
	if data then
		return 0
	end
	return damage
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	local ud = UnitDefs[unitDefID]
	if ud.name == "cloakraid" and teamID == 0 then
		ReplaceTurret(unitID, unitDefID, teamID, builderID, UnitDefNames["jumpraid"].id)
	end
	if ud.name == "jumpraid" and teamID == 1 then
		ReplaceTurret(unitID, unitDefID, teamID, builderID, UnitDefNames["cloakraid"].id)
	end
end