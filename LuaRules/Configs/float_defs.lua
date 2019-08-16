-- initialRiseSpeed:    Velocity which unit "pushes off" the bottom
-- riseAccel:           Acceleration while trying to surface
-- riseUpDrag:          Drag on negative velocity while trying to surface
-- riseDownDrag:        Drag on positive velocity while trying to surface
-- sinkAccel:           Acceleration while trying to sink
-- sinkUpDrag:          Drag on negative velocity while trying to sink
-- sinkDownDrag:        Drag on positive velocity while trying to sink
-- airAccel:            Acceleration while out of water. aka gravity qhich is only active out of water
-- airDrag:             Drag on speed while out of water
-- waterHitDrag:        Reduction in speed upon hitting the water
-- floatPoint:          Position of unit base that denotes the surface of the water
-- depthRequirement:    Max depth of sea floor that float can be enabled
-- sinkOnPara:          If true the unit will set to sink if paralysed. In either mode state cannot be changed while paraed
-- stopSpeedLeeway:     Below this speed the unit can snap to surface
-- stopPositionLeeway:  Below this distance from the surface the unit can stnap to surface.

-- PHYSIC UPDATE (4 April 2013):
-- as in ZK version >= r9871 (>1.1.3.6) all "Drag" related constant now mean "dragCoefficient" from Physic's drag equation ( this equation here: http://en.wikipedia.org/wiki/Drag_equation ),
-- from this physic equation, the negative acceleration (the resistance) is defined by :  resistiveAccel = 0.5*(currentVelocity*currentVelocity*dragCoefficient)
-- this mean faster unit has more drag, and bigger "Drag" cause more drag, while smaller "Drag" lead to less drag, while 0 "Drag" lead to 0 drag (and 0 drag will lead to infinite speed).

local floatDefs = {
	
	-- This unit pushes off the floor and swims to the surface at fairly constant
	-- velocity. It then treads water so sinks if EMPed. It is heavier than water
	-- so sinks at a fairly constant velocity as well.
	[UnitDefNames["amphaa"].id] = {
		initialRiseSpeed = 3,
		riseAccel = 0.12,
		riseUpDrag = 0.9,
		riseDownDrag = 0.7,
		sinkAccel = -0.12,
		sinkUpDrag = 0.9,
		sinkDownDrag = 0.9,
		airAccel = -0.1, -- aka gravity, only effective out of water
		airDrag = 0.995,
		waterHitDrag = 0.5,
		floatPoint = -20,
		depthRequirement = -30,
		stopSpeedLeeway = 0.05,
		stopPositionLeeway = 0.1,
	},

	[UnitDefNames["amphimpulse"].id] = {
		initialRiseSpeed = 5,
		riseAccel = 0.15,
		riseUpDrag = 0.99,
		riseDownDrag = 0.7,
		sinkAccel = -0.12,
		sinkUpDrag = 0.9,
		sinkDownDrag = 0.9,
		airAccel = -0.2, -- aka gravity, only effective out of water
		airDrag = 0.92,
		waterHitDrag = 0.5,
		floatPoint = -12,
		depthRequirement = -30,
		sinkTankRequirement = false,
		stopSpeedLeeway = 0.05,
		stopPositionLeeway = 0.1,
	},
		
	-- This unit expels water with an air tank to float. It results in high rise
	-- acceleration with low drag. To sink the tank must be filled with water
	-- which results in a delay and low sink acceleration.
	[UnitDefNames["amphfloater"].id] = {
		initialRiseSpeed = 2,
		riseAccel = 0.10,
		riseUpDrag = 0.97,
		riseDownDrag = 0.9,
		sinkAccel = -0.10,
		sinkUpDrag = 0.9,
		sinkDownDrag = 0.9,
		airAccel = -0.1, -- aka gravity, only effective out of water
		airDrag = 0.995,
		waterHitDrag = 0.8,
		floatPoint = -15,
		depthRequirement = -15,
		stopSpeedLeeway = 0.05,
		stopPositionLeeway = 0.1,
	},
	
	-- Big epic unit moves up and down about as quickly as Atlantis
	[UnitDefNames["amphassault"].id] = {
		initialRiseSpeed = 1.5,
		riseAccel = 0.06,
		riseUpDrag = 0.9,
		riseDownDrag = 0.7,
		sinkAccel = -0.06,
		sinkUpDrag = 0.9,
		sinkDownDrag = 0.9,
		airAccel = -0.3, -- aka gravity, only effective out of water
		airDrag = 1,
		waterHitDrag = 0.5,
		floatPoint = -40,
		depthRequirement = -40,
		stopSpeedLeeway = 0.05,
		stopPositionLeeway = 0.1,
	},
}

for id, def in pairs (floatDefs) do
	def.sinkOnPara = (UnitDefs[id].customParams.sink_on_emp ~= '0')
end

return floatDefs
