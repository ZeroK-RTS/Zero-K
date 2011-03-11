--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Stuck Keys",
    desc      = "v0.01 Alerts user when a key is stuck.",
    author    = "CarRepairer",
    date      = "2011-03-01",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("keysym.h.lua")
local keysyms = {}
for k,v in pairs(KEYSYMS) do
	keysyms[v] = k
end


local keys = {}
local cycle = 1
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:KeyPress(key, modifier, isRepeat)
	if not keys[key] then
		keys[key] = 10
	end
end
function widget:KeyRelease(key)
	keys[key] = nil
end

function widget:Update()
	cycle = (cycle + 1) % 32
	
	if cycle == 1 then
		for key, time in pairs(keys) do
			keys[key] = time - 1
			if keys[key] < 0 then
				echo( 'The key "' .. keysyms[key] .. '" has been pressed for over 10 seconds. It might be stuck, try tapping it.' )
				keys[key] = 10
			end
		end
	end
end


--------------------------------------------------------------------------------
