//File: timexp.h
//Description: Makes the unit gain XP over time
//Author: Evil4Zerggin
//Date: 13 May 2008

/*How to use:
1.Decide how long to wait before increasing the unit's xp by 0.01. Then,
	#define TIME_XP_PERIOD time

2. Below that, put
	#include "timexp.h"

3. At the end of Create(), put
	start-script TimeXP();
*/

#ifndef TIMEXP_H
#define TIMEXP_H

TimeXP()
{
	var xp;
	xp = 0;
	while (GET BUILD_PERCENT_LEFT) sleep 500;
	while (1) {
		++xp;
		SET VETERAN_LEVEL to xp;
		sleep TIME_XP_PERIOD;
	}
}

#endif
