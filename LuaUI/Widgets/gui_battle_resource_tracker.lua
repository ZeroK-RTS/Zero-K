function widget:GetInfo()
	return {
		name = "Battle Resource Tracker",
		desc = "Shows the resource gains/losses in battles",
		author = "citrine",
		date = "2023",
		license = "GNU GPL, v2 or later",
		version = 7,
		layer = -100,
		enabled = true
	}
end

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

local config = {
	-- user configuration
	-- =============

	-- distance to swap between drawing text under units, and above units/icons
	cameraThreshold = 0,

	-- what drawing mode to use depending on camera distance
	-- "PreDecals", "WorldPreUnit", "World", "ScreenEffects", or nil
	nearCameraMode = "WorldPreUnit",
	farCameraMode = "ScreenEffects",

	-- advanced configuration
	-- ======================

	-- the size of the cells that the map is divided into (for performance optimization)
	spatialHashCellSize = 500,

	-- how often to check and remove old events (for performance optimization)
	eventTimeoutCheckPeriod = 30 * 1,

	-- how distance affects font size when drawing using DrawScreenEffects
	distanceScaleFactor = 1800,

	-- how much to increase the size of the text as you zoom out
	farCameraTextBoost = 0.8,
}

local BASE_FONT_SIZE = 64
local font = gl.LoadFont('FreeSansBold.otf', BASE_FONT_SIZE, 8, 6)

local spatialHash = SpatialHash.new(config.spatialHashCellSize)
local drawLocation = nil
local isGameStarted = false
local ignoreUnitDestroyed = {}


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


local hpcolormap = { {0.9, 0.1, 0.1, 1},  {0.8, 0.6, 0.0, 1}, {0.1, 0.90, 0.1, 1} }
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


options_path = 'Settings/Interface/Battle Value Tracker'
options_order = { 'showText', 'clearEvents', 'searchRadius', 'eventTimeout', 'fontSize', 'textAlpha' }
options = {
	showText = {
		name = 'Show text',
		desc = 'Whether to show text. Use this to toggle the text while keeping tracking active.',
		type = 'bool',
		value = true,
	},
	clearEvents = {
		name = "Clear data",
		desc = "Forget previous events. Hotkey this button.",
		type = 'button',
		OnChange = function(self)
			spatialHash = SpatialHash.new(config.spatialHashCellSize)
		end,
	},
	searchRadius = {
		name = 'Battle radius (elmos)',
		desc = 'The size of an individual battle. Lower radius detects more distinct battles.',
		type = 'number',
		value = 600,
		min = 200,
		max = 1600,
		step = 50,
	},
	eventTimeout = {
		name = 'Battle time (seconds)',
		desc = 'How long a battle persists until it fades. New kills refresh battle time.',
		type = 'number',
		value = 16,
		min = 2,
		max = 60,
		step = 1,
	},
	fontSize = {
		name = 'Font size',
		type = 'number',
		value = 30,
		min = 10,
		max = 80,
		step = 1,
	},
	textAlpha = {
		name = 'Font opacity',
		type = 'number',
		value = 0.7,
		min = 0.01,
		max = 1,
		step = 0.01,
	}
}

-- widget code
-- ===========

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
	for _, event in ipairs(events) do
		for key, value in pairs(event.metal) do
			totalMetal[key] = (totalMetal[key] or 0) + value
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

local function toRoundedNotation(number, alwaysSign)
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
	number = sign * math.pow(10, digits - 1) * math.round(number / (math.pow(10, digits - 1)))
	if math.abs(number) >= 10000 then
		number = math.round(number / 1000) .. "k"
	end
	if alwaysSign and sign == 1 then
		return "+" .. number
	end
	return number
end

local function deltaText(killed, lost)
	if killed == 0 then
		if lost == 0 then
			return false
		end
		return toRoundedNotation(lost, true), GetColor(hpcolormap, 0)
	end
	if lost == 0 then
		return toRoundedNotation(killed), GetColor(hpcolormap, 1)
	end
	local str = toRoundedNotation(killed) .. "" .. toRoundedNotation(lost, true)
	return str, GetColor(hpcolormap, killed / (killed - lost))
end

local function drawText(text, fontSize, color, alpha)
	gl.Scale(fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE)
	font:Begin()
		font:SetTextColor(color[1], color[2], color[3], alpha)
		font:SetOutlineColor(0, 0, 0, alpha)
		font:Print(text, 0, 0, BASE_FONT_SIZE, "cov")
	font:End()
end

local function DrawBattleText()
	if not isGameStarted then
		return
	end
	if not options.showText.value then
		return
	end

	local cameraState = SpringGetCameraState()
	local events = spatialHash:allEvents()
	local currentFrame = SpringGetGameFrame()

	local myTeamID = SpringGetMyTeamID()
	local myAllyTeamID = SpringGetTeamAllyTeamID(myTeamID)

	local currentFontSize = options.fontSize.value
	--if drawLocation == "ScreenEffects" then
	--	local cameraDistance = getCameraDistance()
	--	local boostSize = mathMax(0, cameraDistance - config.cameraThreshold) * config.farCameraTextBoost
	--	currentFontSize = scaleText(currentFontSize, cameraDistance - boostSize)
	--end

	for _, event in ipairs(events) do
		local ex, ey, ez = event.x, math.max(0, SpringGetGroundHeight(event.x, event.z)) + 30, event.z
		if SpringIsSphereInView(ex, ey, ez, 300) then
			-- generate text for the event
			local eventAge = (currentFrame - event.t) / (options.eventTimeout.value * 30) -- fraction of total lifetime left
			local alpha = options.textAlpha.value * (1 - mathMin(1, eventAge * eventAge * eventAge * eventAge * eventAge)) -- fade faster as it gets older

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

			if metalDeltaText then
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
end

local function AddDestroyEvent(unitID, unitDefID, unitTeam, costMult)
	local ud = UnitDefs[unitDefID]
	if ud.customParams.dontcount then
		return
	end
	local _, _, _, _, buildProgress = SpringGetUnitHealth(unitID)
	local allyTeamID = SpringGetTeamAllyTeamID(unitTeam)
	local x, y, z = SpringGetUnitPosition(unitID)
	local gameTime = SpringGetGameFrame()

	local metal = Spring.Utilities.GetUnitCost(unitID, unitDefID) * buildProgress

	if metal < 1 then
		return
	end
	metal = metal * (costMult or 1)

	local event = {
		x = x, -- x coordinate of the event
		z = z, -- z coordinate of the event
		t = gameTime, -- game time (in frames) when the event happened
		metal = { -- the metal lost in the event, by allyteam that lost the metal
			[allyTeamID] = metal
		},
		n = 1 -- how many events have been combined into this one
	}

	-- combine with nearby events if necessary
	local nearbyEvents = spatialHash:getNearbyEvents(x, z, options.searchRadius.value)
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

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if ignoreUnitDestroyed[unitID] then
		ignoreUnitDestroyed[unitID] = nil
		return
	end
	if Spring.GetUnitRulesParam(unitID, "wasMorphedTo") then
		return
	end
	AddDestroyEvent(unitID, unitDefID, unitTeam)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if Spring.AreTeamsAllied(unitTeam, oldTeam) then
		return
	end
	AddDestroyEvent(unitID, unitDefID, oldTeam)
	AddDestroyEvent(unitID, unitDefID, unitTeam, -1)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	if Spring.AreTeamsAllied(unitTeam, newTeam) then
		return
	end
	local currentspec, currentfullview = Spring.GetSpectatingState()
	if currentfullview then
		return -- Both UnitGiven and UnitTaken are called for fullview spectators
	end
	AddDestroyEvent(unitID, unitDefID, unitTeam)
	AddDestroyEvent(unitID, unitDefID, newTeam, -1)
end

function widget:GameFrame(frame)
	if not isGameStarted then
		isGameStarted = true
	end

	if frame % config.eventTimeoutCheckPeriod == 0 then
		local oldEvents = spatialHash:allEvents(
			function(event)
				return event.t < frame - (options.eventTimeout.value * 30)
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
