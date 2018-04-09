
if addon.InGetInfo then
	return {
		name    = "Main",
		desc    = "displays a simplae loadbar",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

local lastLoadMessage = ""
local lastProgress = {0, 0}

local progressByLastLine = {
	["Parsing Map Information"] = {0, 20},
	["Loading Weapon Definitions"] = {10, 50},
	["Loading LuaRules"] = {40, 80},
	["Loading LuaUI"] = {70, 95},
	["Finalizing"] = {100, 100}
}
for name,val in pairs(progressByLastLine) do
	progressByLastLine[name] = {val[1]*0.01, val[2]*0.01}
end

function addon.LoadProgress(message, replaceLastLine)
	lastLoadMessage = message
	if message:find("Path") then -- pathing has no rigid messages so cant use the table
		lastProgress = {0.8, 1.0}
	end
	lastProgress = progressByLastLine[message] or lastProgress
end

------------------------------------------

local font = gl.LoadFont("FreeSansBold.otf", 50, 20, 1.95)
local vsx, vsy = gl.GetViewSizes()

function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()
	if loadProgress == 0 then
		loadProgress = lastProgress[1]
	else
		loadProgress = math.min(math.max(loadProgress, lastProgress[1]), lastProgress[2])
	end

	gl.BeginEnd(GL.QUADS, function()

		--bar bg
		gl.Color(0,0,0,1)
			gl.Vertex(0, 0.1)
			gl.Vertex(1, 0.1)
			gl.Vertex(1, 0)
			gl.Vertex(0, 0)

		--progress
		gl.Color(1,1,1,0.7)
			gl.Vertex(0, 0.1)
			gl.Vertex(0 + loadProgress, 0.1)
			gl.Vertex(0 + loadProgress, 0)
			gl.Vertex(0, 0)

		--bar border
		gl.Color(1,1,1,1)
			gl.Vertex(0, 0.1)
			gl.Vertex(1, 0.1)
			gl.Vertex(1, 0.11)
			gl.Vertex(0, 0.11)
	end)

	gl.PushMatrix()
	gl.Scale(1/vsx,1/vsy,1)
	local barTextSize = vsy * (0.07)
	font:Print(("%.0f%%"):format(loadProgress * 100), vsx * 0.02, vsy * 0.02, barTextSize, "o")
	gl.PopMatrix()
end

function addon.Shutdown()
	gl.DeleteFont(font)
end
