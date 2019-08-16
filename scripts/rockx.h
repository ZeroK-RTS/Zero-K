//File: rockx.h
//Description: Unit rocking script; x-axis (pitch) only.
//Author: Evil4Zerggin
//Date: 14 February 2008


/*How to Use:
1. Copy the following to  the top of your unit script, below the piecenum declarations. MAKE SURE YOU REPLACE VALUES WHEN APPROPRIATE.

#define SIG_ROCK_X				2		//Signal to prevent multiple rocking. REPLACE!

//rockx
#define ROCK_PIECE				0		//piece to rock. REPLACE!
#define ROCK_X_SPEED			3		//Number of half-cycles per second around x-axis.
#define ROCK_X_DECAY			-1/2	//Rocking around x-axis is reduced by this factor each time; should be negative to alternate rocking direction.
#define ROCK_X_MIN              <0.5>	//If around x-axis rock is not greater than this amount, rocking will stop after returning to center.

#include "rockx.h"

2. In Create() put the following line:
call-script RockXInit();
3. For each weapon that you want to cause rocking, do the following:
	3a. Create a static variable gun_X_yaw.
	3b. In AimWeaponX, put the following line before the return(1); line:
		gun_X_yaw = heading;
	3c. In FireWeaponX or ShotX, put the following line:
		start-script RockX(rock_x, heading);
		Note the reversed order of the arguments. Scriptor is a neeb and decided to randomly switch the order of the arguments.
		If you don't see any rocking, try reversing them again.
		It may be helpful to #define ROCK_X_FIRE_X for your weapons to use as the argument rock_x.

4. Remove any other x-axis rock-on-fire code (e.g., RockUnit()); otherwise rocking may not work as expected.

More details:
"heading" in the following functions refers to the direction that the weapon was fired in. Use the gun_X_yaw variables for this.
"rock_x" determines how far to rock the unit. Currently the unit will be rocked up to 60 degrees divided by rock_x.
rock_x should be negative to rock away from the firing direction.
*/

#ifndef ROCKX_H
#define ROCKX_H

#include "calc.h"

static-var ROCKX_H_ANGLE;

RockXInit()
{
	ROCKX_H_ANGLE = 0;
}

RockX(heading, rock_x)
{
	signal SIG_ROCK_X;
	set-signal-mask SIG_ROCK_X;
	call-script ProjZPW(<60> / rock_x, heading);
	ROCKX_H_ANGLE = ROCKX_H_ANGLE + CALC_H_RESULT;
	call-script Abs(ROCKX_H_ANGLE);
	while ( CALC_H_RESULT > ROCK_X_MIN )
	{
	    turn ROCK_PIECE to x-axis ROCKX_H_ANGLE speed CALC_H_RESULT * ROCK_X_SPEED;
		wait-for-turn ROCK_PIECE around x-axis;
		ROCKX_H_ANGLE = ROCKX_H_ANGLE * ROCK_X_DECAY;
		call-script Abs(ROCKX_H_ANGLE);
	}
	turn ROCK_PIECE to x-axis <0> speed ROCK_X_MIN * ROCK_X_SPEED;
}

#endif
