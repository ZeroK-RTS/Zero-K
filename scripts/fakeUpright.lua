--original script by evil4Zerggin, luafied by MergeNine
--completely rewritten from first principles by GoogleFrog

if GG.FakeUpright then
	return
end
GG.FakeUpright = {}

function GG.FakeUpright.FakeUprightInit(xp, zp, drop)
	Move (xp,z_axis,5000)
	Move (zp,x_axis,5000)
	Turn(drop, x_axis, math.rad(90))
end

function GG.FakeUpright.FakeUprightTurn(unitID, xp, zp, base, preDrop)
	
	local xx, xy, xz = Spring.GetUnitPiecePosDir(unitID,xp)
	local zx, zy, zz = Spring.GetUnitPiecePosDir(unitID,zp)
	local bx, by, bz = Spring.GetUnitPiecePosDir(unitID,base)
	local xdx = xx - bx
	local xdy = xy - by
	local xdz = xz - bz
	local zdx = zx - bx
	local zdy = zy - by
	local zdz = zz - bz
	local angle_x = math.atan2(xdy, math.sqrt(xdx^2 + xdz^2))
	local angle_z = math.atan2(zdy, math.sqrt(zdx^2 + zdz^2))

	Turn(preDrop, x_axis, angle_x)
	Turn(preDrop, z_axis, -angle_z)
end
