-- $Id: movedefs.lua 3518 2008-12-23 08:46:54Z saktoth $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    moveDefs.lua
--  brief:   move data definitions
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local moveDefs = {

	KBOT1 = {
		footprintx = 1,
		footprintz = 1,
		maxwaterdepth = 15,
		maxslope = 36,
		crushstrength = 5,
	},

	KBOT2 = {
		footprintx = 2,
		footprintz = 2,
		maxwaterdepth = 22,
		maxslope = 36,
		crushstrength = 50,
	},

	KBOT4 = {
		footprintx = 4,
		footprintz = 4,
		maxwaterdepth = 22,
		maxslope = 36,
		crushstrength = 500,
	},
	
	AKBOT2 = {
		footprintx = 2,
		footprintz = 2,
		maxwaterdepth = 5000,
		depthmod = 0,
		maxslope = 36,
		crushstrength = 50,
	},
	
	AKBOT3 = {
		footprintx = 2,
		footprintz = 2,
		maxwaterdepth = 5000,
		depthmod = 0,
		maxslope = 36,
		crushstrength = 150,
	},
	
	AKBOT6 = {
		footprintx = 6,
		footprintz = 6,
		maxwaterdepth = 5000,
		depthmod = 0,
		maxslope = 36,
		crushstrength = 5000,
	},
	
	TKBOT1 = {
		footprintx = 1,
		footprintz = 1,
		maxwaterdepth = 15,
		maxslope = 55,
		crushstrength = 5,
	},

	TKBOT3 = {
		footprintx = 3,
		footprintz = 3,
		maxwaterdepth = 22,
		maxslope = 55,
		crushstrength = 150,
	},
	
	TKBOT4 = {
		footprintx = 3,
		footprintz = 3,
		maxwaterdepth = 22,
		maxslope = 55,
		crushstrength = 500,
	},

	ATKBOT3 = {
		footprintx = 3,
		footprintz = 3,
		maxwaterdepth = 5000,
		maxslope = 55,
		crushstrength = 150,
	},
	
	TANK2 = {
		footprintx = 2,
		footprintz = 2,
		maxwaterdepth = 22,
		maxslope = 18,
		crushstrength = 50,
	},
	
	TANK3 = {
		footprintx = 3,
		footprintz = 3,
		maxwaterdepth = 22,
		maxslope = 18,
		crushstrength = 150,
	},

	TANK4 = {
		footprintx = 4,
		footprintz = 4,
		maxwaterdepth = 22,
		maxslope = 18,
		crushstrength = 500,
	},
	
	HOVER3 = {
		footprintx = 3,
		footprintz = 3,
		maxslope = 18,
		maxwaterdepth = 5000,
		slopemod = 60,
		crushstrength = 5,
	},

	BHOVER3 = {
		footprintx = 3,
		footprintz = 3,
		maxslope = 36,
		maxwaterdepth = 5000,
		--slopemod = 60,
		crushstrength = 150,
	},
	
	BOAT3 = {
		footprintx = 3,
		footprintz = 3,
		minwaterdepth = 5,
		crushstrength = 150,
	},

	BOAT4 = {
		footprintx = 4,
		footprintz = 4,
		minwaterdepth = 10,
		crushstrength = 500,
	},
	
	BOAT6 = {
		footprintx = 6,
		footprintz = 6,
		minwaterdepth = 15,
		crushstrength = 5000,
	},
	
	UBOAT3 = {
		footprintx = 3,
		footprintz = 3,
		minwaterdepth = 15,
		crushstrength = 5,
		subMarine = 1,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- convert from map format to the expected array format

local array = {}
local i = 1
for k,v in pairs(moveDefs) do
	v.heatmapping = false -- disable heatmapping
	array[i] = v
	v.name = k
	i = i + 1
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return array

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
