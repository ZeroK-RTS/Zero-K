function widget:GetInfo()
	return {
		name      = "Gesture Build Menu",
		desc      = "Hold right mouse + move or press B to use",
		author    = "Licho, esainane",
		date      = "2009-2020",
		license   = "GNU GPL, v2 or later",
		layer     = 100000,
		enabled   = false,
		handler   = true,
	}
end

include("keysym.lua")

------ SPEEDUPS

local glGetTextWidth  = gl.GetTextWidth
local glTexture       = gl.Texture
local glTexRect       = gl.TexRect
local glText          = gl.Text
local glColor         = gl.Color

local spEcho          = Spring.Echo

-- consts


local keyconfig = include("Configs/marking_menu_keys.lua", nil, VFS.RAW_FIRST)
local keys = keyconfig.qwerty.keys
local keys_display = keyconfig.qwerty.keys_display

-- options

local ALLOW_MULTIPLE

local function OptionsChanged()
	ALLOW_MULTIPLE = options.allowMultiple.value

	-- XXX: What keyboard someone is using should probably be set in some other, more generic widget
	if options.alternateconfig.value then
		keys = keyconfig.qwerty_d.keys
		keys_display = keyconfig.qwerty_d.keys_display
	elseif options.qwertz.value then
		keys = keyconfig.qwertz.keys
		keys_display = keyconfig.qwertz.keys_display
	else
		keys = keyconfig.qwerty.keys
		keys_display = keyconfig.qwerty.keys_display
	end
end

options_path = 'Settings/Interface/Gesture Menus/Build Menu'
local local_options_order = {'qwertz', 'alternateconfig', 'allowMultiple'}
local local_options = {
	qwertz = {
		name = "qwertz keyboard",
		type = "bool",
		value = false,
		desc = "keys for qwertz keyboard",
		OnChange = OptionsChanged,
	},

	alternateconfig = {
		name = "Alternate Keyboard Layout",
		type = "bool",
		value = false,
		desc = "Centre hotkeys around D instead of S.",
		OnChange = OptionsChanged,
	},

	allowMultiple = {
		name = "Allow for multiple selected units",
		type = "bool",
		value = true,
		desc = "Allows gestures even for multiple units selected",
		OnChange = OptionsChanged,
	}
}

local menu_use = include("Configs/marking_menu_menus.lua", nil, VFS.RAW_FIRST)

local function CanInitialQueue()
	return WG.InitialQueue~=nil and not (Spring.GetGameFrame() > 0)
end

-- Gesture Menu callbacks

local function GetMenuDefinition(keyboard)
	local units = Spring.GetSelectedUnits()
	local initialQueue = CanInitialQueue()
	local allow = (units and (#units == 1 or (#units > 0 and (ALLOW_MULTIPLE or keyboard))) ) or initialQueue

	-- only show menu if a unit is selected
	if allow then
		local found = false
		for _, unitID in ipairs(units) do
			local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
			if ud then
				if ud.isBuilder and menu_use[ud.name] then
					found = ud
				elseif ud.canMove and not keyboard then
					return nil
				end
			else
				return nil
			end
		end

		-- setup menu depending on selected unit
		if found or initialQueue then
			local menu = found and menu_use[found.name] or menu_use["armcom1"]
			return menu
		end
		return nil
	end
end

local function PreDrawMenuItems()
	return Spring.GetActiveCmdDescs()
end

local function DrawMenuItem(item, x,y, size, alpha, displayLabel, angle, userdata)
	local cmdDesc = userdata
	if not alpha then alpha = 1 end
	if displayLabel == nil then displayLabel = true end
	if item then
		local ud = UnitDefNames[item.unit]
		if (ud)	then
			if (displayLabel and item.label) then
				glColor(1,1,1,alpha)
				local wid = glGetTextWidth(item.label)*12
				glText(item.label,x-wid*0.5, y+size,12,"")
			end

			local isEnabled = CanInitialQueue()
			if not isEnabled then
				for _, desc in ipairs(cmdDesc) do
				if desc.id == -ud.id and not desc.disabled then
					isEnabled = true
					break
				end
			end
		end

		if isEnabled then
			glColor(1*alpha,1*alpha,1,alpha)
		else glColor(0.3,0.3,0.3,alpha) end
		glTexture(WG.GetBuildIconFrame(ud))
		glTexRect(x-size, y-size, x+size, y+size)
		glTexture("#"..ud.id)
		glTexRect(x-size, y-size, x+size, y+size)
		glTexture(false)

		if (ud.metalCost) then
			--glColor(1,1,1,alpha)
			glText(ud.metalCost .. " m",x-size+4,y-size + 4,10,"")
		end

		if angle then
			if angle < 0 then angle = angle + 360 end
				local idx = angle / 45
				glColor(0,1,0,1)
				glText(keys_display[1 + idx%8],x-size+4,y+size-10,10,"")
			end
		end
	end
end

local function KeyToAngle(k)
	return keys[k]
end

local function PerformAction(menu_selected, initialWorldOrigin)
	if menu_selected.unit == nil then return false end
	local cmdid = menu_selected.cmd
	if (cmdid == nil) then
		local ud = UnitDefNames[menu_selected.unit]
		if (ud ~= nil) then
			cmdid = Spring.GetCmdDescIndex(-ud.id)
		end
	end
	if (cmdid) then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		local _, _, left, _, right = Spring.GetMouseState()

		Spring.SetActiveCommand(cmdid, 1, left, right, alt, ctrl, meta, shift)
		return true
	end
	return false
end

-- Now, actually create our gesture menu

local ActionMenu
options, options_order, widget.Update, widget.DrawScreen, widget.KeyPress, widget.MousePress, widget.MouseRelease, widget.IsAbove = WG.CreateGestureMenu(
	GetMenuDefinition,
	DrawMenuItem,
	PerformAction,
	PreDrawMenuItems,
	KeyToAngle
)

for k,v in pairs(local_options) do
	options[k] = v
end
for i = 1,#local_options_order do
	options_order[#options_order] = local_options_order[i]
end

-- Set some saner defaults
options.onlyOpenWithKeyboard.value = false

function widget:Initialize()
	OptionsChanged()
	-- FIXME: Do this more nicely
	options.iconDistance.OnChange()
end
