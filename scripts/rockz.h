//File: rockz.h
//Description: Unit rocking script; z-axis (roll) only.
//Author: Evil4Zerggin
//Date: 5 February 2008


/*How to Use:
1. Copy the following to  the top of your unit script, below the piecenum declarations. MAKE SURE YOU REPLACE VALUES WHEN APPROPRIATE.


#define SIG_ROCK_Z				2		//Signal to prevent multiple rocking. REPLACE!

//rockz
#define ROCK_PIECE				0		//piece to rock. REPLACE!
#define ROCK_Z_SPEED			3		//Number of half-cycles per second around z-axis.
#define ROCK_Z_DECAY			-1/2	//Rocking around z-axis is reduced by this factor each time; should be between -1 and 0 to alternate rocking direction.
#define ROCK_Z_MIN              <0.5>	//If around z-axis rock is not greater than this amount, rocking will stop after returning to center.

#include "rockz.h"


2. In Create() put the following line:
call-script RockZInit();
3. For each weapon that you want to cause rocking, do the following:
	3a. Create a static variable gun_X_yaw.
	3b. In AimWeaponX, put the following line before the return(1); line:
		gun_X_yaw = heading;
	3c. In FireWeaponX or ShotX, put the following line:
		start-script RockZ(rock_z, heading);
		Note the reversed order of the arguments. Scriptor is a neeb and decided to randomly switch the order of the arguments.
		If you don't see any rocking, try reversing them again.
		It may be helpful to #define ROCK_Z_FIRE_X for your weapons to use as the argument rock_z.
		
4. Remove any other x-axis rock-on-fire code (e.g., RockUnit()); otherwise rocking may not work as expected.

More details:
"heading" in the following functions refers to the direction that the weapon was fired in. Use the gun_X_yaw variables for this.
"rock_z" determines how far to rock the unit. Currently the unit will be rocked up to 60 degrees divided by rock_z.
rock_z should be negative to rock away from the firing direction.
*/

#ifndef ROCKZ_H
#define ROCKZ_H

#include "calc.h"

static-var ROCKZ_H_ANGLE;

RockZInit()
{
	ROCKZ_H_ANGLE = 0;
}

RockZ(heading, rock_z)
{
	signal SIG_ROCK_Z;
	set-signal-mask SIG_ROCK_Z;
	call-script ProjXPW(<60> / rock_z, heading);
	ROCKZ_H_ANGLE = ROCKZ_H_ANGLE + CALC_H_RESULT;
	call-script Abs(ROCKZ_H_ANGLE);
	while ( CALC_H_RESULT > ROCK_Z_MIN )
	{
	    turn ROCK_PIECE to z-axis ROCKZ_H_ANGLE speed CALC_H_RESULT * ROCK_Z_SPEED;
		wait-for-turn ROCK_PIECE around z-axis;
		ROCKZ_H_ANGLE = ROCKZ_H_ANGLE * ROCK_Z_DECAY;
		call-script Abs(ROCKZ_H_ANGLE);
	}
	turn ROCK_PIECE to z-axis <0> speed ROCK_Z_MIN * ROCK_Z_SPEED;
}

#endif
