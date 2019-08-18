//File: pushz.h
//Description: Simple unit pushing script for vehicles
//Author: Evil4Zerggin
//Date: 5 February 2008


/*How to Use:
1. Copy the following to the top of your unit script, below the piecenum declarations. MAKE SURE YOU REPLACE VALUES WHEN APPROPRIATE.


#define SIG_PUSH_Z				2		//Signal to prevent multiple pushing. REPLACE!

//pushz
#define PUSH_PIECE				0		//piece to push. REPLACE!
#define PUSH_Z_DIST				[-5]	//Typically half the width of the unit. Keeps the unit's edges from sinking into the ground.
#define PUSH_Z_SPEED			[20]
#define PUSH_Z_RESTORE			[5]

#include "pushz.h"

2. For each weapon that you want to cause pushing, do the following:
	2a. Create a static variable gun_X_yaw.
	2b. In AimWeaponX, put the following line before the return(1); line:
		gun_X_yaw = heading;
	2c. In FireWeaponX or ShotX, put the following line:
		start-script PushZ(heading);
*/

#ifndef PUSHZ_H
#define PUSHZ_H

#include "calc.h"

PushZ(heading)
{
	signal SIG_PUSH_Z;
	set-signal-mask SIG_PUSH_Z;
	call-script ProjZPW(PUSH_Z_DIST, heading);
	move PUSH_PIECE to z-axis CALC_H_RESULT speed PUSH_Z_SPEED;
	wait-for-move PUSH_PIECE along z-axis;
	move PUSH_PIECE to z-axis 0 speed PUSH_Z_RESTORE;
}

#endif
