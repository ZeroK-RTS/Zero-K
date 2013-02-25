

local rgbSpecMults = {0.25, 0.25, 0.25} -- specular RGB scales

local dynLightDefs = {
        ["ZK"] = {
			['weaponLightDefs']={
					["nuclear_missile"] = {
							explosionLightDef = {
									diffuseColor      = {40.0,                   20.0,                   5.0                  },
									specularColor     = {200.0 * rgbSpecMults[1], 100.0 * rgbSpecMults[2], 0.0 * rgbSpecMults[3]},
									priority          = 20 * 10 + 1,
									radius            = 1800.0,
									ttl               = 6 * Game.gameSpeed,
									decayFunctionType = {0.0, 0.0, 0.0},
									altitudeOffset    = 0.0,
									altitudeClimb     = 10,
							},
					},
					["corsilo_crblmssl"] = {
							explosionLightDef = {
									diffuseColor      = {20.0,                   10.0,                   5.0                  },
									specularColor     = {255.0 * rgbSpecMults[1],  255 * rgbSpecMults[2], 255 * rgbSpecMults[3]},
									priority          = 20 * 10 + 1,
									radius            = 4000.0,
									ttl               = 20 * Game.gameSpeed,
									decayFunctionType = {0.0, 0.0, 0.0},
									altitudeOffset    = 150.0,
									altitudeClimb     = 7.0,
							},
					},
			},
		},
}

return dynLightDefs
