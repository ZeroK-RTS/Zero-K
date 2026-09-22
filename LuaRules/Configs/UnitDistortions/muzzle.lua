

local defs = {
	amphlaunch = {
		script = {
			launch = {
				distortionType = "point",
				distortionConfig = {
					posx = 0,
					posy = 0,
					posz = 0,
					radius = 180,
					effectStrength = 0.3,
					noiseScaleSpace = 0.2,
					noiseStrength = 0.3,
					onlyModelMap = 0,
					lifeTime = 7,
					refractiveIndex = 1.03,
					decay = 6,
					rampUp = 1,
					effectStrength = 1.8,
					startRadius = 0.6,
					shockWidth = -0.80,
					effectType = "airShockwave",
				},
			},
			launchGround = {
				distortionType = "point",
				distortionConfig = {
					posx = 0,
					posy = -6,
					posz = 12,
					radius = 180,
					noiseStrength = 0.3,
					noiseScaleSpace = 0.4,
					distanceFalloff = 0.8,
					onlyModelMap = 1,
					effectStrength = 0.75,
					lifeTime = 21,
					rampUp = 6,
					decay = 12,
					startRadius = 0.1,
					shockWidth = 5,
					effectType = "groundShockwave",
				},
			}
		}
	},
}

return defs
