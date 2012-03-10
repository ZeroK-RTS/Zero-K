local floatDefs = {
	[UnitDefNames["amphaa"].id] = {
		initialRiseSpeed = 2,
		riseAccel = 0.07,
		riseUpDrag = 0.9,
		riseDownDrag = 0.7,
		sinkAccel = -0.06,
		sinkUpDrag = 0.9,
		sinkDownDrag = 0.9,
		airAccel = -0.1, -- aka gravity, only effective out of water
		airDrag = 0.995,
		floatPoint = -20,
		depthRequirement = -30,
		sinkOnPara = true,
		stopSpeedLeeway = 0.05,
		stopPositionLeeway = 0.1,
	},
	
	[UnitDefNames["amphfloater"].id] = {
		initialRiseSpeed = 0.1,
		riseAccel = 0.015,
		riseUpDrag = 0.98,
		riseDownDrag = 0.9,
		sinkAccel = -0.01,
		sinkUpDrag = 0.9,
		sinkDownDrag = 0.98,
		airAccel = -0.1, -- aka gravity, only effective out of water
		airDrag = 0.995,
		floatPoint = -15,
		depthRequirement = -15,
		sinkOnPara = false,
		stopSpeedLeeway = 0.05,
		stopPositionLeeway = 0.1,
	},
}

return floatDefs