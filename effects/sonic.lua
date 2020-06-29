local fx = {
['sonic'] = {
    groundflash = {
      air                = true,
      underwater         = true,
      circlealpha        = 0.6,
      circlegrowth       = 2,
      flashalpha         = 0.9,
      flashsize          = 20,
      ground             = true,
      ttl                = 10,
      unit                 = true,
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
      unit                 = true,
      underwater         = true,
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
      unit                 = true,
      underwater         = true,
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
    --expand = {
    --  air                = true,
    --  class              = [[heatcloud]],
    --  count              = 1,
    --  ground             = true,
    --  water              = true,
    --  unit                 = true,
    --  underwater         = true,
    --  properties = {
    --    heat               = 96,
    --    heatfalloff        = 16,
    --    maxheat            = 96,
    --    pos                = [[0,0,0]],
    --    size               = 60,
    --    sizegrowth         = -10,
    --    speed              = [[0, 0, 0]],
    --    texture            = [[sonic_glow]],
    --  },
    --},
    airpop = {
      air                = true,
      class              = [[heatcloud]],
      count              = 3,
      ground             = true,
      water              = true,
      unit                 = true,
      properties = {
        heat               = 12,
        heatfalloff        = 1,
        maxheat            = 10,
        pos                = [[-7.5 r15, -7.5 r15, -7.5 r15]],
        size               = 3,
        sizegrowth         = -0.01,
        speed              = [[-1.5 r3, -1.5 r3, -1.5 r3]],
        texture            = [[sonic_glow]],
      },
    },
    waterpop = {
      air                = false,
      class              = [[heatcloud]],
      count              = 3,
      ground             = false,
      water              = true,
      unit                 = false,
      underwater         = true,
      properties = {
        heat               = 11,
        heatfalloff        = 0.5,
        maxheat            = 10,
        pos                = [[-3.5 r7, -3.5 r7, -3.5 r7]],
        size               = 3,
        sizegrowth         = 0.01,
        speed              = [[-0.5 r1, -0.5 r1, -0.5 r1]],
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

local suMergeTable = Spring.Utilities.MergeTable
for cegName, info in pairs(altforms) do
  fx[cegName] = suMergeTable(info.modifications, fx[info.source], true)
end

return fx
