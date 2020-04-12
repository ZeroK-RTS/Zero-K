
if addon.InGetInfo then
	return {
		name    = "Main",
		desc    = "displays a simple loadbar",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------
local BAR_SCALING = 0.72
local X_OFFSET = -0.1575
local Y_OFFSET = -0.02

local lastLoadMessage = ""
local lastProgress = {0, 0}

local progressByLastLine = {
	["Parsing Map Information"] = {0, 20},
	["Loading Weapon Definitions"] = {10, 50},
	["Loading LuaRules"] = {40, 80},
	["Loading LuaUI"] = {70, 95},
	["Loading Skirmish AIs"] = {100, 100},
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

local font = gl.LoadFont("FreeSansBold.otf", 50, 20, 1.75)

function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()
	if loadProgress == 0 then
		loadProgress = lastProgress[1]
	else
		loadProgress = math.min(math.max(loadProgress, lastProgress[1]), lastProgress[2])
	end

	local vsx, vsy = gl.GetViewSizes()

	-- draw progressbar
	gl.PushMatrix()
	gl.Scale(BAR_SCALING,BAR_SCALING,1)
	gl.Translate(X_OFFSET,Y_OFFSET,0)
	
	gl.Texture(":n:LuaIntro/Images/barframe.png")
		gl.TexRect(0.188,0.2194,0.810,0.097)
	gl.Texture(false)
	
	gl.BeginEnd(GL.QUADS, function()
		--progress
		gl.Color(0.15,0.91,0.97,0.95)
			gl.Vertex(0.2035, 0.186)
			gl.Vertex(0.2035 + math.max(0, loadProgress-0.01) * 0.595, 0.186)
			gl.Vertex(0.2035 + math.max(0, loadProgress-0.01) * 0.595, 0.17)
			gl.Vertex(0.2035, 0.17)
		gl.Color(0.1,0.73,0.75,0.95)
			gl.Vertex(0.2035 + math.max(0, loadProgress-0.01) * 0.595, 0.186)
			gl.Vertex(0.2035 + math.max(0, loadProgress-0.01) * 0.595, 0.17)
		gl.Color(0.05,0.67,0.69,0)
			gl.Vertex(0.2035 + math.min(1, math.max(0, loadProgress+0.01)) * 0.595, 0.17)
			gl.Vertex(0.2035 + math.min(1, math.max(0, loadProgress+0.01)) * 0.595, 0.186)
	end)

	-- progressbar text
	gl.PushMatrix()
	gl.Scale(1/vsx,1/vsy,1)
	local barTextSize = vsy * (0.05 - 0.015)

	--font:Print(lastLoadMessage, vsx * 0.5, vsy * 0.3, 50, "sc")
	--font:Print(Game.gameName, vsx * 0.5, vsy * 0.95, vsy * 0.07, "sca")
	--font:Print(lastLoadMessage, vsx * 0.2, vsy * 0.14, barTextSize*0.5, "sa")
	font:Print(lastLoadMessage, vsx * 0.5, vsy * 0.125, barTextSize*0.775, "oc")
	if loadProgress>0 then
		font:Print(("%.0f%%"):format(loadProgress * 100), vsx * 0.5, vsy * 0.171, barTextSize*0.65, "oc")
	else
		font:Print("Loading...", vsx * 0.5, vsy * 0.171, barTextSize*0.65, "oc")
	end
	gl.PopMatrix()
	
	gl.PopMatrix()
end


function addon.MousePress(...)
	--Spring.Echo(...)
end


function addon.Shutdown()
	gl.DeleteFont(font)
end
