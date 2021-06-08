--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Font Cache",
		desc      = "Cache for Chili fonts.",
		author    = "GoogleFrog",
		date      = "8 June 2021",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		alwaysStart = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DISABLE = false

local font = {}
local specialFont = {}

function WG.GetFont(size)
	size = size or 14
	if (not font[size]) or DISABLE then
		font[size] = WG.Chili.Font:New {
			font          = "FreeSansBold.otf",
			size          = size,
			shadow        = true,
			outline       = false,
			outlineWidth  = 3,
			outlineWeight = 3,
			color         = {1, 1, 1, 1},
			outlineColor  = {0, 0, 0, 1},
			autoOutlineColor = true,
		}
	end
	return font[size]
end

function WG.GetSpecialFont(size, name, data)
	size = size or 14
	if not specialFont[size] then
		specialFont[size] = {}
	end
	if (not specialFont[size][name]) or DISABLE then
		local shadows, outline, autoOutlineColor = true, false, true
		if data.shadows ~= nil then
			shadows = data.shadows
		end
		if data.outline ~= nil then
			outline = data.outline
		end
		if data.autoOutlineColor ~= nil then
			autoOutlineColor = data.autoOutlineColor
		end
		specialFont[size][name] = WG.Chili.Font:New {
			font          = data.font or "FreeSansBold.otf",
			size          = data.size or size,
			shadow        = shadows,
			outline       = outline,
			outlineWidth  = data.outlineWidth or 3,
			outlineWeight = data.outlineWeight or 3,
			color         = data.color or {1, 1, 1, 1},
			outlineColor  = data.outlineColor or {0, 0, 0, 1},
			autoOutlineColor = autoOutlineColor,
		}
	end
	return specialFont[size][name]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
