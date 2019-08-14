function widget:GetInfo() return {
	name      = "Smoke Signals",
	desc      = "Adds a Lups smoke signal to marker points",
	author    = "jK/quantum",
	date      = "Sep, 2008",
	license   = "GNU GPL, v2 or later",
	layer     = 10,
	enabled   = true
} end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Graphics/Effects'
options_order = { 'enable' }
options = {
	enable = {
		name = "Smoke signal markers",
		desc = "Labels are additionally marked by a smoke signal flare.",
		type = "bool",
		value = false,
		noHotkey = true,
		OnChange = function (self)
			if self.value then
				widgetHandler:UpdateCallIn("MapDrawCmd")
			else
				widgetHandler:RemoveCallIn("MapDrawCmd")
			end
		end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local smokeFX = {
	alwaysVisible  = true,
	layer          = 1,
	speed          = 0.65,
	count          = 300,
	life           = 50,
	lifeSpread     = 20,
	delaySpread    = 900,
	rotSpeed       = 1,
	rotSpeedSpread = -2,
	rotSpread      = 360,
	size           = 30,
	sizeSpread     = 5,
	sizeGrowth     = 0.9,
	emitVector     = {0, 1, 0},
	emitRotSpread  = 60,

	-- values that change per instance (here for reference and so that tables stay static)
	force          = {0, 0, 0},
	pos            = {0, 0, 0},
	colormap       = {
		{0.00, 0.00, 0.00, 0.01},
		{0.40, 0.40, 0.40, 0.01},
		{0.15, 0.15, 0.15, 0.20},
		{0.00, 0.00, 0.00, 0.01}
	},
	texture        = 'bitmaps/smoke/smoke01.tga',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local AddParticles

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()

	if not WG.Lups then
		widgetHandler:RemoveCallIn("MapDrawCmd")
		options.enable.OnChange = nil
		return
	end

	AddParticles = WG.Lups.AddParticles
	options.enable.OnChange(options.enable)
end

function widget:MapDrawCmd(playerID, cmdType, px, py, pz, caption)
	if cmdType ~= 'point' or Spring.GetGameFrame() <= 0 then
		return
	end

	local wx, wy, wz = Spring.GetWind()
	smokeFX.force[1] = wx * 0.09
	smokeFX.force[2] = wy * 0.09 + 3
	smokeFX.force[3] = wz * 0.09

	local _,_, spec, teamID = Spring.GetPlayerInfo(playerID, false)
	if spec then
		teamID = Spring.GetGaiaTeamID()
	end
	local r, g, b = Spring.GetTeamColor(teamID)

	smokeFX.pos[1] = px
	smokeFX.pos[2] = py
	smokeFX.pos[3] = pz
	smokeFX.partpos = "r*sin(alpha),0,r*cos(alpha) | alpha=rand()*2*pi, r=rand()*20"
	smokeFX.colormap[2][1], smokeFX.colormap[3][1] = r, r
	smokeFX.colormap[2][2], smokeFX.colormap[3][2] = g, g
	smokeFX.colormap[2][3], smokeFX.colormap[3][3] = b, b
	smokeFX.texture = "bitmaps/smoke/smoke0" .. math.random(1,9) .. ".tga"
	AddParticles('SimpleParticles2', smokeFX)
end
