local fx = {
['sonic'] = {
    groundflash = {
      air                = true,
      underwater         = true,
      circlealpha        = 0.65,
      circlegrowth       = 4.7,
      flashalpha         = 0.92,
      flashsize          = 20,
      ground             = true,
      ttl                = 12,
      unit               = true,
      water              = true,
      color = {
        [1]  = 0,
        [2]  = 0.55,
        [3]  = 0.96,
      },
    },
    expand = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      unit               = true,
      underwater         = true,
      properties = {
        heat               = 30,
        heatfalloff        = 3.5,
        maxheat            = 30,
        pos                = [[0,4,0]],
        size               = 16,
        sizegrowth         = 16,
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
      unit               = true,
      underwater         = true,
      properties = {
        heat               = 30,
        heatfalloff        = 2.5,
        maxheat            = 30,
        pos                = [[0,4,0]],
        size               = 64,
        sizegrowth         = -16,
        speed              = [[0, 0, 0]],
        texture            = [[sonic_glow]],
      },
    },
},

['sonicfire'] = {
    expand = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      unit                 = true,
      underwater         = true,
      properties = {
        heat               = 96,
        heatfalloff        = 24,
        maxheat            = 96,
        pos                = [[0,0,0]],
        size               = 10,
        sizegrowth         = 8,
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
      count              = 2,
      ground             = true,
      water              = true,
      unit               = true,
      properties = {
        heat               = 10,
        heatfalloff        = 1,
        maxheat            = 10,
        pos                = [[-7.5 r15, -7.5 r15, -7.5 r15]],
        size               = 7,
        sizegrowth         = -0.01,
        speed              = [[-1.5 r3, -1.5 r3, -1.5 r3]],
        texture            = [[sonic_glow]],
      },
    },
    waterpop = {
      air                = false,
      class              = [[heatcloud]],
      count              = 2,
      ground             = false,
      water              = true,
      unit               = false,
      underwater         = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.4,
        maxheat            = 10,
        pos                = [[-3.5 r7, -3.5 r7, -3.5 r7]],
        size               = 7,
        sizegrowth         = 0.01,
        speed              = [[-0.4 r0.8, -0.4 r0.8, -0.4 r0.8]],
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
       ttl = 18,
      },
      expand = {
        properties = {size = 16, sizegrowth = 16, heat = 45, maxheat = 45},
      },
      contract = {
        properties = {size = 90, sizegrowth = -16, heat = 45, maxheat = 45},
      },
    },
  },
  sonicfire_80 = {
    source = "sonicfire",
    modifications = {
      expand = {
        properties = {size = 10, sizegrowth = 12, heat = 120, maxheat = 120},
      },
    },
  },
  sonicarcher = {
    source = "sonictrail",
    modifications = {
      airpop = {
        properties = {size = 5,},
      },
      waterpop = {
        properties = {size = 5,},
      },
    },
  },
}

local suMergeTable = Spring.Utilities.MergeTable
for cegName, info in pairs(altforms) do
  fx[cegName] = suMergeTable(info.modifications, fx[info.source], true)
end

return fx
