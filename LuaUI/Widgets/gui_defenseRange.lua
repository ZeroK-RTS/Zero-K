function widget:GetInfo()
	return {
		name      = "Defense Range Zero-K",
		desc      = "Displays range of defenses (enemy and ally)",
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
		lineWidth = 2,
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
local gl = gl
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
local defenseRangeDrawList

-- Chili buttonry

local checkboxes = {}
local pics = {}
local global_command_button

-- EPIC options

options_path = 'Settings/Interface/Defence and Cloak Ranges'

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
	label = { type = 'label', name = 'Defence Ranges' },
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

local function CreateDrawList(configData, inBuild, x, y, z)
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

local defNeedingLosChecks = {}
local defNeedingBuildingChecks = {}

local function RemoveUnit(unitID)
	defNeedingLosChecks[unitID] = nil
	defNeedingBuildingChecks[unitID] = nil
	local def = defences[unitID]
	if not def then return end
	glDeleteList(def.drawList)
	defences[unitID] = nil
end

local function UnitDetected(unitID, unitDefID, isAlly, alwaysUpdate)
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

	local _,_,inBuild = Spring.GetUnitIsStunned(unitID)

	local defenceData = defences[unitID]
	if defenceData then
		if not alwaysUpdate and not configData.colorInBuild or inBuild == defenceData.isBuild then
			return
		end
		RemoveUnit(unitID)
	end

	local x, y, z = spGetUnitPosition(unitID)
	defences[unitID] = {
		drawList = glCreateList(CreateDrawList, configData, inBuild, x, y, z),
		x = x, y = y, z = z,
		inBuild = inBuild,
		isAlly = isAlly,
		unitDefID = unitDefID,
	}
	if (not isAlly) and inBuild and configData.colorInBuild then
		defNeedingBuildingChecks[unitID] = true
	end
	needRedraw = needRedraw or REDRAW_TIME
end

RedoUnitList = function()
	local options = options
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

	RemoveUnit(unitID)
	needRedraw = needRedraw or REDRAW_TIME
end

function widget:UnitEnteredLos(unitID, unitTeam)
	local def = defences[unitID]
	if def then
		-- if this is defence we knew about, we don't need to poll the position for los anymore
		defNeedingLosChecks[unitID] = nil
	end
	UnitDetected(unitID, Spring.GetUnitDefID(unitID), false)
end

function widget:UnitLeftLos(unitID, unitTeam)
	local def = defences[unitID]
	if def then
		-- slow poll this defence's position to see if the position entered los, but the unit didn't, meaning it was destroyed out of los
		defNeedingLosChecks[unitID] = true
		-- we invoke UnitDetected on UnitEnteredLos anyway, and if it is still incomplete then, it'll be re-added to defNeedingBuildingChecks
		defNeedingBuildingChecks[unitID] = nil
	end
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
			glDeleteList(defenseRangeDrawList)
			defenseRangeDrawList = glCreateList(RedrawDrawRanges)
			needRedraw = false
		end
	end
end

local function DoFullUnitReload()
	for unitID,def in pairs(defences) do
		RemoveUnit(unitID)
	end
	local myAllyTeam = Spring.GetMyAllyTeamID()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		local unitAllyTeam = Spring.GetUnitAllyTeam(unitID)
		UnitDetected(unitID, Spring.GetUnitDefID(unitID), unitAllyTeam == myAllyTeam, true)
	end
end

function widget:GameFrame(n)
	if (n % 30) ~= 0 then
		return
	end

	for unitID in pairs(defNeedingBuildingChecks) do
		local unitDefID = spGetUnitDefID(unitID)
		if unitDefID then
			UnitDetected(unitID, unitDefID, false)
		end
	end

	for unitID in pairs(defNeedingLosChecks) do -- TODO: rarely updated but constantly iterated, consider IndexableArray
		if not spGetUnitDefID(unitID) then
			local def = defences[unitID]
			local _, inLos = spGetPositionLosState(def.x, def.y, def.z)
			if inLos then
				RemoveUnit(unitID)
				needRedraw = needRedraw or REDRAW_TIME
			end
		end
	end
end

local myTeam = Spring.GetMyTeamID()
local fullView = false
function widget:PlayerChanged(playerID)
	if myPlayerID ~= playerID then
		return
	end

	local newMyTeam = Spring.GetMyTeamID()
	local newSpectating, newFullView = Spring.GetSpectatingState()
	-- we can avoid a lot of expensive recalulation if we're only moving from spectating one team under fullview to another
	if fullView ~= newFullView or (not fullView and myTeam ~= newMyTeam) then
		if fullView then
			widgetHandler:RemoveCallIn('GameFrame')
			-- we now know everything, but callins for entering radar/los won't trigger in this transition.
		else
			widgetHandler:UpdateCallIn('GameFrame')
			-- we don't know everything anymore, and callins for leaving radar/los won't trigger in this transition.
		end
		-- callins for units entering radar/los won't trigger during team/spectator change
		-- so we could miss incomplete or completed units suddenly appearing in los,
		-- or fail to mark units suddenly leaving los/radar for loschecks.
		DoFullUnitReload()
		fullView = newFullView
	end
	myTeam = newMyTeam
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
	local Checkbox = Chili.Checkbox

	local mainWindow = Window:New{
		classname = "main_window_small_tall",
		name      = 'DefenseRangesWindow',
		x         =  50,
		y         = 150,
		width     = 130,
		height    = 168,
		padding = {12, 12, 12, 12},
		dockable  = true,
		dockableSavePositionOnly = true,
		draggable = true,
		resizable = false,
		tweakResizable = false,
		parent = WG.Chili.Screen0,
	}

	pics.ground = Image:New { x = 0, y = 24*1, file = 'LuaUI/Images/defense_ranges/ground.png' }
	pics.air    = Image:New { x = 0, y = 24*2, file = 'LuaUI/Images/defense_ranges/air.png'    }
	pics.nuke   = Image:New { x = 0, y = 24*3, file = 'LuaUI/Images/defense_ranges/nuke.png'   }
	pics.shield = Image:New { x = 0, y = 24*4, file = 'LuaUI/Images/defense_ranges/shield.png' }
	pics.radar  = Image:New { x = 0, y = 24*5, file = 'LuaUI/Images/defense_ranges/radar.png'  }

	pics.ally  = Image:New { x = 24*1, y = 0, file = 'LuaUI/Images/defense_ranges/defense_ally.png'  }
	pics.enemy = Image:New { x = 24*2, y = 0, file = 'LuaUI/Images/defense_ranges/defense_enemy.png' }
	pics.spec  = Image:New { x = 24*3, y = 0, file = 'LuaUI/Images/dynamic_comm_menu/eye.png'        }

	for key, pic in pairs(pics) do
		pic.width = 24
		pic.height = 24
		mainWindow:AddChild(pic)
	end

	checkboxes.allyground  = Checkbox:New { x = 26, y = 28, noFont = true}
	checkboxes.enemyground = Checkbox:New { x = 50, y = 28, noFont = true}
	checkboxes.specground  = Checkbox:New { x = 74, y = 28, noFont = true}
	checkboxes.allyair     = Checkbox:New { x = 26, y = 52, noFont = true}
	checkboxes.enemyair    = Checkbox:New { x = 50, y = 52, noFont = true}
	checkboxes.specair     = Checkbox:New { x = 74, y = 52, noFont = true}
	checkboxes.allynuke    = Checkbox:New { x = 26, y = 76, noFont = true}
	checkboxes.enemynuke   = Checkbox:New { x = 50, y = 76, noFont = true}
	checkboxes.specnuke    = Checkbox:New { x = 74, y = 76, noFont = true}
	-- no allyshield
	checkboxes.enemyshield = Checkbox:New { x = 50, y = 100, noFont = true}
	-- no specshield
	-- no allyradar
	checkboxes.enemyradar  = Checkbox:New { x = 50, y = 124, noFont = true}
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

	local GCB = WG.GlobalCommandBar
	if GCB then
		local function ToggleWindow()
			if mainWindow then
				mainWindow:SetVisibility(not mainWindow.visible)
			end
		end
		global_command_button = GCB.AddCommand("LuaUI/Images/defense_ranges/defense_colors.png", "Defence Ranges", ToggleWindow)
	end
end

function widget:Initialize()
	widget:PlayerChanged(Spring.GetMyPlayerID())
	SetupChiliStuff()

	RedoUnitList()

	DoFullUnitReload()
end

function widget:Shutdown()
	for unitID,def in pairs(defences) do
		glDeleteList(def.drawList)
	end
	glDeleteList(defenseRangeDrawList)
end
