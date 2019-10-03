--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Icon Height",
    desc      = "Displays icons for all units at once, depending on camera height",
    author    = "CrazyEddie",
    date      = "2013-10-13",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
	handler   = true,
    enabled   = false,
  }
end

--[[

This widget changes the icon-vs-unit drawing behavior such that either
ALL units are drawn as icons or ALL units are drawn as units.

The primary purpose is to allow for zooming in close and level to
watch a battle from a ground perspective, while having ALL the units
visible as units, even those far off in the distance behind the
battle in front of you. This may be desired for casts or video
recording, or simply because you think it looks better.

At the same time, one doesn't want to lose the ability to zoom out
and see units as icons. You could deal with this by adjusting the
Icon Distance, but that requires manual intervention (even if bound
to a hotkey).

Accordingly, this widget will dynamically change the Icon Distance
based on the current camera height. When you are low to the ground,
the Icon Distance is set very high, so that all units will be seen
as units no matter how far away they are. Conversely, when you are
high above the ground, the Icon Distance is set to zero, so that all
units appear as icons no matter how close they are. What constitutes
"low to the ground" is settable by a configuration slider.

Note that this could cause your PC to unexpectedly attempt to render
lots of units in high detail. Be warned that your performance could
suffer if your PC is not up to the task.

----

In addition, since you may at some point decide that you want to see
icons even below your chosen threshold altitude, or see units above it,
you can manually override the dynamic Icon Distance using a hotkey.

When you press the hotkey, if you are currently seeing icons you
will then see only units, no matter what your camera height is.
Conversely, if you are currently seeing units you will then see only
icons. Dynamic changing will be turned off. You can switch back and
forth between units and icons any time, as often as you like, using
the hotkey as a toggle.

If you double-press the hotkey (like double-clicking the mouse
button, i.e. twice in rapid succession) then you will reactivate
Dynamic mode, and you will once again see icons when up high and
units when down low.

----

LIMITATIONS

The principal drawback is that every time you transition between high
and low altitude, the widget uses Spring.SendCommands to change the
Icon Distance. This causes Spring to log a message. Which means that
your chat console will be constantly spammed with useless messages.

I have not yet found any way around this.

If you know of one, please let me know. Or just add it.

--]]

include("keysym.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Parameters
local tolerance = 25

-- Flags and switches
local waiting_on_double
local current_mode
local target_mode
local showing_icons

-- Variables
local kp_timer

-- Forward function declarations
local UpdateDynamic = function() end
local GotHotkeypress = function() end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Graphics/Unit Visibility'

options_order = {
	'lblIconHeight',
	'iconheight',
	'iconmodehotkey',
}

options = {

	lblIconHeight = {name='Icon Height Widget', type='label'},
	iconheight = {
		name = 'Icon Height',
		desc = 'If the camera is above this height, all units will be icons; if below, no units will be icons.\n\nOnly applies when the icon display mode is set to Dynamic.\n\nThis setting overrides Icon Distance.',
		type = 'number',
		min = 0, max = 10000,
		value = 2500,
	},
	iconmodehotkey = {
		name = "Icon Mode Hotkey",
		desc = "Define a hotkey to switch between icon display modes (On/Off/Dynamic).\n\nSingle-press to switch between On/Off.\n\nDouble-press to switch to Dynamic.",
		type = 'button',
		OnChange = function(self) GotHotkeypress() end,
	},

}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

GotHotkeypress = function()
	if waiting_on_double then
		waiting_on_double = false
		target_mode = nil
		kp_timer = nil
		current_mode = "Dynamic"
		UpdateDynamic()
	else
		waiting_on_double = true
		kp_timer = Spring.GetTimer()
		if current_mode == "On" then target_mode = "Off"
		elseif current_mode == "Off" then target_mode = "On"
		elseif showingicons then target_mode = "Off"
		else target_mode = "On"
		end
	end
end

local UpdateDynamic = function()
	local cs = Spring.GetCameraState()
	local gy = Spring.GetGroundHeight(cs.px, cs.pz)
	local testHeight = cs.py - gy
	if cs.name == "ov" then
		testHeight = options.iconheight.value * 2
	elseif cs.name == "ta" then
		testHeight = cs.height - gy
	end
	if showingicons and testHeight < options.iconheight.value - tolerance then
		Spring.SendCommands("disticon " .. 100000)
		showingicons = false
	elseif not showingicons and testHeight > options.iconheight.value + tolerance then
		Spring.SendCommands("disticon " .. 0)
		showingicons = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update()
	
	if not waiting_on_double and (current_mode == "On" or current_mode == "Off") then return end

	if not waiting_on_double then UpdateDynamic() -- Not waiting, Dynamic mode
	else
		-- Waiting to see if there's a double keypress
		local now_timer = Spring.GetTimer()
		if kp_timer and Spring.DiffTimers(now_timer, kp_timer) < 0.2 then return end -- keep waiting
		
		-- Otherwise, time's up
		if target_mode == "On" then
			Spring.SendCommands("disticon " .. 0)
			showingicons = true
			current_mode = "On"
		else
			Spring.SendCommands("disticon " .. 100000)
			showingicons = false
			current_mode = "Off"
		end
		target_mode = nil
		kp_timer = nil
		waiting_on_double = nil
	end

end

function widget:Initialize()
	waiting_on_double = false
	target_mode = nil
	kp_timer = nil
	current_mode = "Dynamic"
	UpdateDynamic()
end
