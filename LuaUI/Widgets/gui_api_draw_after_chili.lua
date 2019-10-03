-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Draw After Chili",
		desc      = "Lets widgets with layers below Chili do some of their drawing after Chili",
		author    = "Histidine (L.J. Lim)",
		date      = "2018-05-08",
		license   = "Public domain/CC0",
		handler   = true,
		layer     = -10000001, -- Lower than minimap and api_chili.lua
		enabled   = true,
		alwaysStart = true,
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local drawFuncs = {}

local function DrawAfterChili(func)
  drawFuncs[#drawFuncs + 1] = func
end

function widget:DrawScreen()
	for i = #drawFuncs, 1, -1 do
		drawFuncs[i]()
		drawFuncs[i] = nil
	end
end

function widget:Initialize()
	WG.DrawAfterChili = DrawAfterChili
end

function widget:Shutdown()
	WG.DrawAfterChili = nil
end
