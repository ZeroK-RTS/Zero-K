local jumpDefs = {}

for id, ud in pairs (UnitDefs) do
	local cp = ud.customParams
	if cp.canjump == "1" then
		jumpDefs[id] = {
			range = tonumber(cp.jump_range),
			speed = tonumber(cp.jump_speed),
			reload = tonumber(cp.jump_reload),
			delay = tonumber(cp.jump_delay),
			height = tonumber(cp.jump_height),

			rotateMidAir = (tonumber(cp.jump_rotate_midair) == 1),
			cannotJumpMidair = (tonumber(cp.jump_from_midair) == 0),
			JumpSpreadException = (tonumber(cp.jump_spread_exception) == 1),
		}
	end
end

return jumpDefs
