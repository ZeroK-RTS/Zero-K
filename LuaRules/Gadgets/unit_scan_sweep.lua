
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:GetInfo()
	return {
		name      = "Scan Sweep",
		desc      = "Implements the Scan Sweep ability.",
		author    = "sprung, GoogleFrog",
		date      = "23/1/13",
		license   = "PD",
		layer     = 0,
		enabled   = true,
	}
end

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local scanDefs = include("LuaRules/Configs/scan_sweep_defs.lua")

local spCreateUnit                 = Spring.CreateUnit
local spDestroyUnit                = Spring.DestroyUnit
local spGetGameFrame               = Spring.GetGameFrame
local spGetUnitAllyTeam            = Spring.GetUnitAllyTeam
local spGetUnitsInCylinder         = Spring.GetUnitsInCylinder
local spSetUnitAlwaysVisible       = Spring.SetUnitAlwaysVisible
local spSetUnitBlocking            = Spring.SetUnitBlocking
local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData
local spSetUnitNeutral             = Spring.SetUnitNeutral
local spSetUnitLosMask             = Spring.SetUnitLosMask
local spSetUnitLosState            = Spring.SetUnitLosState
local spSetUnitSensorRadius        = Spring.SetUnitSensorRadius
local spSetUnitNoSelect            = Spring.SetUnitNoSelect
local spSetUnitNoDraw              = Spring.SetUnitNoDraw
local spSetUnitNoMinimap           = Spring.SetUnitNoMinimap
local spSpawnCEG                   = Spring.SpawnCEG
local veRandomPointInCircle        = Spring.Utilities.Vector.RandomPointInCircle

local SendToUnsync = SendToUnsynced
local ceil = math.ceil

local ally_count = #Spring.GetAllyTeamList() - 1

local scans = IterableMap.New() -- a table holding the fake scan units providing LoS.

local POKE_CLOAK_FREQUENCY = 60
local RADIUS_FUDGE = 10

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (scans[unitID]) then
		scans[unitID] = nil
	end
end

local function DecloakArea(ax, az, radius)
	local nearby_units = spGetUnitsInCylinder(ax, az, radius)
	for i = 1, #nearby_units do
		GG.PokeDecloakUnit(nearby_units[i])
	end
end

local function SetScannedArea(scanType, teamID, ax, az, radius, duration)
	local scanConf = scanDefs[scanType]
	radius = radius or scanConf.radius
	duration = duration or scanConf.duration
	
	local frame = spGetGameFrame()
	local scanID = spCreateUnit("fakeunit_los", ax, 10000, az, 0, teamID)
	if not scanID then
		-- Unit might not exist due to unit limit.
		-- This mainly happens if the team dies.
		return
	end
	local scanTime = frame + duration

	-- change LoS to the wanted value and make the unit not interact with the environment
	spSetUnitSensorRadius(scanID, "los", radius)
	spSetUnitSensorRadius(scanID, "airLos", radius)
	--spSetUnitSensorRadius(scanID, "radar", radius)
	spSetUnitSensorRadius(scanID, "sonar", radius)

	spSetUnitSensorRadius(scanID, "radarJammer", 0)
	spSetUnitSensorRadius(scanID, "sonarJammer", 0)
	spSetUnitNeutral(scanID, true)
	spSetUnitBlocking(scanID, false, false, false, false, false, false, false)
	spSetUnitNoSelect (scanID, true)
	spSetUnitNoDraw (scanID, true)
	spSetUnitNoMinimap (scanID, true)
	spSetUnitCollisionVolumeData(scanID
		, 0, 0, 0
		, 0, 0, 0
		, 0, 1, 0
	)

	for i = 0, ally_count do
		spSetUnitLosState(scanID, i, 0)
		spSetUnitLosMask (scanID, i, 15)
	end
	
	
	IterableMap.Add(scans, scanID, {
		x = ax, z = az,
		radius = radius,
		endFrame = scanTime,
		pokeCloakFrame = frame + POKE_CLOAK_FREQUENCY,
	})
	DecloakArea(ax, az, radius)
	
	-- reveal cloaked stuff without decloaking, Dust of Appearance style
	--local nearby_units = spGetUnitsInCylinder(ax, az, radius)
	--local scannerAllyTeam = spGetUnitAllyTeam(scanID)
	--for i = 1, #nearby_units do
	--	if ((not revealed[nearby_units[i]]) or (scanTime > revealed[nearby_units[i]])) then -- don't replace longer reveal time with a shorter one
	--		revealed[nearby_units[i]] = scanTime
	--	end
	--	spSetUnitLosState(nearby_units[i], scannerAllyTeam, 15)
	--	spSetUnitLosMask (nearby_units[i], scannerAllyTeam, 15)
	--end
	
	local cegCount = scanConf.count or 1
	if scanConf.cegDensity then
		local area = math.pi*radius*radius
		cegCount = math.ceil(area * scanConf.cegDensity)
	end
	
	local yVar = (scanConf.cegHeightVariance or 0)
	for i = 1, cegCount do
		local dir = math.random()*2*math.pi
		local spawnRad = math.pow(math.random(), 0.1) * (radius - RADIUS_FUDGE)
		local px, pz = ax + math.cos(dir) * spawnRad, az + math.sin(dir) * spawnRad
		local py = math.max(Spring.GetGroundHeight(px, pz), 0) + scanConf.cegHeight + math.random()*yVar - yVar*0.5
		spSpawnCEG(scanConf.ceg, px, py, pz)
	end
end

local function UpdateScanArea(scanID, scanData, index, frame)
	if (frame > scanData.endFrame) then -- vision time ran out
		spDestroyUnit(scanID, false, true)
		DecloakArea(scanData.x, scanData.z, scanData.radius)
		return true
	end
	if (frame > scanData.pokeCloakFrame) then -- vision time ran out
		DecloakArea(scanData.x, scanData.z, scanData.radius)
		scanData.pokeCloakFrame = frame + POKE_CLOAK_FREQUENCY
	end
end

function gadget:GameFrame(n)
	IterableMap.Apply(scans, UpdateScanArea, n)
end

function gadget:Initialize()
	GG.ScanSweep = {}
	GG.ScanSweep.AddArea = SetScannedArea
end
