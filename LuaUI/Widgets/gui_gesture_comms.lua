function widget:GetInfo()
	return {
		name      = "Gesture Communicator Menu",
		desc      = "Quickly add common points to the map with a gesture.",
		author    = "esainane",
		date      = "2019-11",
		license   = "GNU GPL, v2 or later",
		layer     = 20050,
		enabled   = true  --  loaded by default?
	}
end

include("keysym.lua")

local MarkerAddPoint  = Spring.RealMarkerAddPoint

local glGetTextWidth  = gl.GetTextWidth
local glTexture       = gl.Texture
local glTexRect       = gl.TexRect
local glText          = gl.Text
local glColor         = gl.Color

local spEcho = Spring.Echo

options_path = 'Settings/Interface/Gesture Menus/Comms Menu'
local local_options_order = {}
local local_options = {}

local menu_use = include("Configs/teamcomms_menu_menus.lua", nil, VFS.RAW_FIRST)

local function GetMenuDefinition(keyboard, mouse_pos, world_pos)
	if world_pos == nil then return nil end
	return menu_use.default
end

local function PerformAction(menu_selected, initialWorldOrigin)
	if menu_selected.marker == nil then return false end
	MarkerAddPoint(initialWorldOrigin[1],initialWorldOrigin[2],initialWorldOrigin[3],menu_selected.marker,false)
	return true
end

local function DrawMenuItem(item, x,y, size, alpha, displayLabel, angle)
	if not alpha then alpha = 1 end
	if displayLabel == nil then displayLabel = true end
	if item then
		if (displayLabel and item.label) then
			glColor(1,1,1,alpha)
			local wid = glGetTextWidth(item.label)*12
			glText(item.label,x-wid*0.5, y+size*2,12,"")
		elseif (item.marker) then
			glColor(1,1,1,alpha)
			local wid = glGetTextWidth(item.marker)*12
			glText(item.marker,x-wid*0.5, y+size*2,12,"")
		end

		local isEnabled = true
		local r,g,b = 1,1,1
		if item.tint then
			r,g,b = item.tint.r, item.tint.g, item.tint.b
		end
		if not isEnabled then
			r,g,b = r*0.3,g*0.3,b*0.3
		end
		glColor(r,g,b,alpha)
		if item.icon then
			glTexture(item.icon)
			glTexRect(x-size, y-size, x+size, y+size)
			glTexture(false)
		end
	end
end

-- Now, actually create our gesture menu

local ActionMenu
options, options_order, widget.Update, widget.DrawScreen, widget.KeyPress, widget.MousePress, widget.MouseRelease, widget.IsAbove = WG.CreateGestureMenu(
	GetMenuDefinition,
	DrawMenuItem,
	PerformAction
)

for k,v in pairs(local_options) do
	options[k] = v
end
for i = 1,#local_options_order do
	options_order[#options_order] = local_options_order[i]
end

-- Set some saner defaults
options.iconDistance.value = 120

function widget:Initialize()
	-- FIXME: Do this more nicely
	options.iconDistance.OnChange()
end
