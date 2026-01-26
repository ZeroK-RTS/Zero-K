
if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name      = "Unit Reload Pause",
		desc      = "Handles Unit Reload Pause",
		author    = "XNTEABDSC", -- v1 CarReparier & GoogleFrog
		date      = "2025", -- v1 2009-11-27
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

local INLOS_ACCESS = {inlos = true}

local spSetUnitWeaponState=Spring.SetUnitWeaponState
local spSetUnitRulesParam=Spring.SetUnitRulesParam
local spGetUnitWeaponState     = Spring.GetUnitWeaponState
local spGetGameFrame           = Spring.GetGameFrame



---@type table<UnitId,table<number,boolean>>
local UnitsWeaponsReloadPaused={}

local UPDATE_PERIOD=3

local function UpdateUnitReloadPause(unitId,weaponNum,reloadState,reloadTime,gameFrame)
	reloadState = reloadState or spGetUnitWeaponState(unitID, weaponNum , 'reloadState')
	reloadTime  = reloadTime or spGetUnitWeaponState(unitID, weaponNum , 'reloadTime')
	gameFrame = gameFrame or spGetGameFrame()
	
	local newReload = 100000 -- set a high reload time so healthbars don't judder. NOTE: math.huge is TOO LARGE
	if reloadState < gameFrame then -- unit is already reloaded, so set unit to almost reloaded
		spSetUnitWeaponState(unitId, weaponNum, {reloadTime = newReload, reloadState = gameFrame+UPDATE_PERIOD+1})
	else
		local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
		spSetUnitWeaponState(unitId, weaponNum, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
	end
end

local function UnitReloadUnpause(unitId,weaponNum)
	local UnitWeaponsReloadPaused=UnitsWeaponsReloadPaused[unitId]
	if not UnitWeaponsReloadPaused then
		return
	end
	local UnitWeaponReloadPaused=UnitWeaponsReloadPaused[weaponNum]
	if not UnitWeaponReloadPaused then
		return
	end
	UnitWeaponsReloadPaused[weaponNum]=nil
	if not next(UnitWeaponsReloadPaused) then
		spSetUnitRulesParam(unitId, "reloadPaused", 0, INLOS_ACCESS)
	end
end

local function UnitReloadPause(unitId,weaponNum,reloadState,reloadTime,gameFrame)
	local UnitWeaponsReloadPaused=UnitsWeaponsReloadPaused[unitId]
	if not UnitWeaponsReloadPaused then
		UnitWeaponsReloadPaused={}
		UnitsWeaponsReloadPaused[unitId]=UnitWeaponsReloadPaused
	end
	local UnitWeaponReloadPaused=UnitWeaponsReloadPaused[weaponNum]
	if UnitWeaponReloadPaused then
		return
	end
	UnitWeaponsReloadPaused[weaponNum]=true
	spSetUnitRulesParam(unitID, "reloadPaused", 1, INLOS_ACCESS)
	UpdateUnitReloadPause(unitId,weaponNum,reloadState,reloadTime,gameFrame)

end

GG.UnitReloadPause={
	UnitReloadPause=UnitReloadPause,
	UnitReloadUnpause=UnitReloadUnpause,
	UpdateUnitReloadPause=UpdateUnitReloadPause
}

function gadget:GameFrame(f)
	if f % UPDATE_PERIOD == 1 then
		for unitID, weapons in pairs(UnitsWeaponsReloadPaused) do
			for weaponNum,_ in pairs(UnitsWeaponsReloadPaused) do
				UpdateUnitReloadPause(unitID,weaponNum,nil,nil,f)
			end
		end
	end
end