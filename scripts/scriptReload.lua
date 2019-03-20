-- TODO: CACHE INCLUDE FILE
-- May not be worth it due to all the local data.
local ALLY_ACCESS = {allied = true}

local extenalFunctions = {}

local gunCount, reloadTime
local loadedGunCount
local gunReloadStartFrame = {}
local penaltyTime = {}

function extenalFunctions.SetupScriptReload(newGunCount, newReloadTime)
	gunCount, reloadTime = newGunCount, newReloadTime
	loadedGunCount = gunCount
end

local function SetReloadFrame()
	local minReloadFrame = math.huge
	local minReloadGunIdx = -1
	local allReloaded = true

	for i = 0, gunCount-1 do
		if gunReloadStartFrame[i] then
			allReloaded = false

			local value = gunReloadStartFrame[i] + (penaltyTime[i] or 0)
			if value < minReloadFrame then
				minReloadFrame = value
				minReloadGunIdx = i
			end
		end
	end

	if allReloaded then
		return false
	end

	minReloadFrame = minReloadFrame + reloadTime

	Spring.SetUnitRulesParam(unitID, "scriptReloadFrame", minReloadFrame, ALLY_ACCESS)
	return minReloadGunIdx, minReloadFrame
end

local zeroReloadMultSet
--only gets called if unit was disabled or slowed down (reloadMult~=1.0)
local function UpdateReloadPenalty(gunNum, reloadMult)
	local penalty = (1 - reloadMult) * 3
	penaltyTime[gunNum] = (penaltyTime[gunNum] or 0) + penalty
	local minReloadGunIdx, minReloadFrame = SetReloadFrame()
	if (gunNum == minReloadGunIdx) and ((reloadMult > 0.0) or (not zeroReloadMultSet)) then
		Spring.SetUnitRulesParam(unitID, "scriptReloadPercentage", 1 - ((minReloadFrame-Spring.GetGameFrame())) / reloadTime, ALLY_ACCESS)
		zeroReloadMultSet = (reloadMult == 0.0)
	end
end

-- returns true if all guns have been reloaded, false otherwise
function extenalFunctions.GunLoaded(gunNum)
	gunReloadStartFrame[gunNum] = nil
	penaltyTime[gunNum] = nil

	loadedGunCount = loadedGunCount + 1
	Spring.SetUnitRulesParam(unitID, "scriptLoaded", loadedGunCount, ALLY_ACCESS)

	if not SetReloadFrame() then
		Spring.SetUnitRulesParam(unitID, "scriptReloadFrame", nil, ALLY_ACCESS)
		Spring.SetUnitRulesParam(unitID, "scriptReloadPercentage", nil, ALLY_ACCESS)
	end
	return loadedGunCount == gunCount
end

function extenalFunctions.GunStartReload(gunNum)
	gunReloadStartFrame[gunNum] = Spring.GetGameFrame()
	penaltyTime[gunNum] = 0
	zeroReloadMultSet = false

	loadedGunCount = loadedGunCount - 1
	Spring.SetUnitRulesParam(unitID, "scriptLoaded", loadedGunCount, ALLY_ACCESS)

	SetReloadFrame()
end

--reloadDuration in frames
function extenalFunctions.SleepAndUpdateReload(gunNum, reloadDuration)
	local reloadTimer = 0
	local percentageSet

	while reloadTimer < reloadDuration do
		local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		local reloadMult = (stunnedOrInbuild and 0) or (Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1)

		reloadTimer = reloadTimer + reloadMult * 3

		if percentageSet and (reloadMult == 1.0) then
			percentageSet = false
			Spring.SetUnitRulesParam(unitID, "scriptReloadPercentage", nil, ALLY_ACCESS)
		end

		if reloadMult < 1.0 then
			percentageSet = true
			UpdateReloadPenalty(gunNum, reloadMult)
		end

		Sleep(100) --3 frames
	end
end

return extenalFunctions
