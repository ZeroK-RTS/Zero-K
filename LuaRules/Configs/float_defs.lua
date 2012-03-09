local floatDefs = {
	[UnitDefNames["amphaa"].id] = {
		initialRiseSpeed = 1,
		riseAccel = 0.05,
		riseUpDrag = 0.99,
		riseDownDrag = 0.94,
		sinkAccel = -0.05,
		sinkUpDrag = 0.98,
		sinkDownDrag = 0.98,
		airAccel = -0.15, -- aka gravity, only effective out of water
		floatPoint = -20,
		sinkOnPara = true,
	},
}

return floatDefs