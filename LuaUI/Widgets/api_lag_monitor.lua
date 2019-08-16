--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Lag (AFK) monitor",
    desc      = "Monitors user presses and mouse moves",
    author    = "Licho",
    date      = "4.1.2012",
    license   = "GPLv2",
    layer     = 1000,
    enabled   = true,  --  loaded by default?
    handler   = false,
    api       = true,
	alwaysStart = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetGameSeconds = Spring.GetGameSeconds


local second
local secondSent
local lx, ly


function widget:MousePress()
	second = spGetGameSeconds()
end

function widget:KeyPress()
	second = spGetGameSeconds()
end

function widget:GameFrame(f)
	if f%51 == 0 then
		local mx, my = Spring.GetMouseState()
		if mx ~= lx or my ~= ly then
			lx = mx
			ly = my
			second = spGetGameSeconds()
		end
		
		if second ~= secondSent then
			Spring.SendLuaRulesMsg('AFK'..second)
			secondSent = second
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
