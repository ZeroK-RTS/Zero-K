function widget:GetInfo()
	return {
		name = "Battle Resource Tracker",
		desc = "Shows the resource gains/losses in battles",
		author = "citrine",
		date = "2023",
		license = "GNU GPL, v2 or later",
		version = 7,
		layer = -100,
		enabled = false
	}
end

local BASE_FONT_SIZE = 64
local font = gl.LoadFont('FreeSansBold.otf', BASE_FONT_SIZE, 8, 6)

local hpcolormap = { {0.9, 0.1, 0.1, 0.8},  {0.8, 0.6, 0.0, 0.8}, {0.1, 0.90, 0.1, 0.8} }
function GetColor(colormap, slider)
	local coln = #colormap
	if (slider >= 1) then
		local col = colormap[coln]
		return {col[1], col[2], col[3], col[4]}
	end
	if (slider < 0) then slider = 0 elseif(slider > 1) then
		slider = 1
	end
	local posn  = 1+(coln-1) * slider
	local iposn = math.floor(posn)
	local aa    = posn - iposn
	local ia    = 1-aa

	local col1, col2 = colormap[iposn], colormap[iposn+1]

	return {col1[1]*ia + col2[1]*aa, col1[2]*ia + col2[2]*aa,
	       col1[3]*ia + col2[3]*aa, col1[4]*ia + col2[4]*aa}
end



local config = {
	-- user configuration
	-- =============

	-- the maximum distance at which battles can be combined
	searchRadius = 600,

	-- how long battles stay visible if they haven't changed (in seconds)
	eventTimeout = 20,

	-- font size for battle text
	fontSize = 38,

	-- maximum alpha value for resource delta text (0-1, 1=opaque, 0=transparent)
	maxTextAlpha = 0.8,

	-- distance to swap between drawing text under units, and above units/icons
	cameraThreshold = 0,

	-- what drawing mode to use depending on camera distance
	-- "PreDecals", "WorldPreUnit", "World", "ScreenEffects", or nil
	nearCameraMode = "WorldPreUnit",
	farCameraMode = "ScreenEffects",

	-- what resources to display, and how to combine them
	-- "metal", "energy", "both" (show m and e separately), "combined" (convert e to m and combine)
	resourceMode = "metal",

	-- advanced configuration
	-- ======================

	-- RGB text color that indicates a positive resource delta (your opponents lost resources)
	positiveTextColor = { 0.3, 1, 0.3 },

	-- RGB text color that indicates a negative resource delta (your allyteam lost resources)
	negativeTextColor = { 1, 0.3, 0.3 },

	-- the size of the cells that the map is divided into (for performance optimization)
	spatialHashCellSize = 500,

	-- how often to check and remove old events (for performance optimization)
	eventTimeoutCheckPeriod = 30 * 1,

	-- how distance affects font size when drawing using DrawScreenEffects
	distanceScaleFactor = 1800,

	-- how much to increase the size of the text as you zoom out
	farCameraTextBoost = 0.8,

	-- method used to draw text ("gl" or "lua")
	textMode = "gl",

	-- energy per metal ratio for combining metal and energy values
	conversionRatio = 70,
}

-- engine call optimizations
-- =========================

local SpringGetCameraState = Spring.GetCameraState
local SpringGetGameFrame = Spring.GetGameFrame
local SpringGetGroundHeight = Spring.GetGroundHeight
local SpringGetMyTeamID = Spring.GetMyTeamID
local SpringGetTeamAllyTeamID = Spring.GetTeamAllyTeamID
local SpringGetUnitHealth = Spring.GetUnitHealth
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringIsGUIHidden = Spring.IsGUIHidden
local SpringWorldToScreenCoords = Spring.WorldToScreenCoords
local SpringIsSphereInView = Spring.IsSphereInView
local SpringGetCameraRotation = Spring.GetCameraRotation
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glRotate = gl.Rotate
local glColor = gl.Color
local glText = gl.Text

local mathPi = math.pi
local mathFloor = math.floor
local mathRound = math.round
local mathSqrt = math.sqrt
local mathMin = math.min
local mathMax = math.max

-- spatial hash implementation
-- ===========================

local SpatialHash = {}
SpatialHash.__index = SpatialHash

function SpatialHash.new(cellSize)
	local self = setmetatable({}, SpatialHash)
	self.cellSize = cellSize
	self.cells = {}
	return self
end

function SpatialHash:hashKey(x, z)
	return string.format("%d,%d", mathFloor(x / self.cellSize), mathFloor(z / self.cellSize))
end

function SpatialHash:addEvent(event)
	local key = self:hashKey(event.x, event.z)
	local cell = self.cells[key]
	if not cell then
		cell = {}
		self.cells[key] = cell
	end
	table.insert(cell, event)
end

function SpatialHash:removeEvent(event)
	local key = self:hashKey(event.x, event.z)
	local cell = self.cells[key]
	if cell then
		for i, storedEvent in ipairs(cell) do
			if storedEvent == event then
				table.remove(cell, i)
				break
			end
		end
	end
end

function SpatialHash:allEvents(filterFunc)
	local events = {}
	for _, cell in pairs(self.cells) do
		for _, event in ipairs(cell) do
			if not filterFunc or filterFunc(event) then
				table.insert(events, event)
			end
		end
	end
	return events
end

function SpatialHash:getNearbyEvents(x, z, radius)
	local nearbyEvents = {}
	local startX = mathFloor((x - radius) / self.cellSize)
	local startZ = mathFloor((z - radius) / self.cellSize)
	local endX = mathFloor((x + radius) / self.cellSize)
	local endZ = mathFloor((z + radius) / self.cellSize)

	for i = startX, endX do
		for j = startZ, endZ do
			local key = self:hashKey(i * self.cellSize, j * self.cellSize)
			local cell = self.cells[key]
			if cell then
				for _, event in ipairs(cell) do
					local distance = mathSqrt((event.x - x) ^ 2 + (event.z - z) ^ 2)
					if distance <= radius then
					  table.insert(nearbyEvents, event)
					end
				end
			end
		end
	end

	return nearbyEvents
end

-- widget code
-- ===========

local spatialHash = SpatialHash.new(config.spatialHashCellSize)
local drawLocation = nil
local isGameStarted = false
local ignoreUnitDestroyed = {}

local function combineEvents(events)
	-- Calculate the average position (weighted by number of events)
	local totalSubEvents = 0
	local averageX, averageZ = 0, 0
	for _, event in ipairs(events) do
		averageX = averageX + (event.x * event.n)
		averageZ = averageZ + (event.z * event.n)
		totalSubEvents = totalSubEvents + event.n
	end
	averageX = averageX / totalSubEvents
	averageZ = averageZ / totalSubEvents

	-- Sum team metal values
	local totalMetal = {}
	local totalEnergy = {}
	for _, event in ipairs(events) do
		for key, value in pairs(event.metal) do
			totalMetal[key] = (totalMetal[key] or 0) + value
		end

		for key, value in pairs(event.energy) do
			totalEnergy[key] = (totalEnergy[key] or 0) + value
		end
	end

	-- Calculate max game time (most recent event)
	local maxT = 0
	for _, event in ipairs(events) do
		maxT = mathMax(event.t, maxT)
	end

	-- Create the combined event
	local combinedEvent = {
		x = averageX,
		z = averageZ,
		metal = totalMetal,
		energy = totalEnergy,
		t = maxT,
		n = totalSubEvents
	}

	return combinedEvent
end

local function scaleText(size, distance)
	return size * config.distanceScaleFactor / distance
end

local function getCameraDistance()
	local cameraState = SpringGetCameraState()
	return cameraState.height or cameraState.dist or cameraState.py or (config.cameraThreshold - 1)
end

local function getDrawLocation()
	if SpringIsGUIHidden() then
		return nil
	end

	local dist = getCameraDistance()
	if dist < config.cameraThreshold then
		return config.nearCameraMode
	else
		return config.farCameraMode
	end
end


local function stripColorCodes(str)
	str = str:gsub("\254........", "")
	str = str:gsub("\255...", "")
	return str
end

local SI_PREFIXES_LOG1K = {
	[10] = "Q",
	[9] = "R",
	[8] = "Y",
	[7] = "Z",
	[6] = "E",
	[5] = "P",
	[4] = "T",
	[3] = "G",
	[2] = "M",
	[1] = "k",
	[0] = "",
	[-1] = "m",
	[-2] = "μ",
	[-3] = "n",
	[-4] = "p",
	[-5] = "f",
	[-6] = "a",
	[-7] = "z",
	[-8] = "y",
	[-9] = "r",
	[-10] = "q",
}

local function toEngineeringNotation(number)
	number = tonumber(number)
	if number == 0 or not number then
		return "0"
	end

	local sign = 1
	if number < 0 then
		number = number * -1
		sign = -1
	end

	local log1k = math.floor(math.log(number) / math.log(1000))
	local prefix = SI_PREFIXES_LOG1K[log1k]
	if prefix == nil then
		return nil
	end

	number = number / math.pow(1000, log1k)
	local precision = 2 - math.floor(math.log10(number))
	local str = string.format("%." .. precision .. "f", sign * number)

	if string.find(str, "%.") ~= nil then
		local i = string.len(str)
		while i > 0 do
			local c = string.sub(str, i, i)
			if c == "0" then
				i = i - 1
			elseif c == "." then
				i = i - 1
				break
			else
				break
			end
		end
		str = string.sub(str, 1, i)
	end

	return str .. prefix
end

local function toRoundedNotation(number)
	number = tonumber(number)
	if number == 0 or not number then
		return "0"
	end
	local sign = 1
	if number < 0 then
		number = number * -1
		sign = -1
	end
	local digits = math.floor(math.log(number) / math.log(10))
	number = math.pow(10, digits - 1) * math.round(number / (math.pow(10, digits - 1)))
	return number * sign
end

local function deltaText(killed, lost)
	if killed == 0 then
		return toRoundedNotation(mathRound(lost)), GetColor(hpcolormap, 0)
	end
	if lost == 0 then
		return toRoundedNotation(mathRound(killed)), GetColor(hpcolormap, 1)
	end
	local str = toRoundedNotation(mathRound(killed)) .. "" .. toRoundedNotation(mathRound(lost))
	return str, GetColor(hpcolormap, killed / (killed - lost))
end

local function drawText(text, fontSize, color, alpha)
	gl.Scale(fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE)
	font:Begin()
		font:SetTextColor(color[1], color[2], color[3], color[4] * alpha)
		font:SetOutlineColor(0, 0, 0, alpha)
		font:Print(text, 0, 0, BASE_FONT_SIZE, "cov")
	font:End()
end

local function DrawBattleText()
	if not isGameStarted then
		return
	end

	local cameraState = SpringGetCameraState()
	local events = spatialHash:allEvents()
	local currentFrame = SpringGetGameFrame()

	local myTeamID = SpringGetMyTeamID()
	local myAllyTeamID = SpringGetTeamAllyTeamID(myTeamID)

	local currentFontSize = config.fontSize
	--if drawLocation == "ScreenEffects" then
	--	local cameraDistance = getCameraDistance()
	--	local boostSize = mathMax(0, cameraDistance - config.cameraThreshold) * config.farCameraTextBoost
	--	currentFontSize = scaleText(currentFontSize, cameraDistance - boostSize)
	--end

	for _, event in ipairs(events) do
		local ex, ey, ez = event.x, math.max(0, SpringGetGroundHeight(event.x, event.z)) + 30, event.z
		if SpringIsSphereInView(ex, ey, ez, 300) then
			-- generate text for the event
			local eventAge = (currentFrame - event.t) / (config.eventTimeout * 30) -- fraction of total lifetime left
			local alpha = config.maxTextAlpha * (1 - mathMin(1, eventAge * eventAge * eventAge * eventAge)) -- fade faster as it gets older

			local metalKilled = 0
			local metalLost = 0
			for key, value in pairs(event.metal) do
				-- show my allyteam metal lost as negative and any other allyteam as positive
				if key == myAllyTeamID then
					metalLost = metalLost - value
				else
					metalKilled = metalKilled + value
				end
			end

			local metalDeltaText, deltaColor = deltaText(metalKilled, metalLost)

			-- draw the text
			glPushMatrix()

			if drawLocation == "ScreenEffects" then
				glTranslate(SpringWorldToScreenCoords(ex, ey, ez))
			else
				glTranslate(ex, ey, ez)

				glRotate(-90, 1, 0, 0)
				if cameraState.flipped == 1 then
					-- only applicable in ta camera
					glRotate(180, 0, 0, 1)
				elseif cameraState.mode == 2 then
					-- spring camera
					local rx, ry, rz = SpringGetCameraRotation()
					glRotate(-180 * ry / mathPi, 0, 0, 1)
				end
			end

			drawText(metalDeltaText, currentFontSize, deltaColor, alpha)
			glPopMatrix()
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if ignoreUnitDestroyed[unitID] then
		ignoreUnitDestroyed[unitID] = nil
		return
	end

	local ud = UnitDefs[unitDefID]
	if ud.customParams.dontcount then
		return
	end

	local _, _, _, _, buildProgress = SpringGetUnitHealth(unitID)
	local allyTeamID = SpringGetTeamAllyTeamID(unitTeam)
	local x, y, z = SpringGetUnitPosition(unitID)
	local gameTime = SpringGetGameFrame()

	local metal = ud.metalCost * buildProgress
	local energy = ud.energyCost * buildProgress
	

	if metal < 1 and energy < 1 then
		return
	end

	local event = {
		x = x, -- x coordinate of the event
		z = z, -- z coordinate of the event
		t = gameTime, -- game time (in frames) when the event happened
		metal = { -- the metal lost in the event, by allyteam that lost the metal
			[allyTeamID] = metal
		},
		energy = { -- the metal lost in the event, by allyteam that lost the metal
			[allyTeamID] = energy
		},
		n = 1 -- how many events have been combined into this one
	}

	-- combine with nearby events if necessary
	local nearbyEvents = spatialHash:getNearbyEvents(x, z, config.searchRadius)
	local combinedEvent = event
	if #nearbyEvents > 0 then
		table.insert(nearbyEvents, event)
		combinedEvent = combineEvents(nearbyEvents)

		for _, nearbyEvent in ipairs(nearbyEvents) do
			spatialHash:removeEvent(nearbyEvent)
		end
	end

	spatialHash:addEvent(combinedEvent)
end

function widget:GameFrame(frame)
	if not isGameStarted then
		isGameStarted = true
	end

	if frame % config.eventTimeoutCheckPeriod == 0 then
		local oldEvents = spatialHash:allEvents(
			function(event)
				return event.t < frame - (config.eventTimeout * 30)
			end
		)

		for _, event in ipairs(oldEvents) do
			spatialHash:removeEvent(event)
		end
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if UnitDefs[unitDefID].canFly and Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing" then
		local ud = UnitDefs[unitDefID]
		if ud.customParams.dontcount then
			return
		end
		widget:UnitDestroyed(unitID, unitDefID, unitTeam, nil, nil, nil)
		ignoreUnitDestroyed[unitID] = true
	end
end

function widget:Update(dt)
	drawLocation = getDrawLocation()
end

local DRAW_MODES = { "PreDecals", "WorldPreUnit", "World", "ScreenEffects", "None" }
local RESOURCE_MODES = { "metal", "energy", "both", "combined" }

local OPTIONS = {
	{
		configVariable = "searchRadius",
		name = "Search Radius",
		description = "Maximum distance at which battles can be combined",
		type = "slider",
		min = 100,
		max = 2000,
		step = 50,
	},
	{
		configVariable = "eventTimeout",
		name = "Event Timeout",
		description = "How long battles stay visible if they haven't changed (seconds)",
		type = "slider",
		min = 5,
		max = 120,
		step = 5,
	},
	{
		configVariable = "fontSize",
		name = "Text Size",
		description = "Font size for battle text",
		type = "slider",
		min = 10,
		max = 200,
		step = 5,
	},
	{
		configVariable = "maxTextAlpha",
		name = "Text Opacity",
		description = "Initial opacity for battle text (text starts at this opacity, and fades over time if it remains unchanged)",
		type = "slider",
		min = 0.1,
		max = 1,
		step = 0.1,
	},
	{
		configVariable = "cameraThreshold",
		name = "Camera Threshold",
		description = "Distance to swap between drawing modes (typically under units and above units/icons)",
		type = "slider",
		min = 500,
		max = 5000,
		step = 100,
	},
	{
		configVariable = "nearCameraMode",
		name = "Near Camera Mode",
		description = "How to draw text when the camera is close to the ground",
		type = "select",
		options = DRAW_MODES,
	},
	{
		configVariable = "farCameraMode",
		name = "Far Camera Mode",
		description = "How to draw text when the camera is far away from the ground",
		type = "select",
		options = DRAW_MODES,
	},
	{
		configVariable = "resourceMode",
		name = "Resource Mode",
		description = "How to display each resource",
		type = "select",
		options = RESOURCE_MODES,
	}
}

local function createOnChange(option)
	return function(i, value, force)
		setOptionValue(option, value)
	end
end

local function getOptionId(option)
	return "battle_resource_tracker__" .. option.configVariable
end

local function getWidgetName()
	return "Battle Resource Tracker"
end

local function getOptionValue(option)
	if option.type == "slider" then
		return config[option.configVariable]
	elseif option.type == "select" then
		-- we have text, we need index
		for i, v in ipairs(option.options) do
			if config[option.configVariable] == v then
				return i
			end
		end
	end
end

function setOptionValue(option, value)
	if option.type == "slider" then
		config[option.configVariable] = value
	elseif option.type == "select" then
		-- we have index, we need text
		config[option.configVariable] = option.options[value]
	end
end

function widget:Initialize()
	for _, option in ipairs(OPTIONS) do
		local tempOption = Spring.Utilities.CopyTable(option)
		tempOption.configVariable = nil
		tempOption.id = getOptionId(option)
		tempOption.widgetname = getWidgetName()
		tempOption.value = getOptionValue(option)
		tempOption.onchange = createOnChange(option)
	end
end


-- draw functions

function widget:DrawPreDecals()
	if drawLocation == "PreDecals" then
		DrawBattleText()
	end
end

function widget:DrawWorldPreUnit()
	if drawLocation == "WorldPreUnit" then
		DrawBattleText()
	end
end

function widget:DrawWorld()
	if drawLocation == "World" then
		DrawBattleText()
	end
end

function widget:DrawScreenEffects()
	if drawLocation == "ScreenEffects" then
		DrawBattleText()
	end
end
