//File: calc.h
//Description: Calculator header
//Author: Evil4Zerggin
//Date: 6 March 2008

#ifndef		CALC_H_
#define		CALC_H_

#define		CALC_H_RADIANS_PER_ANGLE	4/(163 * 256)

static-var	CALC_H_RESULT;
//The results of each calculation are stored in CALC_H_RESULT.
//The result remains valid until one of the following occurs:
//1. A sleep or wait statement. Another calculation may occur while the function is sleeping or waiting.
//2. A function call (or start?). The function may conduct a calculation.
//If more permanent storage is needed you should copy the result to another variable.

Abs(x)
{
	if (x >= 0)
	{
		CALC_H_RESULT = x;
	}
	else
	{
		CALC_H_RESULT = 0 - x;
	}
}

//piece-wise projection on x-axis
ProjXPW(mag, angle) {
	if (angle < <-120>) {
		CALC_H_RESULT = mag * (angle + <180>) / <60>;
	} else if (angle > <120>) {
		CALC_H_RESULT = mag * (<180> - angle) / <60>;
	} else if (angle < <-60>) {
		CALC_H_RESULT = 0 - mag;
	} else if (angle > <60>) {
		CALC_H_RESULT = mag;
	} else {
		CALC_H_RESULT = mag * angle / <60>;
	}
}

//piece-wise projection on z-axis
ProjZPW(mag, angle) {
	if (angle < <-150> || angle > <150>) {
		CALC_H_RESULT = 0 - mag;
	} else if (angle > <30>) {
		CALC_H_RESULT = mag * (<90> - angle) / <60>;
	} else if (angle < <-30>) {
		CALC_H_RESULT = mag * (angle + <90>) / <60>;
	} else {
		CALC_H_RESULT = mag;
	}
}

#endif
