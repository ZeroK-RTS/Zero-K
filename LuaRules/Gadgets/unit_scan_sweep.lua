--[[
To-do:
	* per-allyteam reveal timers. Currently your scans' reveal time gets extended if someone else also scans the same units.
]]--

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
	data.scanTime = (data.scanTime or 5) * 30
	data.cooldownTime = (data.cooldownTime or 60) * 30
	data.selfRevealTime = (data.selfRevealTime or 0) * 30 end
	if (not data.scanRadius) then data.scanRadius = 300 end
end

if (gadgetHandler:IsSyncedCode()) then

	local spInsertUnitCmdDesc          = Spring.InsertUnitCmdDesc
	local spCreateUnit                 = Spring.CreateUnit
	local spDestroyUnit                = Spring.DestroyUnit
	local spEditUnitCmdDesc            = Spring.EditUnitCmdDesc
	local spFindUnitCmdDesc            = Spring.FindUnitCmdDesc
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

	local SendToUnsync = SendToUnsynced
	local ceil = math.ceil

	local ally_count = #Spring.GetAllyTeamList() - 1

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
	local revealed = {} -- a table holding scanners that are revealed.

	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if (config[unitDefID]) then
			spInsertUnitCmdDesc(unitID, scanSweepCmdDesc)
		end
	end

	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
		if (cooldowns[unitID]) then
			cooldowns[unitID] = nil
		end
		if (revealed[unitID]) then
			revealed[unitID] = nil
		end
		if (scans[unitID]) then
			scans[unitID] = nil
			SendToUnsync("scan_end", unitID)
		end
	end

	function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
		if (cmdID ~= CMD_SCAN_SWEEP) then return false end -- Not recognized
		if (cooldowns[unitID]) then return true, false end -- Recognized, but not done (keep in queue)

		local current_frame = spGetGameFrame()

		cooldowns[unitID] = current_frame + config[unitDefID].cooldownTime

		-- self revelation
		if (config[unitDefID].selfRevealTime > 0) then
			revealed[unitID] = current_frame + config[unitDefID].selfRevealTime
			for i = 0, ally_count do
				spSetUnitLosState(unitID, i, 15)
				spSetUnitLosMask (unitID, i, 15)
			end
		end
 
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_SCAN_SWEEP)
		editCmdDesc.disabled = true
		editCmdDesc.name = 'Scanning...'
		spEditUnitCmdDesc(unitID, cmdDescID, editCmdDesc)

		local scanID = spCreateUnit("fakeunit_los", cmdParams[1], cmdParams[2], cmdParams[3], 0, teamID)
		local scanTime = current_frame + config[unitDefID].scanTime
		scans[scanID] = scanTime

		-- change LoS to the wanted value and make the unit not interact with the environment
		spSetUnitSensorRadius(scanID, "los", config[unitDefID].scanRadius)
		spSetUnitSensorRadius(scanID, "airLos", config[unitDefID].scanRadius)
		spSetUnitSensorRadius(scanID, "radar", config[unitDefID].scanRadius)
		spSetUnitSensorRadius(scanID, "sonar", config[unitDefID].scanRadius)

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

		for i = 0, ally_count do
			spSetUnitLosState(scanID, i, 0)
			spSetUnitLosMask (scanID, i, 15)
		end

		-- reveal cloaked stuff without decloaking, Dust of Appearance style
		if (config[unitDefID].revealCloaked) then
			local nearby_units = spGetUnitsInCylinder(cmdParams[1], cmdParams[3], config[unitDefID].scanRadius)
			local scannerAllyTeam = spGetUnitAllyTeam(unitID)
			for i = 1, #nearby_units do
				if ((not revealed[nearby_units[i]]) or (scanTime > revealed[nearby_units[i]])) then -- don't replace longer reveal time with a shorter one
					revealed[nearby_units[i]] = scanTime
				end
				spSetUnitLosState(nearby_units[i], scannerAllyTeam, 15)
				spSetUnitLosMask (nearby_units[i], scannerAllyTeam, 15)
			end
		end

		-- visuals (CEG + circle)
		if (config[unitDefID].ceg) then
			spSpawnCEG(config[unitDefID].ceg, cmdParams[1], cmdParams[2], cmdParams[3])
		end
		SendToUnsync("scan_start", scanID, config[unitDefID].scanRadius)

		return true, true -- Recognized and finished (remove from Q)
	end

	function gadget:GameFrame(n)
		for id, timer in pairs(scans) do
			if (n > timer) then -- vision time ran out
				spDestroyUnit(id, false, true)
			end
		end
		for id, timer in pairs(revealed) do
			if (n > timer) then
				for i = 0, ally_count do
					spSetUnitLosMask (id, i, 0)
				end
				revealed[id] = nil
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

	local spGetUnitPosition  = Spring.GetUnitPosition
	local spGetUnitDefID     = Spring.GetUnitDefID

	local glColor            = gl.Color
	local glDrawGroundCircle = gl.DrawGroundCircle

	local scans = {}

	local function scan_start (_, unitID, scanRadius)
		local xx, yy, zz = spGetUnitPosition(unitID)
		scans[unitID] = { x = xx, y = yy, z = zz, r = scanRadius }
	end

	local function scan_end (_, unitID)
		scans[unitID] = nil
	end

	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_SCAN_SWEEP)
		Spring.SetCustomCommandDrawData(CMD_SCAN_SWEEP, "Centroid", {0.0, 0.5, 1, 1})

		gadgetHandler:AddSyncAction("scan_start", scan_start)
		gadgetHandler:AddSyncAction("scan_end", scan_end)
	end

	function gadget:DrawWorldPreUnit()
		glColor(0.0, 0.5, 1.0, 0.5)
		for _, scan in pairs(scans) do
			glDrawGroundCircle(scan.x, scan.y, scan.z, scan.r, 32)
		end
		glColor(1,1,1,1)
	end
end