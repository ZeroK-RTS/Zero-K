#ifndef CONSTANTS_H_
#define CONSTANTS_H_

#define SFXTYPE_VTOL			0
//#define SFXTYPE_THRUST			1
#define	SFXTYPE_WAKE1			2
#define	SFXTYPE_WAKE2			3
#define	SFXTYPE_REVERSEWAKE1	4
#define	SFXTYPE_REVERSEWAKE2	5

//#define SFXTYPE_POINTBASED		256
#define SFXTYPE_WHITESMOKE		256|1
#define SFXTYPE_BLACKSMOKE		256|2
#define SFXTYPE_SUBBUBBLES		256|3

#define SHATTER			1		// The piece will shatter instead of remaining whole
#define EXPLODE_ON_HIT		2		// The piece will explode when it hits the ground
#define FALL			4		// The piece will fall due to gravity instead of just flying off
#define SMOKE			8		// A smoke trail will follow the piece through the air
#define FIRE			16		// A fire trail will follow the piece through the air
#define BITMAPONLY		32		// The piece will not fly off or shatter or anything.  Only a bitmap explosion will be rendered.
#define NOCEGTRAIL		64		// Disables the cegtrail for the specific piece (defined in the unit fbi)
#define BITMAP			10000001

// Bitmap Explosion Types
#define BITMAP1			256
#define BITMAP2			512
#define BITMAP3			1024
#define BITMAP4			2048
#define BITMAP5			4096
#define BITMAPNUKE		8192
#define BITMAPMASK		16128	// Mask of the possible bitmap bits

// Explosion generators
#define UNIT_SFX1				1024
#define UNIT_SFX2				1025
#define UNIT_SFX3				1026
#define UNIT_SFX4				1027
#define UNIT_SFX5				1028
#define UNIT_SFX6				1029
#define UNIT_SFX7				1030
#define UNIT_SFX8				1031

// Weapons
#define FIRE_W1					2048
#define FIRE_W2					2049
#define FIRE_W3					2050
#define FIRE_W4					2051
#define FIRE_W5					2052
#define FIRE_W6					2053
#define FIRE_W7					2054
#define FIRE_W8					2055

#define DETO_W1					4096
#define DETO_W2					4097
#define DETO_W3					4098
#define DETO_W4					4099
#define DETO_W5					4100
#define DETO_W6					4101
#define DETO_W7					4102
#define DETO_W8					4103


// COB constants
#define ACTIVATION           1  // set or get
#define STANDINGMOVEORDERS   2  // set or get
#define STANDINGFIREORDERS   3  // set or get
#define HEALTH               4  // get (0-100%)
#define INBUILDSTANCE        5  // set or get
#define BUSY                 6  // set or get (used by misc. special case missions like transport ships)
#define PIECE_XZ             7  // get
#define PIECE_Y              8  // get
#define UNIT_XZ              9  // get
#define UNIT_Y              10  // get
#define UNIT_HEIGHT         11  // get
#define XZ_ATAN             12  // get atan of packed x,z coords
#define XZ_HYPOT            13  // get hypot of packed x,z coords
#define ATAN                14  // get ordinary two-parameter atan
#define HYPOT               15  // get ordinary two-parameter hypot
#define GROUND_HEIGHT       16  // get land height, 0 if below water
#define BUILD_PERCENT_LEFT  17  // get 0 = unit is built and ready, 1-100 = How much is left to build
#define YARD_OPEN           18  // set or get (change which plots we occupy when building opens and closes)
#define BUGGER_OFF          19  // set or get (ask other units to clear the area)
#define ARMORED             20  // set or get

/*#define WEAPON_AIM_ABORTED  21
#define WEAPON_READY        22
#define WEAPON_LAUNCH_NOW   23
#define FINISHED_DYING      26
#define ORIENTATION         27*/
#define IN_WATER            28
#define CURRENT_SPEED       29
//#define MAGIC_DEATH         31
#define VETERAN_LEVEL       32
#define ON_ROAD             34

#define MAX_ID                    70
#define MY_ID                     71
#define UNIT_TEAM                 72
#define UNIT_BUILD_PERCENT_LEFT   73
#define UNIT_ALLIED               74
#define MAX_SPEED                 75
#define CLOAKED                   76
#define WANT_CLOAK                77
#define GROUND_WATER_HEIGHT       78 // get land height, negative if below water
#define UPRIGHT                   79 // set or get
#define	POW                       80 // get
#define PRINT                     81 // get, so multiple args can be passed
#define HEADING                   82 // get
#define TARGET_ID                 83 // get
#define LAST_ATTACKER_ID          84 // get
#define LOS_RADIUS                85 // set or get
#define AIR_LOS_RADIUS            86 // set or get
#define RADAR_RADIUS              87 // set or get
#define JAMMER_RADIUS             88 // set or get
#define SONAR_RADIUS              89 // set or get
#define SONAR_JAM_RADIUS          90 // set or get
#define SEISMIC_RADIUS            91 // set or get
#define DO_SEISMIC_PING           92 // get
#define CURRENT_FUEL              93 // set or get
#define TRANSPORT_ID              94 // get
#define SHIELD_POWER              95 // set or get
#define STEALTH                   96 // set or get
#define CRASHING                  97 // set or get, returns whether aircraft isCrashing state
#define CHANGE_TARGET             98 // set, the value it's set to determines the affected weapon
#define CEG_DAMAGE                99 // set
#define COB_ID                   100 // get
#define PLAY_SOUND               101 // get, so multiple args can be passed
#define KILL_UNIT                102 // get KILL_UNIT(unitId, SelfDestruct=true, Reclaimed=false)
#define ALPHA_THRESHOLD          103 // set or get
#define SET_WEAPON_UNIT_TARGET   106 // get (fake set)
#define SET_WEAPON_GROUND_TARGET 107 // get (fake set)

// Indices for SET, GET, and GET_UNIT_VALUE for LUA return values
#define LUA0			110	// (LUA0 returns the lua call status, 0 or 1)
#define LUA1			111
#define LUA2			112
#define LUA3			113
#define LUA4			114
#define LUA5			115
#define LUA6			116
#define LUA7			117
#define LUA8			118
#define LUA9			119

#define FLANK_B_MODE             120 // set or get
#define FLANK_B_DIR              121 // set or get, set is through get for multiple args
#define FLANK_B_MOBILITY_ADD     122 // set or get
#define FLANK_B_MAX_DAMAGE       123 // set or get
#define FLANK_B_MIN_DAMAGE       124 // set or get
#define WEAPON_RELOADSTATE       125 // get (with fake set)
#define WEAPON_RELOADTIME        126 // get (with fake set)
#define WEAPON_ACCURACY          127 // get (with fake set)
#define WEAPON_SPRAY             128 // get (with fake set)
#define WEAPON_RANGE             129 // get (with fake set)
#define WEAPON_PROJECTILE_SPEED  130 // get (with fake set)

// NOTE: shared variables use codes [1024 - 5119]

#endif
