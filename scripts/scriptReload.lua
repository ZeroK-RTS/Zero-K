
local ALLY_ACCESS = {allied = true}

local extenalFunctions = {}

local gunCount, reloadTime
local reloads = {}
local reloadSpeed = 1

function extenalFunctions.SetupScriptReload(newGunCount, newReloadTime)
	gunCount, reloadTime = newGunCount, newReloadTime
end

local function SetReloadFrame()
	local highestProgress
	for i = 1, gunCount do
		if not reloads[i] then
			return false
		end
		if (not highestProgress) or (reloads[i] > highestProgress) then
			highestProgress = reloads[i]
		end
	end
	
	if not highestProgress then
		return false
	end
	
	local gameFrame = Spring.GetGameFrame()
	local reloadFrame = gameFrame + reloadTime - highestProgress
	Spring.SetUnitRulesParam(unitID, "scriptReloadFrame", reloadFrame, ALLY_ACCESS)
	
	return true
end

local function UpdateReloadTime()
	if not SetReloadFrame() then
		Spring.SetUnitRulesParam(unitID, "scriptReloadFrame", nil, ALLY_ACCESS)
	end
end

function extenalFunctions.UpdateReload(index, progress, newSpeed)
	reloads[index] = progress
	if not newSpeed then
		local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		newSpeed = (stunnedOrInbuild and 0) or (Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1)
	end
	reloadSpeed = newSpeed
	UpdateReloadTime()
end

function extenalFunctions.GunLoaded(index)
	reloads[index] = false
	UpdateReloadTime()
end

return extenalFunctions
