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

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local TURRET_OFFSET_FUDGE = 2

local turrets = {}
local mountData = IterableMap.New()

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

local mountDefs = {
	[UnitDefNames["cloakraid"].id] = "chest",
	[UnitDefNames["jumpraid"].id] = "low_head",
}

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

local function UpdateWeaponTarget(unitID, data)
	-- Doesn't work, needs to be replaced with reading the first order of the command queue and SetTarget API
	local targetType, isUser, params = Spring.GetUnitWeaponTarget(unitID, 0)
	Spring.Utilities.UnitEcho(unitID, targetType)
	if targetType and targetType == 1 then
		Spring.SetUnitTarget(data.turretID, params, false, isUser)
	elseif targetType and targetType == 2 then
		Spring.SetUnitTarget(data.turretID, params[1], params[2], params[3], false, isUser)
	end
end

function gadget:GameFrame(n)
	--IterableMap.ApplyFraction(mountData, 20, n%20, UpdateWeaponTarget)
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