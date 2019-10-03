function widget:GetInfo()
	return {
		name      = "BuildETA",
		desc      = "Displays estimated time of arrival for builds",
		author    = "trepan (modified by jK) (stall ETA fixed by Google Frog)",
		date      = "Feb, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true,
	}
end

local gl     = gl
local Spring = Spring
local table  = table

local stockpilerDefNames = {
	"staticnuke",
	"subtacmissile",
	"shipcarrier"
}

local stockpilerDefs = {}
for i = 1, #stockpilerDefNames do
	stockpilerDefs[UnitDefNames[stockpilerDefNames[i]].id] = true
end
stockpilerDefNames = nil

local etaTable = {}
local stockpileEtaTable = {}

local fontSize = 8
local displayETA = true
local previousFullview = false

options_path = 'Settings/Interface/Build ETA'
options_order = { 'showonlyonshift', 'showforicons', 'fontsize', 'drawHeight'}
options = {
	showonlyonshift = {
		name = 'Show only on shift',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	showforicons = {
		name = 'Show for icons',
		desc = 'Whether to show for radar icons during strategic zoom.',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	fontsize = {
		name = 'Size',
		type = 'number',
		value = 9,
		min = 2, max = 100, step = 1,
		OnChange = function(self)
			fontSize = self.value
		end,
	},
	drawHeight = {
		name = 'Display Height',
		type = 'number',
		value = 1500,
		min = 0, max = 5000, step = 1,
	},
}

local vsx, vsy = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
end

local function MakeETA(unitID,unitDefID)
	if (unitDefID == nil) then
		return nil
	end
	local buildProgress = select(5, Spring.GetUnitHealth(unitID))
	if (buildProgress == nil) then
		return nil
	end

	local ud = UnitDefs[unitDefID]
	if (ud == nil)or(ud.height == nil) then
		return nil
	end

	return {
		firstSet = true,
		lastTime = Spring.GetGameSeconds(),
		lastProg = buildProgress,
		rate     = nil,
		lastNewTime = nil,
		timeLeft = nil,
		yoffset  = Spring.Utilities.GetUnitHeight(ud) + 14,
	}
end

local build_eta_translation
function languageChanged ()
	build_eta_translation = WG.Translate ("interface", "build_eta")
end

function widget:Shutdown()
	WG.ShutdownTranslation(GetInfo().name)
end

local function InitializeUnits()
	etaTable = {}
	stockpileEtaTable = {}
	local spect, spectFull = Spring.GetSpectatingState()
	local myAllyTeam = Spring.GetMyAllyTeamID()
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		if (Spring.GetUnitAllyTeam(unitID) == myAllyTeam) or (spect and spectFull) then
			local buildProgress = select(5, Spring.GetUnitHealth(unitID))
			if (buildProgress < 1) then
				etaTable[unitID] = MakeETA(unitID, Spring.GetUnitDefID(unitID))
			elseif (stockpilerDefs[Spring.GetUnitDefID(unitID)]) then
				stockpileEtaTable[unitID] = {
					firstSet = true,
					lastTime = Spring.GetGameFrame(),
					lastProg = Spring.GetUnitRulesParam(unitID, "gadgetStockpile") or 0,
					rate     = nil,
					lastNewTime = nil,
					timeLeft = nil,
					negative = false,
					yoffset  = Spring.Utilities.GetUnitHeight(UnitDefs[Spring.GetUnitDefID(unitID)]) + 14,
				}
			end
		end
	end
end

function widget:Initialize()
	WG.InitializeTranslation (languageChanged, GetInfo().name)
	InitializeUnits()
	previousFullview = select(2, Spring.GetSpectatingState())
	WG.etaTable = etaTable
end

local function updateTime(bi, dt, newTime, negative)
	if bi.lastNewTime and dt < 2 and (bi.negative == negative) then
		bi.timeLeft = ((newTime + bi.lastNewTime - dt)/2)
	else
		bi.timeLeft = newTime
	end
	bi.negative = negative
	bi.lastNewTime = newTime
end

function widget:GameFrame(n)
	-- 6N because stockpile happens in such increments, else its eta fluctuates
	if (n % 6 ~= 0) then
		return
	end

	local _,_,pause = Spring.GetGameSpeed()
	if (pause) then
		return
	end

	local gs = Spring.GetGameSeconds()

	for unitID, bi in pairs(stockpileEtaTable) do
		local buildProgress = Spring.GetUnitRulesParam(unitID, "gadgetStockpile") or 0
		local dp = buildProgress - bi.lastProg
		local dt = n - bi.lastTime

		if (dt >= 30) then
			if (buildProgress <= bi.lastProg) then
				bi.rate = nil
				bi.timeLeft = nil
				bi.firstSet = true
			else
				local rate = 30 * dp / dt

				if (bi.firstSet) then
					if (buildProgress > 0.001) then
						bi.firstSet = false
					end
				else
					updateTime(bi, dt, (1 - buildProgress) / rate, false)
				end
			end
			bi.lastTime = n
			bi.lastProg = buildProgress
		end
	end

	for unitID, bi in pairs(etaTable) do
		local buildProgress = select(5, Spring.GetUnitHealth(unitID)) or 0
		if buildProgress == 1 then
			etaTable[unitID] = nil
		else
			local dp = buildProgress - bi.lastProg
			local dt = gs - bi.lastTime
			if (dt > 2) then
				bi.firstSet = true
				bi.rate = nil
				bi.timeLeft = nil
			end
			
			if dt > 0.5 then
				local rate = dp / dt
				if (rate ~= 0) then
					if (bi.firstSet) then
						if (buildProgress > 0.001) then
							bi.firstSet = false
						end
					else
						if (rate > 0) then
							updateTime(bi, dt, (1 - buildProgress) / rate, false)
						elseif (rate < 0) then
							updateTime(bi, dt, -buildProgress / rate, true)
						end
					end
					bi.lastTime = gs
					bi.lastProg = buildProgress
				end
			end
		end
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	local buildProgress = select(5, Spring.GetUnitHealth(unitID))
	if (buildProgress < 1) then
		local spect,spectFull = Spring.GetSpectatingState()
		local myTeam = Spring.GetMyTeamID()
		if Spring.AreTeamsAllied(unitTeam, myTeam) or (spect and spectFull) then
			etaTable[unitID] = MakeETA(unitID,unitDefID)
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	etaTable[unitID] = nil
	stockpileEtaTable[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	local spec = Spring.GetSpectatingState()
	if (spec) then
		return
	end

	if Spring.AreTeamsAllied (Spring.GetMyTeamID(), newTeam) then
		local buildProgress = select(5, Spring.GetUnitHealth(unitID))
		if (buildProgress < 1) then
			if not etaTable[unitID] then
				etaTable[unitID] = MakeETA(unitID,Spring.GetUnitDefID(unitID))
			end
		elseif stockpilerDefs[Spring.GetUnitDefID(unitID)] and not stockpileEtaTable[unitID] then
			stockpileEtaTable[unitID] = {
				firstSet = true,
				lastTime = Spring.GetGameFrame(),
				lastProg = buildProgress,
				rate     = nil,
				lastNewTime = nil,
				timeLeft = nil,
				negative = false,
				yoffset  = Spring.Utilities.GetUnitHeight(UnitDefs[Spring.GetUnitDefID(unitID)]) + 14,
			}
		end
	else
		etaTable[unitID] = nil
		stockpileEtaTable[unitID] = nil
	end
end

local terraunitDefID = UnitDefNames["terraunit"] and UnitDefNames["terraunit"].id

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitDefID ~= terraunitDefID then
		etaTable[unitID] = nil
	end

	if stockpilerDefs[unitDefID] and not stockpileEtaTable[unitID] then -- reclaim into rebuild
		stockpileEtaTable[unitID] = {
			firstSet = true,
			lastTime = Spring.GetGameFrame(),
			lastProg = Spring.GetUnitRulesParam(unitID, "gadgetStockpile") or 0,
			rate     = nil,
			lastNewTime = nil,
			timeLeft = nil,
			negative = false,
			yoffset  = Spring.Utilities.GetUnitHeight(UnitDefs[unitDefID]) + 14,
		}
	end
end

function widget:Update()
	if options.drawHeight.value < 5000 then
		local cs = Spring.GetCameraState()
		local gy = Spring.GetGroundHeight(cs.px, cs.pz)
		local cameraHeight
		if cs.name == "ov" then
			displayETA = true
			return
		elseif cs.name == "ta" then
			cameraHeight = cs.height - gy
		else
			cameraHeight = cs.py - gy
		end
		displayETA = options.drawHeight.value > cameraHeight
	end
	local newFullview = select(2, Spring.GetSpectatingState())
	if newFullview ~= previousFullview then
		InitializeUnits()
		previousFullview = newFullview
	end
end

local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spIsUnitIcon = Spring.IsUnitIcon
local function DrawEtaText(unitID, timeLeft,yoffset, negative)
	if not options.showforicons.value and spIsUnitIcon(unitID) then
		return
	end

	local etaStr
	if (timeLeft == nil) then
		etaStr = '\255\255\255\1' .. build_eta_translation .. ' \255\1\1\255???'
	else
		local color = negative and '\255\255\1\1' or '\255\1\255\1'
		etaStr = "\255\255\255\1" .. string.format('%s %s%d:%02d', build_eta_translation, color, timeLeft / 60, timeLeft % 60)
	end
	local x, y, z = spGetUnitViewPosition(unitID)
	
	if x and y and z then
		gl.PushMatrix()
			gl.Translate(x, y + yoffset, z)
			gl.Billboard()
			gl.Translate(0, 5 ,0)
			gl.Text(etaStr, 0, 0, fontSize, "co")
		gl.PopMatrix()
	end
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() or not displayETA or (options.showonlyonshift.value and not select(4,Spring.GetModKeyState())) then
		return
	end
	gl.DepthTest(true)

	gl.Color(1, 1, 1)

	for unitID, bi in pairs(etaTable) do
		DrawEtaText(unitID, bi.timeLeft,bi.yoffset, bi.negative)
	end

	for unitID, bi in pairs(stockpileEtaTable) do
		local stocked, wanted = Spring.GetUnitStockpile(unitID)
		if (stocked < wanted) then
			DrawEtaText(unitID, bi.timeLeft, bi.yoffset, false)
		end
	end

	gl.DepthTest(false)
end
