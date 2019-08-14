//File: fakeupright.h
//Description: Fake upright script
//Author: Evil4Zerggin
//Date: 12 September 2008

/*
Model Requirements:
1. You need two pieces to made upright, one a child of the other.
2. The model for the unit must have three pieces all in the same spot, tied directly to something that doesn't turn relative to the base
and not used in other animation.
There should be a "ref", "x", and "z" piece.
You can use the base for the ref piece if it is not being used in animation and is not the piece to be made upright.
All three pieces should be in the same location.

Script Requirements:
1. Copy the following to  the top of your unit script, below the piecenum declarations. MAKE SURE YOU REPLACE VALUES WHEN APPROPRIATE.

//fakeupright
#define FAKE_UPRIGHT_TARGET_PARENT	0
#define FAKE_UPRIGHT_TARGET_CHILD	0	//piece to make upright
#define FAKE_UPRIGHT_REFERENCE		0
#define FAKE_UPRIGHT_X				0
#define FAKE_UPRIGHT_Z				0

#include "fakeupright.h"

2. In Create() put the following line:
call-script FakeUprightInit();

3. Whenever you want the piece to be turned upright, put the following line:
call-script FakeUprightTurn();
*/

#ifndef FAKEUPRIGHT_H
#define FAKEUPRIGHT_H

#include "constants.h"

FakeUprightInit() {
	move FAKE_UPRIGHT_X to z-axis [1] now;
	move FAKE_UPRIGHT_Z to x-axis [-1] now;
	turn FAKE_UPRIGHT_TARGET_CHILD to x-axis <90> now;
}

FakeUprightTurn() {
	var angle_x, angle_z, dy_x, dy_z;
	dy_x = GET PIECE_Y(FAKE_UPRIGHT_X) - GET PIECE_Y(FAKE_UPRIGHT_REFERENCE);
	dy_z = GET PIECE_Y(FAKE_UPRIGHT_Z) - GET PIECE_Y(FAKE_UPRIGHT_REFERENCE);
	angle_x = GET ATAN(dy_x, GET POW(65536 - GET POW(dy_x, 131072), 32768));
	angle_z = GET ATAN(dy_z, GET POW(65536 - GET POW(dy_z, 131072), 32768));
	turn FAKE_UPRIGHT_TARGET_PARENT to x-axis angle_x now;
	turn FAKE_UPRIGHT_TARGET_PARENT to z-axis angle_z now;
}

#endif
