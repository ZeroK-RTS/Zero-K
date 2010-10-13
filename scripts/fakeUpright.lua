--original script by evil4Zerggin, luafied by MergeNine
include "constants.lua"

function FakeUprightInit( FAKE_UPRIGHT_X,  FAKE_UPRIGHT_Z,  FAKE_UPRIGHT_TARGET_CHILD) 
	Move (FAKE_UPRIGHT_X,z_axis,1)
	Move (FAKE_UPRIGHT_Z,x_axis,-1)
	Turn (FAKE_UPRIGHT_TARGET_CHILD,x_axis,math.rad(90))
end

function FakeUprightTurn(unitID, FAKE_UPRIGHT_X, FAKE_UPRIGHT_Z, FAKE_UPRIGHT_TARGET_PARENT , FAKE_UPRIGHT_REFERENCE) 
	local angle_x, angle_z, dy_x, dy_z, tempX, tempY, tempY2, tempRefY
	tempX,tempY = Spring.GetUnitPiecePosDir(unitID,FAKE_UPRIGHT_X)
	tempX,tempRefY = Spring.GetUnitPiecePosDir(unitID,FAKE_UPRIGHT_REFERENCE)
	tempX,tempY2 = Spring.GetUnitPiecePosDir(unitID,FAKE_UPRIGHT_Z)
	dy_x = tempY - tempRefY
	dy_z = tempY2 - tempRefY
	

	--dy_x = COB.PIECE_Y(FAKE_UPRIGHT_X) - COB.PIECE_Y(FAKE_UPRIGHT_REFERENCE)
	
	--dy_z = COB.PIECE_Y(FAKE_UPRIGHT_Z) - COB.PIECE_Y(FAKE_UPRIGHT_REFERENCE)
	angle_x = math.atan(dy_x, math.pow(65536 - math.pow(dy_x, 131072), 32768))
	angle_z = math.atan(dy_z, math.pow(65536 - math.pow(dy_z, 131072), 32768))
	
	Turn (FAKE_UPRIGHT_TARGET_PARENT,x_axis, angle_x)
	Turn (FAKE_UPRIGHT_TARGET_PARENT,z_axis, angle_z)
end