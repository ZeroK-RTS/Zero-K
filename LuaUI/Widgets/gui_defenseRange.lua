function widget:GetInfo()
	return {
		name      = "Defense Range Zero-K",
		desc      = "[v6.2.6] Displays range of defenses (enemy and ally)",
		author    = "very_bad_soldier / versus666",
		date      = "October 21, 2007 / September 08, 2010",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

-- Technicalities

local GROUND = 1
local AIR    = 2
local ANTI   = 3
local MIXED  = 4
local SHIELD = 5
local RADAR  = 6

local CYLINDER_HEIGHTMOD = { heightMod = 0, }
local SPHERE_HEIGHTMOD = { heightMod = 1, }

-- Config

local alphaValue = 0.35
local REDRAW_TIME = 0.1 -- Time in seconds to batch redraws within

local unitConfig = {}
for unitName, conf in pairs({
	staticantinuke = {
		class = ANTI,
		color = { 1, 1, 1 },
		colorInBuild = { 0, 0.6, 0.8 },
	},
	turretemp = {
		color = {1, 0.56, 0},
		class = GROUND,
	},
	turretriot = {
		color = {1, 0.54, 0},
		class = GROUND,
	},
	turretgauss = {
		color = {1, 0, 0},
		class = GROUND,
	},
	mahlazer = {
		color = {1, 0, 0},
		class = GROUND,
	},
	turretantiheavy = {
		color = {1, 0.47, 0},
		class = GROUND,
	},
	staticheavyarty = {
		color = {1, 0.3, 0},
		class = GROUND,
	},
	tacnuke = {
		color = {1, 0.4, 0},
		class = GROUND,
	},
	turretaafar = {
		color = {0, 0.56, 0.44},
		class = AIR,
	},
	turretmissile = {
		color = {1, 0, 0},
		color2 = {0, 1, 0},
		class = MIXED,
	},
	turretlaser = {
		color = {1, 0, 0},
		class = GROUND,
	},
	turretheavylaser = {
		color = {1, 0.15, 0},
		class = GROUND,
	},
	turretheavy = {
		color = {1, 0.47, 0},
		class = GROUND,
	},
	turretaalaser = {
		color = {0, 0.8, 0.2},
		class = AIR,
	},
	turretaaflak = {
		color = {0, 0.43, 0.57},
		class = AIR,
	},
	turretaaheavy = {
		color = {0, 0, 1},
		class = AIR,
	},
	turretaaclose = {
		color = {0, 0, 1},
		class = AIR,
	},
	staticarty = {
		color = {1, 0.13, 0},
		class = GROUND,
	},
	turrettorp = {
		color = {1, 0, 0},
		class = GROUND,
	},
	turretimpulse = {
		color = {1, 0, 0},
		class = GROUND,
	},
	staticshield = {
		color = {1, 0, 1},
		class = SHIELD,
	},
	staticradar = {
		color = {0, 0.8, 0},
		lineWidth = 3,
		class = RADAR,
	},
	staticheavyradar = {
		color = {0, 0.8, 0},
		lineWidth = 3,
		class = RADAR,
	},
}) do
	local unitDef = UnitDefNames[unitName]
	local weaponDef
	if conf.class ~= RADAR then
		weaponDef = WeaponDefs[unitDef.weapons[1].weaponDef]
	end

	if conf.class == ANTI then
		conf.weaponDef = CYLINDER_HEIGHTMOD
		conf.radius = weaponDef.customParams.nuke_coverage
	elseif conf.class == RADAR then
		conf.weaponDef = CYLINDER_HEIGHTMOD
		conf.radius = unitDef.radarRadius
	elseif conf.class == SHIELD then
		conf.weaponDef = SPHERE_HEIGHTMOD
		conf.radius = weaponDef.shieldRadius
	else
		conf.weaponDef = weaponDef
		conf.radius = weaponDef.range
	end

	if not conf.lineWidth then
		conf.lineWidth = 1.0
	end

	conf.color[4] = alphaValue
	if conf.colorInBuild then
		conf.colorInBuild[4] = alphaValue
	end
	if conf.color2 then
		conf.color2[4] = alphaValue
	end

	unitConfig[unitDef.id] = conf
end

local unitDefIDRemap = {
	[UnitDefNames["staticmissilesilo"].id] = UnitDefNames["tacnuke"].id,
	[UnitDefNames["tacnuke"].id] = -1,
}

-- speedups

local GL_LINE_STRIP         = GL.LINE_STRIP
local glBeginEnd            = gl.BeginEnd
local glCallList            = gl.CallList
local glColor               = gl.Color
local glCreateList          = gl.CreateList
local glDeleteList          = gl.DeleteList
local glLineWidth           = gl.LineWidth
local glVertex              = gl.Vertex
local spGetPositionLosState = Spring.GetPositionLosState
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spIsGUIHidden 		= Spring.IsGUIHidden

local CalcBallisticCircle = VFS.Include("LuaUI/Utilities/engine_range_circles.lua")

local RedoUnitList

-- globals

local spectating = Spring.GetSpectatingState()
local myPlayerID = Spring.GetLocalPlayerID()

local defences = {}
local needRedraw = false
local defenseRangeDrawList = false

-- Chili buttonry

local checkboxes = {}
local pics = {}
local global_command_button

-- EPIC options

local Chili
options_path = 'Settings/Interface/Defense and Cloak Ranges'

local function OnOptChange(self)
	local cb = checkboxes[self.key]
	if cb then
		cb.checked = self.value
		cb.state.checked = self.value
		cb:Invalidate()
	end
	RedoUnitList()
end

options = {
	label = { type = 'label', name = 'Defense Ranges' },
	allyground = {
		name = 'Show Ally Ground Defence',
		type = 'bool',
		value = false,
	},
	allyair = {
		name = 'Show Ally Air Defence',
		type = 'bool',
		value = false,
	},
	allynuke = {
		name = 'Show Ally Nuke Defence',
		type = 'bool',
		value = true,
	},
	enemyground = {
		name = 'Show Enemy Ground Defence',
		type = 'bool',
		value = true,
	},
	enemyair = {
		name = 'Show Enemy Air Defence',
		type = 'bool',
		value = true,
	},
	enemynuke = {
		name = 'Show Enemy Nuke Defence',
		type = 'bool',
		value = true,
	},
	enemyshield = {
		name = 'Show Enemy Shields',
		type = 'bool',
		value = true,
	},
	enemyradar = {
		name = 'Show Enemy Radar Coverage',
		type = 'bool',
		value = false,
	},
	specground = {
		name = 'Show Ground Defence as Spectator',
		type = 'bool',
		value = false,
	},
	specair = {
		name = 'Show Air Defence as Spectator',
		type = 'bool',
		value = false,
	},
	specnuke = {
		name = 'Show Nuke Defence as Spectator',
		type = 'bool',
		value = true,
	},
}
for name, opt in pairs(options) do
	if name ~= 'label' then
		opt.OnChange = OnOptChange
	end
end

options_order = {
	'label',
	'allyground',
	'allyair',
	'allynuke',
	'enemyground',
	'enemyair',
	'enemynuke',
	'enemyshield',
	'specground',
	'specair',
	'specnuke',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function BuildVertexList(verts)
	local count = #verts
	for i = 1, count do
		glVertex(verts[i])
	end
	glVertex(verts[1])
end

local function CreateDrawList(isAlly, configData, inBuild, x, y, z)
	local color = inBuild and configData.colorInBuild or configData.color

	glLineWidth(configData.lineWidth)
	glColor(color)
	glBeginEnd(GL_LINE_STRIP, BuildVertexList, CalcBallisticCircle(x,y,z, configData.radius, configData.weaponDef))

	if configData.color2 then
		glColor(configData.color2)
		glBeginEnd(GL_LINE_STRIP, BuildVertexList, CalcBallisticCircle(x,y,z, configData.radius + 3, configData.weaponDef))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitDetected(unitID, unitDefID, isAlly)
	if not unitDefID then
		return
	end

	if unitDefIDRemap[unitDefID] then
		unitDefID = unitDefIDRemap[unitDefID]
		if unitDefID == -1 then
			return
		end
	end

	local configData = unitConfig[unitDefID]
	if not configData then
		return
	end

	local inBuild = select(3, Spring.GetUnitIsStunned(unitID))

	local defenceData = defences[unitID]
	if defenceData then
		if not configData.colorInBuild or inBuild == defenceData.isBuild then
			return
		end
	end

	local x, y, z = spGetUnitPosition(unitID)
	defences[unitID] = {
		drawList = glCreateList(CreateDrawList, isAlly, configData, inBuild, x, y, z),
		x = x, y = y, z = z,
		inBuild = inBuild,
		isAlly = isAlly,
		checkCompleteness = (not isAlly) and inBuild and configData.colorInBuild and true,
		unitDefID = unitDefID,
	}
	needRedraw = needRedraw or REDRAW_TIME
end

RedoUnitList = function()

	for _, def in pairs(unitConfig) do
		if def.class == GROUND then
			def.wantedAlly = options.allyground.value
			def.wantedEnemy = options.enemyground.value
			def.wantedSpec = options.specground.value
		elseif def.class == AIR then
			def.wantedAlly = options.allyair.value
			def.wantedEnemy = options.enemyair.value
			def.wantedSpec = options.specair.value
		elseif def.class == MIXED then
			def.wantedAlly = options.allyground.value or options.allyair.value
			def.wantedEnemy = options.enemyground.value or options.enemyair.value
			def.wantedSpec = options.specground.value or options.specair.value
		elseif def.class == ANTI then
			def.wantedAlly = options.allynuke.value
			def.wantedEnemy = options.enemynuke.value
			def.wantedSpec = options.specnuke.value
		elseif def.class == RADAR then
			def.wantedAlly = false
			def.wantedEnemy = options.enemyradar.value
			def.wantedSpec = false
		elseif def.class == SHIELD then
			def.wantedAlly = false
			def.wantedEnemy = options.enemyshield.value
			def.wantedSpec = false
		end
	end

	needRedraw = needRedraw or REDRAW_TIME
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	UnitDetected(unitID, unitDefID, true)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	UnitDetected(unitID, unitDefID, true)
end

function widget:UnitGiven(unitID, unitDefID)
	widget:UnitDestroyed(unitID, unitDefID)
	widget:UnitCreated(unitID, unitDefID)
end

function widget:UnitTaken(unitID, unitDefID)
	widget:UnitDestroyed(unitID, unitDefID)
	widget:UnitCreated(unitID, unitDefID)
end

function widget:UnitDestroyed(unitID)
	local def = defences[unitID]
	if not def then
		return
	end

	glDeleteList(def.drawList)
	defences[unitID] = nil
	needRedraw = needRedraw or REDRAW_TIME
end

function widget:UnitEnteredLos(unitID, unitTeam)
	UnitDetected(unitID, Spring.GetUnitDefID(unitID), false)
end

local function RedrawDrawRanges()
	for _, def in pairs(defences) do
		local configData = unitConfig[def.unitDefID]
		if spectating and configData.wantedSpec
		or not spectating and ((def.isAlly and configData.wantedAlly) or (not def.isAlly and configData.wantedEnemy))
		then
			glCallList(def.drawList)
		end
	end
end

function widget:Update(dt)
	if needRedraw then
		needRedraw = needRedraw - dt
		if needRedraw < 0 then
			if defenseRangeDrawList then
				gl.DeleteList(defenseRangeDrawList)
			end
			defenseRangeDrawList = glCreateList(RedrawDrawRanges)
			needRedraw = false
		end
	end
end

function widget:GameFrame(n)
	if (n % 30) ~= 0 then
		return
	end

	for unitID, def in pairs(defences) do
		local unitDefID = spGetUnitDefID(unitID)
		if unitDefID then
			if defences[unitID].checkCompleteness then
				-- Not allied because this check is only required for enemies.
				-- Allied units are detected in UnitFinished.
				UnitDetected(unitID, unitDefID, false)
			end
		elseif select(2, spGetPositionLosState(def.x, def.y, def.z)) then
			glDeleteList(def.drawList)
			defences[unitID] = nil
			needRedraw = needRedraw or REDRAW_TIME
		end
	end
end

function widget:PlayerChanged(playerID)
	if myPlayerID ~= playerID then
		return
	end

	local newSpectating = Spring.GetSpectatingState()
	if spectating ~= newSpectating then
		spectating = newSpectating
		needRedraw = needRedraw or REDRAW_TIME
	end
end

function widget:DrawWorldPreUnit()
	if spIsGUIHidden() then
		return
	end

	if defenseRangeDrawList then
		glCallList(defenseRangeDrawList)
	end
	glColor(1, 1, 1, 1)
	glLineWidth(1.0)
end

local function SetupChiliStuff()
	local Chili = WG.Chili
	local Window = Chili.Window
	local Image = Chili.Image

	local mainWindow = WG.Chili.Window:New{
		classname = "main_window_small_tall",
		name      = 'DefenseRangesWindow',
		x         =  50,
		y         = 150,
		width     = 120,
		height    = 168,
		padding = {12, 12, 12, 12},
		dockable  = true,
		dockableSavePositionOnly = true,
		draggable = true,
		resizable = false,
		tweakResizable = false,
		parent = WG.Chili.Screen0,
	}

	pics.ground = WG.Chili.Image:New { x = 0, y = 24*1, file = 'LuaUI/Images/defense_ranges/ground.png' }
	pics.air    = WG.Chili.Image:New { x = 0, y = 24*2, file = 'LuaUI/Images/defense_ranges/air.png'    }
	pics.nuke   = WG.Chili.Image:New { x = 0, y = 24*3, file = 'LuaUI/Images/defense_ranges/nuke.png'   }
	pics.shield = WG.Chili.Image:New { x = 0, y = 24*4, file = 'LuaUI/Images/defense_ranges/shield.png' }
	pics.radar  = WG.Chili.Image:New { x = 0, y = 24*5, file = 'LuaUI/Images/defense_ranges/radar.png'  }

	pics.ally  = WG.Chili.Image:New { x = 24*1, y = 0, file = 'LuaUI/Images/defense_ranges/defense_ally.png'  }
	pics.enemy = WG.Chili.Image:New { x = 24*2, y = 0, file = 'LuaUI/Images/defense_ranges/defense_enemy.png' }
	pics.spec  = WG.Chili.Image:New { x = 24*3, y = 0, file = 'LuaUI/Images/dynamic_comm_menu/eye.png'        }

	for key, pic in pairs(pics) do
		pic.width = 24
		pic.height = 24
		mainWindow:AddChild(pic)
	end

	checkboxes.allyground  = WG.Chili.Checkbox:New { x = 26, y = 28, }
	checkboxes.enemyground = WG.Chili.Checkbox:New { x = 50, y = 28, }
	checkboxes.specground  = WG.Chili.Checkbox:New { x = 74, y = 28, }
	checkboxes.allyair     = WG.Chili.Checkbox:New { x = 26, y = 52, }
	checkboxes.enemyair    = WG.Chili.Checkbox:New { x = 50, y = 52, }
	checkboxes.specair     = WG.Chili.Checkbox:New { x = 74, y = 52, }
	checkboxes.allynuke    = WG.Chili.Checkbox:New { x = 26, y = 76, }
	checkboxes.enemynuke   = WG.Chili.Checkbox:New { x = 50, y = 76, }
	checkboxes.specnuke    = WG.Chili.Checkbox:New { x = 74, y = 76, }
	-- no allyshield
	checkboxes.enemyshield = WG.Chili.Checkbox:New { x = 50, y = 100, }
	-- no specshield
	-- no allyradar
	checkboxes.enemyradar  = WG.Chili.Checkbox:New { x = 50, y = 124, }
	-- no specradar

	local function OnCheckboxChangeFunc(self)
		-- called *before* the 'checked' value is swapped, hence negation everywhere
		local opt = options[self.key]
		local er = opt.epic_reference
		if er then
			er.checked = not self.checked
			er.state.checked = not self.checked
			er:Invalidate()
		end
		opt.value = not self.checked
		RedoUnitList()
	end
	local OnCheckboxChange = { OnCheckboxChangeFunc }

	for key, checkbox in pairs(checkboxes) do
		local opt = options[key]
		checkbox.width = 16
		checkbox.key = key
		checkbox.checked = opt.value
		checkbox.state.checked = checkbox.checked
		checkbox.tooltip = opt.name
		checkbox.caption = ""
		checkbox.OnChange = OnCheckboxChange
		checkbox:Invalidate()
		mainWindow:AddChild(checkbox)
	end

	mainWindow:SetVisibility(false)
	if WG.GlobalCommandBar then
		local function ToggleWindow()
			if mainWindow then
				mainWindow:SetVisibility(not mainWindow.visible)
			end
		end
		global_command_button = WG.GlobalCommandBar.AddCommand("LuaUI/Images/defense_ranges/defense_colors.png", "Defense Ranges", ToggleWindow)
	end
end

function widget:Initialize()
	SetupChiliStuff()

	RedoUnitList()

	local myAllyTeam = Spring.GetMyAllyTeamID()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		local unitAllyTeam = Spring.GetUnitAllyTeam(unitID)
		UnitDetected(unitID, Spring.GetUnitDefID(unitID), unitAllyTeam == myAllyTeam)
	end
end
