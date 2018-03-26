--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "PlanetWars Info",
    desc      = "Writes some PW stuff",
    author    = "KingRaptor (L.J. Lim)",
    date      = "Nov 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 1, 
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Utilities/base64.lua")

local Chili
local factionDisplayWindow, teleportWindow

local imageDir = "LuaUI/Configs/Factions/"

local STRUCTURE_HEIGHT = 16
local DEBUG_MODE = false

local EVAC_STATE = {
	ACTIVE = 1,
	NO_WORMHOLE = 2,
	NOTHING_TO_EVAC = 3,
	WORMHOLE_DESTROYED = 4,
}

local factions = {
	Cybernetic = {name = "Cybernetic Front", color = {136,170,255} },
	--Dynasty = {name = "Dynasty of Earth", color = {255, 170, 32} },
	Dynasty = {name = "Dynasty of Man", color = {255, 191, 0} },
	Machines = {name = "Free Machines", color = {170, 0, 0} },
	Empire = {name = "Empire Reborn", color = {96, 16, 255} },
	Liberty = {name = "Liberated Humanity", color = {85, 187, 85} },
	SynPact = {name = "Synthetic Pact", color = {83, 136, 235} },
}

for faction, data in pairs(factions) do
	for i = 1, 3 do
		data.color[i] = data.color[i]/255
	end
end

local flashState = true

local global_button_evacuation
local global_button_instructions
local lbl_battle_instructions
local lbl_planet

local strings = {
	evac_ready = "",
	evac_charging = "",
	evac_no_wormhole = "",
	evac_wormhole_destroyed = "",
	evac_nothing_to_evac = "",
	evac_broken = "",
	toggle_evacuation_name = "",
	toggle_evacuation_desc = "",
	toggle_pw_instructions_name = "",
	toggle_pw_instructions_desc = "",
	pw_battle_instructions = "",
}

local numCharges = -1
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function IsSpec()
	return (Spring.GetSpectatingState() or Spring.IsReplay())
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Structure List

local function CreateStructureButton(holder, index)
	local unitName = Spring.GetGameRulesParam("pw_structureList_" .. index)
	local humanName = UnitDefNames[unitName].humanName
	
	-- TODO: This should have a button which zooms the camera to the structure, when pressed,
	-- if the structure is visible and alive.
	
	local structureName = Chili.Label:New{
		x = 2,
		y = (index - 1)*STRUCTURE_HEIGHT,
		width = "100%",
		height = STRUCTURE_HEIGHT,
		align = "left",
		valign = "top",
		caption = humanName,
		font = {size = 14},
		parent = holder,
	}
	
	local externalFunctions = {}
	
	function externalFunctions.Destroy()
		structureName:SetCaption("\255\255\0\0\x " .. humanName)
	end
	function externalFunctions.Evacuate()
		structureName:SetCaption("\255\0\255\255\~ " .. humanName)
	end
	function externalFunctions.Teleporting()
		flashState = not flashState
		if flashState then
			structureName:SetCaption("\255\0\205\255\- " .. humanName)
		else
			structureName:SetCaption("\255\0\255\205\- " .. humanName)
		end
	end
	
	return externalFunctions, unitName
end

local function CreateStructureList(holder)
	local structureCount = Spring.GetGameRulesParam("pw_structureList_count")
	if not structureCount then
		return
	end
	
	local destroyedCount, evacCount = 0, 0
	local structures = {}
	local structuresByName = {}
	for i = 1, structureCount do
		structures[i], unitName = CreateStructureButton(holder, i)
		structuresByName[unitName] = structures[i]
	end
	
	local externalFunctions = {}
	
	function externalFunctions.Update()
		local newDestroyed = Spring.GetGameRulesParam("pw_structureDestroyed_" .. (destroyedCount + 1))
		while newDestroyed do
			structuresByName[newDestroyed].Destroy()
			destroyedCount = destroyedCount + 1
			newDestroyed = Spring.GetGameRulesParam("pw_structureDestroyed_" .. (destroyedCount + 1))
		end
		
		local newEvac = Spring.GetGameRulesParam("pw_structureEvacuated_" .. (evacCount + 1))
		while newEvac do
			structuresByName[newEvac].Evacuate()
			evacCount = evacCount + 1
			newEvac = Spring.GetGameRulesParam("pw_structureEvacuated_" .. (evacCount + 1))
		end
		
		local teleportUnitName = Spring.GetGameRulesParam("pw_teleport_unitname")
		if teleportUnitName then
			structuresByName[teleportUnitName].Teleporting()
		end
		
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Teleport Window

local function CreateTeleportWindow()
	local structureCount = Spring.GetGameRulesParam("pw_structureList_count") or 0
	
	local evacuable = true
	local holderHeight = 78 + structureCount*STRUCTURE_HEIGHT
	
	local holderWindow = Chili.Window:New{
		classname = ((holderHeight > 130) and "main_window_small") or "main_window_small_flat",
		name   = 'pw_teleport_meter_1',
		y = 48,
		right = 2, 
		width = 240,
		height = holderHeight,
		dockable = true,
		dockableSavePositionOnly = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		parent = Chili.Screen0,
	}
	local teleportImage = Chili.Image:New{
		y = 2,
		right = 4,
		width = 24,
		height = 24,
		file = "LuaUI/Images/commands/Bold/drop_beacon.png",
		parent = holderWindow,
	}
	local teleportLabel = Chili.Label:New{
		x = 4,
		y = 4,
		width = "100%",
		height = 18,
		align = "left",
		valign = "top",
		caption = '',
		font = {size = 14},
		parent = holderWindow,
	}
	local teleportProgress = WG.Chili.Progressbar:New{
		x       = 4,
		y       = 26,
		right   = 4,
		height  = 20,
		max     = 1,
		caption = "0%",
		color   =  {0.15,0.4,0.9,1},
		parent  = holderWindow,
	}
	
	local structureHolder = WG.Chili.ScrollPanel:New{
		x       = 4,
		y       = 52,
		right   = 4,
		bottom  = 4,
		horizontalScrollbar = false,
		parent  = holderWindow,
	}
	
	local structureList = CreateStructureList(structureHolder)
	
	local function CheckEvacuationState(forceUpdate)
		if not evacuable and not forceUpdate then
			return false
		end
		local evacuateState = Spring.GetGameRulesParam("pw_evacuable_state")
		if evacuateState == EVAC_STATE.ACTIVE then
			return true
		end
		evacuable = false
		
		teleportImage:SetVisibility(false)
		teleportProgress:SetVisibility(false)
		structureHolder:SetPos(4, 20)
		holderWindow:SetPos(nil, nil, nil, holderHeight - 32)
		
		if evacuateState == EVAC_STATE.NO_WORMHOLE then
			teleportLabel:SetCaption("\255\128\128\128" .. strings.evac_no_wormhole .. "\008")
		elseif evacuateState == EVAC_STATE.NOTHING_TO_EVAC then
			teleportLabel:SetCaption("\255\128\128\128" .. strings.evac_nothing_to_evac .. "\008")
		elseif evacuateState == EVAC_STATE.WORMHOLE_DESTROYED then
			teleportLabel:SetCaption("\255\128\128\128" .. strings.evac_wormhole_destroyed .. "\008")
		else
			teleportLabel:SetCaption("\255\128\128\128" .. strings.evac_broken .. "\008")
		end
	end
	
	local function UpdateBar()
		local current = Spring.GetGameRulesParam("pw_teleport_charge") or 0
		local needed = Spring.GetGameRulesParam("pw_teleport_charge_needed") or 1
		local currentRemainder = current%needed
		local numChargesNew = math.floor(current/needed)
		
		teleportProgress:SetValue(current/needed)
		local percent = math.floor(current/needed * 100 + 0.5)
		teleportProgress:SetCaption(percent .. "%")
		
		if numChargesNew ~= numCharges then
			local text = ""
			if (numChargesNew > 0) then
				text = "\255\0\255\32 " .. strings.evac_ready .. "\008"
				teleportImage.color = {1,1,1,1}
			else
				text = "\255\128\128\128" .. strings.evac_charging .. "\008"
				teleportImage.color = {0.3, 0.3, 0.3, 1}
			end
			teleportLabel:SetCaption(text)
			teleportImage:Invalidate()
			
			numCharges = numChargesNew
		end
	end
	
	local externalFunctions = {}
	
	function externalFunctions.Update(force)
		if CheckEvacuationState(force) then
			UpdateBar()
		end
		if structureList then
			structureList.Update()
		end
	end
	
	externalFunctions.Update()
	
	if WG.GlobalCommandBar then
		local function ToggleWindow()
			if holderWindow then
				holderWindow:SetVisibility(not holderWindow.visible)
			end
		end
		global_button_evacuation = WG.GlobalCommandBar.AddCommand("LuaUI/Images/commands/Bold/drop_beacon.png", strings.toggle_evacuation_name .. "\n\n" .. strings.toggle_evacuation_desc, ToggleWindow)
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Info Window

local function CreateFactionDisplayWindow()
	local modoptions = Spring.GetModOptions()
	local planet = modoptions.planet
	local attacker = modoptions.attackingfaction
	local defender = modoptions.defendingfaction
	
	local WINDOW_HEIGHT = 116
	local WINDOW_WIDTH = 220
	local IMAGE_WIDTH = 36
	
	local ATTACKER_POS = 20
	local DEFENDER_POS = 60
	
	factionDisplayWindow = Chili.Window:New{
		classname = "main_window_small",
		name   = 'pwinfo_1',
		width = WINDOW_WIDTH,
		height = WINDOW_HEIGHT,
		x = 2,
		y = 48,
		dockable = true,
		dockableSavePositionOnly = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		--color = {1, 1, 1, 0.6},
		--minimizable = true,
		--itemMargin  = {0, 0, 0, 0},
		parent = Chili.Screen0,
	}
	
	lbl_planet = Chili.Label:New {
		x = 0,
		y = 4,
		width = WINDOW_WIDTH - factionDisplayWindow.padding[1] - factionDisplayWindow.padding[3],
		height = WINDOW_HEIGHT/3,
		align = "center",
		caption = WG.Translate("interface", "planet", {planet = planet}),
		font = {
			size = 16,
			shadow = true,
		},
		parent = factionDisplayWindow,
	}
	
	if not attacker then
		Chili.Label:New {
			x = IMAGE_WIDTH + 20,
			y = ATTACKER_POS + 6,
			height = IMAGE_WIDTH,
			caption = "No attacker",
			font = {
				size = 14,
				shadow = true,
			},
			parent = factionDisplayWindow,
		}
	else
		local attackerIcon = imageDir..attacker..".png"
		if VFS.FileExists(attackerIcon) then
			Chili.Image:New {
				x = 10,
				y = ATTACKER_POS,
				width = IMAGE_WIDTH,
				height = IMAGE_WIDTH,
				keepAspect = true,
				file = attackerIcon,
				parent = factionDisplayWindow,
			}
		end
		Chili.Label:New {
			x = IMAGE_WIDTH + 20,
			y = ATTACKER_POS + 6,
			height = IMAGE_WIDTH,
			align="left",
			caption = factions[attacker] and factions[attacker].name or attacker or "Unknown attacker",
			font = {
				size = 14,
				shadow = true,
				color = factions[attacker] and factions[attacker].color,
			},
			parent = factionDisplayWindow,
		}
	end
	
	if not defender then
		Chili.Label:New {
			x = IMAGE_WIDTH + 20,
			y = DEFENDER_POS + 6,
			height = IMAGE_WIDTH,
			caption = "No defender",
			font = {
				size = 14,
				shadow = true,
			},
			parent = factionDisplayWindow,
		}
	else
		local defenderIcon = imageDir..defender..".png"
		if VFS.FileExists(defenderIcon) then
			Chili.Image:New {
				x = 10,
				y = DEFENDER_POS,
				width = IMAGE_WIDTH,
				height = IMAGE_WIDTH,
				keepAspect = true,
				file = defenderIcon,
				parent = factionDisplayWindow,
			}
		end
		Chili.Label:New {
			x = IMAGE_WIDTH + 20,
			y = DEFENDER_POS + 6,
			height = IMAGE_WIDTH,
			caption = factions[defender] and factions[defender].name or defender or "Unknown defender",
			font = {
				size = 14,
				shadow = true,
				color = factions[defender] and factions[defender].color,
			},
			parent = factionDisplayWindow,
		}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Info Window

local function CreateGoalWindow()
	if IsSpec() then
		return
	end
	local customKeys = select(10, Spring.GetPlayerInfo(Spring.GetMyPlayerID())) or {}
	if (not DEBUG_MODE) and (not customKeys.pwinstructions) then
		return
	end
	local instructions = (DEBUG_MODE and "bla") or Spring.Utilities.Base64Decode(customKeys.pwinstructions)
	if not instructions then
		return
	end
	
	local WINDOW_HEIGHT = 320
	local WINDOW_WIDTH = 480
	
	local instructionWindow =  Chili.Window:New{
		classname = "main_window_small",
		name   = 'pw_instructions_1',
		x = 2,
		y = 178, 
		width = WINDOW_WIDTH,
		height = WINDOW_HEIGHT,
		dockable = true,
		dockableSavePositionOnly = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		--color = {1, 1, 1, 0.6},
		--minimizable = true,
		--itemMargin  = {0, 0, 0, 0},
		parent = Chili.Screen0,
	}
	
	lbl_battle_instructions = Chili.Label:New {
		x = 0,
		y = 4,
		width = WINDOW_WIDTH - instructionWindow.padding[1] - instructionWindow.padding[3],
		height = 20,
		align = "center",
		caption = strings.pw_battle_instructions,
		font = {
			size = 18,
			shadow = true,
		},
		parent = instructionWindow,
	}
	
	Chili.TextBox:New {
		x = 6,
		y = 35,
		right = 6,
		bottom = 6,
		text = instructions,
		fontsize = 14,
		parent = instructionWindow,
	}
	
	local function ToggleWindow()
		if instructionWindow then
			instructionWindow:SetVisibility(not instructionWindow.visible)
		end
	end
	
	Chili.Button:New {
		name = 'closeButton',
		width = 80,
		height = 38,
		bottom = 6,
		right = 5,
		caption = WG.Translate("interface", "close"),
		OnClick = {ToggleWindow},
		font = {size = 16},
		parent = instructionWindow,
	}
	
	if WG.GlobalCommandBar then
		global_button_instructions = WG.GlobalCommandBar.AddCommand("LuaUI/Images/planetQuestion.png", strings.toggle_pw_instructions_name .. "\n\n" .. strings.toggle_pw_instructions_desc, ToggleWindow)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GameFrame(n)
	if n%120 == 1 and (not IsSpec()) then
		if factionDisplayWindow and (not DEBUG_MODE) then
			factionDisplayWindow:Dispose()
		end
	end
	if n%10 == 3 then
		if teleportWindow then
			teleportWindow.Update()
		else
			teleportWindow = CreateTeleportWindow()
		end
	end
end

local function languageChanged ()
	for k, v in pairs(strings) do
		strings[k] = WG.Translate("interface", k)
	end

	if global_button_evacuation then
		global_button_evacuation.tooltip = strings.toggle_evacuation_name .. "\n\n" .. strings.toggle_evacuation_desc
		global_button_evacuation:Invalidate()
	end
	if global_button_instructions then
		global_button_instructions.tooltip = strings.toggle_pw_instructions_name .. "\n\n" .. strings.toggle_pw_instructions_desc
		global_button_instructions:Invalidate()
	end
	if lbl_battle_instructions then
		lbl_battle_instructions:SetCaption(strings.pw_battle_instructions)
	end
	if lbl_planet then
		lbl_planet:SetCaption(WG.Translate("interface", "planet", {planet = Spring.GetModOptions().planet}))
	end
	if teleportWindow then
		teleportWindow.Update(true)
	end
end

function widget:Initialize()
	if (not DEBUG_MODE) and (not Spring.GetModOptions().planet) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	CreateFactionDisplayWindow()
	CreateGoalWindow()
	WG.InitializeTranslation (languageChanged, GetInfo().name)
end

function widget:GamePreload()
	teleportWindow = CreateTeleportWindow()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------