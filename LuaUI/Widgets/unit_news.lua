function widget:GetInfo()
  return {
    name      = "Unit News",
    desc      = "Informs player of unit completion/death events",
    author    = "KingRaptor",
    date      = "July 26, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local soundTimeout = 0

local lastUpdate = 0
local updatePeriod = 0.2
local mIncome = 0
local _

--SPEEDUPS

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spEcho = Spring.Echo
local spGetTeam = Spring.GetUnitTeam
local spGetGameSeconds = Spring.GetGameSeconds
local spInView = Spring.IsUnitInView
local spGetTeamRes = Spring.GetTeamResources
local spGetLastAttacker = Spring.GetUnitLastAttacker
local spGetGameFrame = Spring.GetGameFrame
local spPlaySoundFile = Spring.PlaySoundFile

local playerID = Spring.GetMyPlayerID()
local teamID = Spring.GetMyTeamID()

--------------------------
--CONFIG
--------------------------
local timeoutConstant = 150

local sounds = {
	UnitComplete = {file = "LuaUI/sounds/voices/productionc_arm_1.wav", timeout = timeoutConstant},
	StructureComplete = {file = "LuaUI/sounds/voices/constructionc_arm_1.wav", timeout = timeoutConstant},
}

local noMonitor = {
	[UnitDefNames.terraunit.id] = true,
}

local useSounds = true
local mFactor = 5 --multiply by current M income to get the minimum cost for newsworthiness
local useDeathMinCost = true
local useCompleteMinCost = true
local logDeathInView = true
local logCompleteInView = true

function widget:Initialize()
  if Spring.GetSpectatingState() or Spring.IsReplay() then
    widgetHandler:RemoveWidget()
    return true
  end
end

local function CheckSpecState()
  if Spring.GetSpectatingState() then
	Spring.Echo("<Unit News> Spectator mode. Widget removed.")
	widgetHandler:RemoveWidget()
  end
end

function widget:Update()
	local now = spGetGameSeconds()
	if (now < lastUpdate + updatePeriod) then
		return
	end
	lastUpdate = now
	CheckSpecState()
	_, _, _, mIncome, _ = spGetTeamRes(teamID, "metal")
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	--don't report cancelled constructions etc.
	local killer = spGetLastAttacker(unitID)
	if killer == nil or killer == -1 or noMonitor[unitDefID] then return end
	local ud = UnitDefs[unitDefID]
	--don't bother player with cheap stuff
	if (spGetTeam(unitID) ~= teamID) or (ud.metalCost < (mIncome * mFactor) and useDeathMinCost) then return end
	--can u c me?
	if (spInView(unitID)) and (logDeathInView == false) then return end
	if (ud.canFly) then spEcho("Aircraft shot down: " .. ud.humanName)
	elseif (ud.isBuilding) then spEcho("Building destroyed: " .. ud.humanName)
	elseif (ud.TEDClass == "SHIP") or (ud.TEDClass == "WATER") then spEcho("Vessel sunk: " .. ud.humanName)
	else spEcho("Unit lost: " .. ud.humanName)
	end
end



function widget:UnitFinished(unitID, unitDefID, unitTeam)
	--visibility check
	if (spGetTeam(unitID) ~= teamID) or (spInView(unitID)) and (logCompleteInView == false) then return end
	local ud = UnitDefs[unitDefID]
	local frame = spGetGameFrame()
	-- cheap units aren't newsworthy unless they're builders
	if (not ud.isBuilder and (UnitDefs[unitDefID].metalCost < (mIncome * mFactor) and useCompleteMinCost)) or noMonitor[unitDefID] then return end
	if (not ud.canMove) or (ud.isFactory) then
		spEcho(ud.humanName .. ": construction completed")
		if useSounds and soundTimeout < frame then
			spPlaySoundFile(sounds.StructureComplete.file)
			soundTimeout = frame + sounds.StructureComplete.timeout
		end
	else
		spEcho(ud.humanName .. ": unit operational")
		if useSounds and soundTimeout < frame then
			spPlaySoundFile(sounds.UnitComplete.file)
			soundTimeout = frame + sounds.UnitComplete.timeout
		end
	end
end
