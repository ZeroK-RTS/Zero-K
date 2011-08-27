
local function raise(piece, angle, speed, theta)
	local x_part = math.sin(theta)
	local z_part = math.cos(theta)
	Turn(piece, x_axis, angle*x_part, math.abs(speed*x_part))
	Turn(piece, z_axis, angle*z_part, math.abs(speed*z_part))
end

function walk(br, mr, fr, bl, ml, fl,
		legRaiseAngle, legRaiseSpeed, legLowerSpeed,
		legForwardAngle, legForwardOffset, legForwardSpeed, legForwardTheta,
		legMiddleAngle, legMiddleOffset, legMiddleSpeed, legMiddleTheta,
		legBackwardAngle, legBackwardOffset, legBackwardSpeed, legBackwardTheta,
		sleepTime)
		
	local slowState = 1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0)
	legRaiseSpeed = legRaiseSpeed * slowState
	legForwardSpeed = legForwardSpeed * slowState
	legMiddleSpeed = legMiddleSpeed * slowState
	legBackwardSpeed = legBackwardSpeed * slowState
	sleepTime = sleepTime/slowState
	
	raise(fl, legRaiseAngle, legRaiseSpeed, -legForwardTheta)
	raise(mr, -legRaiseAngle, legRaiseSpeed, legMiddleTheta)
	raise(bl, legRaiseAngle, legRaiseSpeed, -legBackwardTheta)
		
	Turn(fl, y_axis, -(legForwardAngle+legForwardOffset), legForwardSpeed)	-- LF leg forward
	Turn(mr, y_axis, (legMiddleAngle+legMiddleOffset), legMiddleSpeed)	-- RM leg forward
	Turn(bl, y_axis, -(legBackwardAngle+legBackwardOffset), legBackwardSpeed)	-- LB leg forward
	
	Turn(fr, y_axis, -(legForwardAngle-legForwardOffset), legForwardSpeed)	-- RF leg back
	Turn(ml, y_axis, (legMiddleAngle-legMiddleOffset), legMiddleSpeed)	-- LM leg down
	Turn(br, y_axis, -(legBackwardAngle-legBackwardOffset), legBackwardSpeed)	-- RB leg back	

	Sleep(sleepTime)
	
	raise(fl, 0, legLowerSpeed, -legForwardTheta)
	raise(mr, 0, legLowerSpeed, legMiddleTheta)
	raise(bl, 0, legLowerSpeed, -legBackwardTheta)
	
	Sleep(sleepTime)	
	
	raise(fr, -legRaiseAngle, legRaiseSpeed, legForwardTheta)
	raise(ml, legRaiseAngle, legRaiseSpeed, -legMiddleTheta)
	raise(br, -legRaiseAngle, legRaiseSpeed, legBackwardTheta)
	
	Turn(fr, y_axis, (legForwardAngle+legForwardOffset), legForwardSpeed)	-- RF leg forward
	Turn(ml, y_axis, -(legMiddleAngle+legMiddleOffset), legMiddleSpeed)	-- LM leg forward
	Turn(br, y_axis, (legBackwardAngle+legBackwardOffset), legBackwardSpeed)	-- RB leg forward		
	
	Turn(fl, y_axis, (legForwardAngle-legForwardOffset), legForwardSpeed)	-- LF leg back
	Turn(mr, y_axis, -(legMiddleAngle-legMiddleOffset), legMiddleSpeed)	-- RM leg down
	Turn(bl, y_axis, (legBackwardAngle-legBackwardOffset), legBackwardSpeed)	-- LB leg back	
	
	Sleep(sleepTime)				
	
	raise(fr, 0, legLowerSpeed, legForwardTheta)
	raise(ml, 0, legLowerSpeed, -legMiddleTheta)
	raise(br, 0, legLowerSpeed, legBackwardTheta)
	
	Sleep(sleepTime)	

end