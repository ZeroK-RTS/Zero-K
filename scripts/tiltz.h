//File: tiltz.h
//Description: Simple unit tilting script for vehicles
//Author: Evil4Zerggin
//Date: 5 February 2008


/*How to Use:
1. Copy the following to  the top of your unit script, below the piecenum declarations. MAKE SURE YOU REPLACE VALUES WHEN APPROPRIATE.


#define SIG_TILT_Z				2		//Signal to prevent multiple tilting. REPLACE!

//tiltz
#define TILT_PIECE				0		//piece to tilt. REPLACE!
#define TILT_Z_ANGLE			<-5>	//How much to tilt at maximum
#define TILT_Z_DIST				[5]		//Typically half the width of the unit. Keeps the unit's edges from sinking into the ground.
#define TILT_Z_SPEED			8		//Number of half-cycles per second around z-axis

#include "tiltz.h"

2. For each weapon that you want to cause tilting, do the following:
	2a. Create a static variable gun_X_yaw.
	2b. In AimWeaponX, put the following line before the return(1); line:
		gun_X_yaw = heading;
	2c. In FireWeaponX or ShotX, put the following line:
		start-script TiltZ(heading);
*/

#ifndef TILTZ_H
#define TILTZ_H

#include "calc.h"

TiltZ(heading)
{
	var tiltz_angle, tiltz_dist, tilt_z_speed;
	signal SIG_TILT_Z;
	set-signal-mask SIG_TILT_Z;
	call-script ProjXPW(TILT_Z_ANGLE, heading);
	tiltz_angle = CALC_H_RESULT;
	call-script Abs(tiltz_angle * TILT_Z_SPEED);
	tilt_z_speed = CALC_H_RESULT;
	call-script Abs(TILT_Z_DIST * CALC_H_RADIANS_PER_ANGLE * tiltz_angle);
	tiltz_dist = CALC_H_RESULT;
	turn TILT_PIECE to z-axis tiltz_angle speed tilt_z_speed;
	move TILT_PIECE to y-axis tiltz_dist speed tiltz_dist * TILT_Z_SPEED;
	wait-for-turn TILT_PIECE around z-axis;
	wait-for-move TILT_PIECE along y-axis;
	turn TILT_PIECE to z-axis 0 speed tilt_z_speed;
	move TILT_PIECE to y-axis 0 speed tiltz_dist * TILT_Z_SPEED;
}

#endif
