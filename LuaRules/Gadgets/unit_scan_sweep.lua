--[[
To-do:
	- actual decloaking (or simply revealing somehow) instead of seismic. For easy solution with seismic enable ping2blip
	- allow to specify whether scanning reveals the scanner unit
--]]

function gadget:GetInfo()
	return {
		name      = "Scan Sweep",
		desc      = "Implements the Scan Sweep ability.",
		author    = "sprung",
		date      = "23/1/13",
		license   = "PD",
		layer     = 0,
		enabled   = false,
	}
end

include("LuaRules/Configs/customcmds.h.lua")
local config = include("LuaRules/Configs/scan_sweep_defs.lua")

-- process the config values
for _, data in pairs(config) do
	data.scanTime = data.scanTime * 30
	data.cooldownTime = data.cooldownTime * 30
end

if (gadgetHandler:IsSyncedCode()) then

	-- performance
	local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
	local spCreateUnit = Spring.CreateUnit
	local spDestroyUnit = Spring.DestroyUnit
	local spGetGameFrame = Spring.GetGameFrame
	local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
	local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
	local spSetUnitNeutral = Spring.SetUnitNeutral
	local spSetUnitBlocking = Spring.SetUnitBlocking
	local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData
	local spSetUnitSensorRadius = Spring.SetUnitSensorRadius
	local spSetUnitLosState = Spring.SetUnitLosState
	local spSetUnitLosMask = Spring.SetUnitLosMask
	local SendToUnsync = SendToUnsynced
	local spSetUnitNoSelect = Spring.SetUnitNoSelect
	local spSetUnitNoDraw = Spring.SetUnitNoDraw
	local spSetUnitNoMinimap = Spring.SetUnitNoMinimap
	local spSpawnCEG = Spring.SpawnCEG
	local ceil = math.ceil

	local scanSweepCmdDesc = {
		id = CMD_SCAN_SWEEP,
		type = CMDTYPE.ICON_MAP,
		name = 'Scan',
		cursor = 'Centroid',
		action = 'scan_sweep',
		tooltip = 'Scan the selected location.',
	}

	local editCmdDesc = {}
	local scans = {} -- a table holding the fake scan units providing LoS.
	local cooldowns = {} -- a table holding scanners that are undergoing cooldown.

	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if (config[unitDefID]) then
			spInsertUnitCmdDesc(unitID, scanSweepCmdDesc)
		end
	end

	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
		if (cooldowns[unitID]) then
			cooldowns[unitID] = nil
		elseif (scans[unitID]) then
			scans[unitID] = nil
		end
	end

	local ally_count = #Spring.GetAllyTeamList() - 1
	function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
		if (cmdID ~= CMD_SCAN_SWEEP) then return false end -- Not recognized
		if (cooldowns[unitID]) then return true, false end -- Recognized, but not done

		cooldowns[unitID] = spGetGameFrame() + config[unitDefID].cooldownTime

		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_SCAN_SWEEP)
		editCmdDesc.disabled = true
		editCmdDesc.name = 'Scanning...'
		spEditUnitCmdDesc(unitID, cmdDescID, editCmdDesc)

		local scanID = spCreateUnit("fakeunit_los", cmdParams[1], cmdParams[2], cmdParams[3], 0, teamID)
		scans[scanID] = spGetGameFrame() + config[unitDefID].scanTime

		-- change LoS to the wanted value and make the unit not interact with the environment
		spSetUnitSensorRadius(scanID, "los", config[unitDefID].scanRadius)
		spSetUnitSensorRadius(scanID, "airLos", config[unitDefID].scanRadius)
		spSetUnitSensorRadius(scanID, "radar", config[unitDefID].scanRadius)
		spSetUnitSensorRadius(scanID, "sonar", config[unitDefID].scanRadius)
		spSetUnitSensorRadius(scanID, "seismic", config[unitDefID].scanRadius)

		spSetUnitSensorRadius(scanID, "radarJammer", 0)
		spSetUnitSensorRadius(scanID, "sonarJammer", 0)
		spSetUnitNeutral(scanID, true)
		spSetUnitBlocking(scanID, false, false, false)
		spSetUnitNoSelect (scanID, true)
		spSetUnitNoDraw (scanID, true)
		spSetUnitNoMinimap (scanID, true)
		spSetUnitCollisionVolumeData(scanID
			, 0, 0, 0
			, 0, 0, 0
			, 0, 1, 0
		)

		for i = 1, ally_count do
			spSetUnitLosState(scanID, i, 0)
			spSetUnitLosMask (scanID, i, 15)
		end

		spSpawnCEG ("scan_sweep", cmdParams[1], cmdParams[2], cmdParams[3])

		_G.ScanSweep = scanID
		_G.ScanRadius = config[unitDefID].scanRadius
		SendToUnsync("ScanSweep")
		_G.ScanSweep = nil
		_G.ScanRadius = nil

		return true, true -- Recognized and finished
	end

	function gadget:GameFrame(n)
		for id, timer in pairs(scans) do
			if (n > timer) then -- vision time ran out
				_G.ScanSweep = id
				SendToUnsync("ScanEnd")
				_G.ScanSweep = nil
				spDestroyUnit(id, false, true)
			end
		end
		for id, timer in pairs(cooldowns) do
			if (n > timer) then -- cooldown expired, reenable command
				editCmdDesc.disabled = false
				editCmdDesc.name = 'Scan'
				cooldowns[id] = nil
			else -- cooldown still ticking, reflect time left in tooltip
				editCmdDesc.disabled = true
				editCmdDesc.name = 'Scan (' .. ceil((timer - n) / 30) .. ')'
			end
			local cmdDescID = spFindUnitCmdDesc(id, CMD_SCAN_SWEEP)
			spEditUnitCmdDesc(id, cmdDescID, editCmdDesc)
		end
	end

else -- un/sync

	local spGetUnitPosition = Spring.GetUnitPosition
	local spGetUnitDefID = Spring.GetUnitDefID
	local glColor = gl.Color
	local glDrawGroundCircle = gl.DrawGroundCircle

	local scans = {}

	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_SCAN_SWEEP)
		Spring.SetCustomCommandDrawData(CMD_SCAN_SWEEP, "Centroid", {0.0, 0.5, 1, 1})

		gadgetHandler:AddSyncAction("ScanSweep", function()
			local unitID = SYNCED.ScanSweep
			local xx, yy, zz = spGetUnitPosition(unitID)
			scans[unitID] = { x = xx, y = yy, z = zz, r = SYNCED.ScanRadius }
		end)

		gadgetHandler:AddSyncAction("ScanEnd", function()
			local unitID = SYNCED.ScanSweep
			scans[unitID] = nil
		end)
	end

	function gadget:DrawWorldPreUnit()
		glColor(0.0, 0.5, 1.0, 0.5)
		for _, scan in pairs(scans) do
			glDrawGroundCircle(scan.x, scan.y, scan.z, scan.r, 32)
		end
		glColor(1,1,1,1)
	end
end