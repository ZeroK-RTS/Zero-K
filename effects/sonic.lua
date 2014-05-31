Spring = Spring or {}
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/tablefunctions.lua")

local fx = {
['sonic'] = {
    groundflash = {
      air                = false,
      underwater		 = true,
      circlealpha        = 0.6,
      circlegrowth       = 2,
      flashalpha         = 0.9,
      flashsize          = 20,
      ground             = true,
      ttl                = 10,
      water              = true,
      color = {
        [1]  = 0,
        [2]  = 0.60000001192093,
        [3]  = 1,
      },
    },
    expand = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      unit				 = true,
      underwater		 = true,
      properties = {
        heat               = 30,
        heatfalloff        = 4,
        maxheat            = 30,
        pos                = [[0,0,0]],
        size               = 20,
        sizegrowth         = 6,
        speed              = [[0, 0, 0]],
        texture            = [[sonic_glow]],
      },
    },
    contract = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      unit				 = true,
      underwater		 = true,
      properties = {
        heat               = 30,
        heatfalloff        = 2,
        maxheat            = 30,
        pos                = [[0,0,0]],
        size               = 20,
        sizegrowth         = -6,
        speed              = [[0, 0, 0]],
        texture            = [[sonic_glow]],
      },
    },
},

['sonictrail'] = {
    expand = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      unit				 = true,
      underwater		 = true,
      properties = {
        heat               = 100,
        heatfalloff        = 15,
        maxheat            = 100,
        pos                = [[0,0,0]],
        size               = 20,
        sizegrowth         = -5,
        speed              = [[0, 0, 0]],
        texture            = [[sonic_glow]],
      },
    },
    airpop = {
      air                = true,
      class              = [[heatcloud]],
      count              = 3,
      ground             = true,
      water              = true,
      unit				 = true,
      properties = {
        heat               = 18,
        heatfalloff        = 0.6,
        maxheat            = 15,
        pos                = [[-5 r10, -5 r10, -5 r10]],
        size               = 3,
        sizegrowth         = -0.01,
        speed              = [[0, 0, 0]],
        texture            = [[sonic_glow]],
      },
    },
    waterpop = {
      air                = false,
      class              = [[heatcloud]],
      count              = 3,
      ground             = false,
      water              = true,
      unit				 = false,
      underwater		 = true,
      properties = {
        heat               = 18,
        heatfalloff        = 0.4,
        maxheat            = 15,
        pos                = [[-5 r10, -5 r10, -5 r10]],
        size               = 3,
        sizegrowth         = 0.01,
        speed              = [[0, 0, 0]],
        texture            = [[sonic_glow]],
      },
    },
  },
}

local altforms = {
  sonic_80 = {
    source = "sonic",
    modifications = {
      groundflash = {
	properties = {flashsize = 80},
      },
      expand = {
	 properties = {size = 80, sizegrowth = 24},
      },
      contract = {
	 properties = {size = 80, sizegrowth = -24},
      }, 
    },
  },
}

for cegName, info in pairs(altforms) do
  fx[cegName] = Spring.Utilities.MergeTable(info.modifications, fx[info.source], true)
end

return fx
