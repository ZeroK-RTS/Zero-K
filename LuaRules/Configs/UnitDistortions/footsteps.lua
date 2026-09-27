
local function BigStomp(piece)
	return {
		-- Footstep shockwave
		alwaysVisible = false,
		distortionType = "point",
		distortionName = "bigstomp",
		pieceName = piece,
		distortionConfig = {
			posx = 0,
			posy = -6,
			posz = 12,
			radius = 60,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.4,
			distanceFalloff = 0.4,
			onlyModelMap = 1,
			effectStrength = 0.9,
			lifeTime = 15,
			rampUp = 3,
			decay = 15,
			startRadius = 0.3,
			shockWidth = 5,
			effectType = "groundShockwave",
		},
	}
end

local function SmallStomp(piece)
	return {
		-- Footstep shockwave
		alwaysVisible = false,
		distortionType = "point",
		distortionName = "smallstomp",
		pieceName = piece,
		distortionConfig = {
			posx = 0,
			posy = -8,
			posz = 0,
			radius = 35,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.4,
			distanceFalloff = 0.5,
			onlyModelMap = 1,
			effectStrength = 0.5,
			lifeTime = 12,
			rampUp = 3,
			decay = 10,
			startRadius = 0.3,
			shockWidth = 3,
			effectType = "groundShockwave",
		},
	}
end

local defs = {
	striderdetriment = {
		script = {
			leftfoot = BigStomp("lfoot"),
			rightfoot = BigStomp("rfoot"),
		}
	},
	jumpsumo = {
		script = {
			leftfront = SmallStomp("lf_foot"),
			rightfront = SmallStomp("rf_foot"),
			leftback = SmallStomp("lb_foot"),
			rightback = SmallStomp("rb_foot"),
		}
	},
}

return defs
