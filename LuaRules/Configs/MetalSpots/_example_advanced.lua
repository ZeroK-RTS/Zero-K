-- Advanced example.
-- Specify a bunch of convenience classes, and modify layout based on game setup.

local    BIG = 3.5
local NORMAL = 2.0
local  SMALL = 1.25

local spots = {
	{ x = 1234, z =  567, metal = NORMAL },
	{ x =  333, z =  444, metal = NORMAL },
	{ x = 4321, z =  765, metal = NORMAL },
	{ x =  444, z =  333, metal = NORMAL },
	{ x = 1111, z = 2222, metal = BIG    },
	{ x = 3333, z = 4444, metal = BIG    },
	{ x =  555, z =  666, metal = SMALL  },
	{ x =  777, z =  888, metal = SMALL  },
}

-- example: for big teams, add a supermex in the very middle, scaling with game size
if Spring.Utilities.Gametype.isBigTeams() then
	spots[#spots+1] = {
		x = Game.mapSizeX / 2,
		z = Game.mapSizeZ / 2,
		metal = #Spring.GetPlayerList(),
	}
end

return { spots = spots }
