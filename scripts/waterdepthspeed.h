//File: waterdepthspeed.h
//Description: COB component of waterdepthspeed modoption
//Author: Evil4Zerggin
//Date: 3 August 2008
//
//Requires a constants file.
//
//Directions:
//1. Include this file by putting the line
//
//	#include "waterdepthspeed.h"
//
//at the top.
//2a. For boats: in Create() put the following line:
//
//	start-script WaterDepthSpeedBoat();
//
//2b. For ships/subs: in Create() put the following line:
//
//	start-script WaterDepthSpeedShip();

#ifndef WATERDEPTHSPEED_H
#define WATERDEPTHSPEED_H

#define LUA_WATERDEPTHSPEED_DIST		4100
#define LUA_WATERDEPTHSPEED_HEIGHT_BOAT	4101
#define LUA_WATERDEPTHSPEED_HEIGHT_SHIP	4102
#define LUA_WATERDEPTHSPEED_MAX			4103

WaterDepthSpeedBoat() {
	var base_speed, speed_penalty;
	
	if (!GET LUA_WATERDEPTHSPEED_DIST) return;
	
	base_speed = GET MAX_SPEED;
	
	while (1) {
		speed_penalty = ((GET LUA_WATERDEPTHSPEED_HEIGHT_BOAT) - GET GROUND_WATER_HEIGHT(GET UNIT_XZ))
			/ GET LUA_WATERDEPTHSPEED_DIST;
		if (speed_penalty < 0) speed_penalty = 0;
		else if (speed_penalty > GET LUA_WATERDEPTHSPEED_MAX) speed_penalty = GET LUA_WATERDEPTHSPEED_MAX;
		SET MAX_SPEED to base_speed * (100 - speed_penalty) / 100;
		sleep 30;
	}
}

WaterDepthSpeedShip() {
	var base_speed, speed_penalty;
	
	if (!GET LUA_WATERDEPTHSPEED_DIST) return;
	
	base_speed = GET MAX_SPEED;
	
	while (1) {
		speed_penalty = (GET GROUND_WATER_HEIGHT(GET UNIT_XZ) - GET LUA_WATERDEPTHSPEED_HEIGHT_SHIP)
			/ GET LUA_WATERDEPTHSPEED_DIST;
		if (speed_penalty < 0) speed_penalty = 0;
		else if (speed_penalty > GET LUA_WATERDEPTHSPEED_MAX) speed_penalty = GET LUA_WATERDEPTHSPEED_MAX;
		SET MAX_SPEED to base_speed * (100 - speed_penalty) / 100;
		sleep 30;
	}
}

#endif
