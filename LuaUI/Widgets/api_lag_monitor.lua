--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Lag (AFK) monitor",
		desc      = "Monitors user presses and mouse moves",
		author    = "Licho",
		date      = "4.1.2012",
		license   = "GPLv2",
		layer     = -1000, -- so the indicator draws in front of Chili.
		enabled   = true,  --  loaded by default?
		handler   = false,
		api       = true,
		alwaysStart = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetGameSeconds = Spring.GetGameSeconds

local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local glBeginEnd             = gl.BeginEnd
local glColor                = gl.Color
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glScale                = gl.Scale
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex

local WARNING_SECONDS = 8

local pieColor  = { 1.0, 0.3, 0.3, 1 }
local circleDivs = 80

local second
local secondSent
local lx, ly
local lagmonitorSeconds = Spring.GetGameRulesParam("lagmonitor_seconds")
local dangerZone = false
local supressDrawUntilNextFrame = false
local personallySucceptible = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:MousePress()
	second = spGetGameSeconds()
end

function widget:KeyPress()
	second = spGetGameSeconds()
end

function widget:GameFrame(f)
	if f%51 == 0 or dangerZone then
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
		dangerZone = false
		supressDrawUntilNextFrame = false
	end
end

function widget:TextInput()
	second = spGetGameSeconds()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawPie(fraction)
	local radius = 100 * (WG.uiScale or 1)
	local mouseX, mouseY = Spring.GetMouseState()
	
	glPushMatrix()
	glTranslate(mouseX, mouseY, 0)
	glScale(radius, radius, 1)
	if fraction < 1 then
		pieColor[4] = 0.1 + 0.7 * fraction
	else
		pieColor[4] = 0.6 + 0.2 * math.cos(WARNING_SECONDS * 8 * (fraction - 1))
	end
	fraction = math.min(1, fraction)
	glColor(pieColor)
	glBeginEnd(GL_TRIANGLE_FAN, function()
		glVertex(0, 0, 0)
		for i = 0, math.floor(circleDivs * fraction) do
			local r = 2.0 * math.pi * ( -i / circleDivs) + math.pi / 2
			local cosv = math.cos(r)
			local sinv = math.sin(r)
			glVertex(cosv, sinv, 0)
		end
		local r = 2.0 * math.pi * ( -circleDivs * fraction / circleDivs) + math.pi / 2
		local cosv = math.cos(r)
		local sinv = math.sin(r)
		glVertex(cosv, sinv, 0)
	end)
	glPopMatrix()
end

function widget:DrawScreen()
	if not (lagmonitorSeconds and secondSent and personallySucceptible) then
		return
	end
	if (supressDrawUntilNextFrame) then
		return
	end
	local afkSeconds = Spring.GetGameSeconds() - secondSent
	if afkSeconds > lagmonitorSeconds - WARNING_SECONDS then
		DrawPie(1 - (lagmonitorSeconds - afkSeconds) / WARNING_SECONDS)
		dangerZone = true
		if select(3, Spring.GetGameSpeed()) then -- If game is paused.
			supressDrawUntilNextFrame = true -- Hides AFK that is cancelled while pausd.
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateLagmonitorSucceptibility()
	if Spring.GetSpectatingState() then
		return false
	end
	local teamList = Spring.GetTeamList(Spring.GetMyAllyTeamID())
	local myTeamID = Spring.GetMyTeamID()
	for i = 1, #teamList do
		local teamID = teamList[i]
		if myTeamID ~= teamID then
			local _, _, _, isAiTeam = Spring.GetTeamInfo(teamID)
			if not isAiTeam then
				if not Spring.GetTeamLuaAI(teamID) then
					return true
				end
			end
		end
	end
	return false
end

function widget:PlayerChanged()
	personallySucceptible = UpdateLagmonitorSucceptibility()
end

function widget:Initialize()
	personallySucceptible = UpdateLagmonitorSucceptibility()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
