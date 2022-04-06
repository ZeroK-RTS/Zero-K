-- empflash240
-- flashmediumbuildingex
-- empflash20
-- dguntrace
-- burn
-- empflash192
-- missile_explosion
-- flashnuke280
-- pilot
-- red_explosion
-- flashsmallbuilding
-- flashbigbuilding
-- flash64
-- kargmissile_explosion
-- vehhvyrocket_explosion
-- flash2
-- starfire
-- medmissile_explosion
-- bigbomb_explosion3
-- flashsmallbuildingex
-- bigbomb_explosion2
-- flash4
-- bigmissile_explosion
-- flash72
-- flash144
-- flash1nd
-- flash96
-- burnteal
-- flashnuke1280
-- flashnuke480
-- empflash640
-- vsmlmissile_explosion
-- vehrocket_explosion
-- flashnuke960
-- burnpurple
-- flash1
-- flashnuke360
-- flashnuke320
-- flashjuno
-- empflash400
-- aft
-- explodeblue
-- flash224
-- flash3
-- flash2nd
-- flashmediumbuilding
-- flashnuke240
-- flash3blue
-- flash1yellow2
-- bigbomb_explosion
-- blue_explosion (deprecated)
-- flashsmallunit
-- empflash360
-- flashstriderbantha
-- flashmediumunitex
-- flashbigunit
-- purple_explosion
-- pilot2
-- lightarms
-- flashbigunitex
-- flashbigbuildingex
-- purpleimpact2
-- flashnuke1920
-- flash3evul
-- artillery_explosion
-- flash_teal7
-- flashmediumunit
-- purpleimpact1
-- bulletimpact
-- flashantimine
-- flashnuke768
-- flashsmallunitex

return {
  ["empflash240"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1.4,
      circlegrowth       = 7,
      flashalpha         = 0.9,
      flashsize          = 240,
      ttl                = 10,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.89999997615814,
        [3]  = 0,
      },
    },
  },

  ["flashmediumbuildingex"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 2.1,
      circlegrowth       = 6,
      flashalpha         = 1.8,
      flashsize          = 134,
      ttl                = 15,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["empflash20"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1.2,
      circlegrowth       = 4,
      flashalpha         = 0.7,
      flashsize          = 6,
      ttl                = 7,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.89999997615814,
        [3]  = 0,
      },
    },
  },

  ["dguntrace"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 0.35,
      circlegrowth       = 0.001,
      flashalpha         = 3.5,
      flashsize          = 20,
      ttl                = 80,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0.20000000298023,
      },
    },
    heatcloud = {
      air                = true,
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        heat               = 75,
        heatfalloff        = 4,
        maxheat            = 100,
        pos                = [[0, 0, 0]],
        size               = 32,
        sizegrowth         = -1.25,
        speed              = [[dir]],
      },
    },
  },

  ["burn"] = {
    gfx = {
      count              = 25,
      water              = true,
      properties = {
        color              = 200,
        creationtime       = 2,
        lifetime           = 10,
        pos                = [[-5 r5, 0 r10, -5 r5]],
        speed              = [[0.5 r-0.5, 0.7 r5.6, 0.5 r-0.5]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 3,
      flashalpha         = 1,
      flashsize          = 10,
      ttl                = 8,
      color = {
        [1]  = 0.5,
        [2]  = 0.10000000149012,
        [3]  = 0,
      },
    },
    heatcloud = {
      air                = true,
      count              = 6,
      ground             = true,
      properties = {
        heat               = 6,
        heatfalloff        = 2,
        maxheat            = 10,
        pos                = [[-10 r10, r20,-10 r10]],
        size               = 10,
        sizegrowth         = 0.2,
        speed              = [[-1 r2, r2, -1 r2]],
      },
    },
  },

  ["empflash192"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1.4,
      circlegrowth       = 6,
      flashalpha         = 0.8,
      flashsize          = 192,
      ttl                = 10,
      color = {
        [1]  = 0.80000001192093,
        [2]  = 0.89999997615814,
        [3]  = 0.25,
      },
    },
  },

  ["missile_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.6,
      circlegrowth       = 3,
      flashalpha         = 0.9,
      flashsize          = 40,
      ground             = true,
      ttl                = 15,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0.20000000298023,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.4,
        maxheat            = 15,
        pos                = [[-2 r4, 3, -2 r4]],
        size               = 15,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[redexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 5,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[-25 r50, 5, -25 r50]],
        size               = [[10 r-1.5]],
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[explo]],
      },
    },
    smoke = {
      air                = true,
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[-3 r6, -3 r6, -3 r6]],
        size               = 8,
        sizeexpansion      = 0.6,
        speed              = [[0, 1 r2.3, 0]],
        startsize          = 2,
      },
    },
  },

  ["flashnuke280"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 14,
      flashalpha         = 1.8,
      flashsize          = 322,
      ttl                = 15,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["pilot"] = {
    heatcloud = {
      air                = true,
      useairlos       = false,
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        heat               = 27,
        heatfalloff        = 1.5,
        maxheat            = 30,
        pos                = [[0, -1.5, 0]],
        size               = 8,
        sizegrowth         = -0.01,
        speed              = [[0 r1, 1.5 r1, 0 r1]],
        texture            = [[explo]],
      },
    },
  },

  ["red_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.4,
      circlegrowth       = 8,
      flashalpha         = 0.9,
      flashsize          = 70,
      ground             = true,
      ttl                = 20,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0,
      },
    },
    pop = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[0, 0 0, 0]],
        size               = [[35 r-1.5]],
        sizegrowth         = 0.75,
        speed              = [[1 r0.35, 0 0, 1 r0.35]],
        texture            = [[redexplo]],
      },
    },
    smoke = {
      air                = true,
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[0, -1, 0]],
        size               = 30,
        sizeexpansion      = -0.6,
        sizegrowth         = 15,
        speed              = [[0, 1 r1.3, 0]],
        startsize          = 10,
      },
    },
    smoke00 = {
      air                = true,
      class              = [[smoke]],
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[1 r5]],
        sizegrowth         = 1,
        speed              = [[0 r-3, 0, 0 r-3]],
      },
    },
    smoke01 = {
      air                = true,
      class              = [[smoke]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[15 r5]],
        sizegrowth         = 1,
        speed              = [[0 r3, 0, 0 r3]],
      },
    },
    smoke02 = {
      air                = true,
      class              = [[smoke]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[15 r5]],
        sizegrowth         = 1,
        speed              = [[0 r3, 0, 0 r-3]],
      },
    },
    smoke04 = {
      air                = true,
      class              = [[smoke]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[15 r5]],
        sizegrowth         = 1,
        speed              = [[0 r-3, 0, 0 r3]],
      },
    },
  },

  ["flashsmallbuilding"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 2.8,
      circlegrowth       = 12,
      flashalpha         = 2.7,
      flashsize          = 160,
      ttl                = 12,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flashbigbuilding"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 14,
      flashalpha         = 2.9,
      flashsize          = 192,
      ttl                = 14,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flash64"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 4,
      flashalpha         = 1.9,
      flashsize          = 64,
      ttl                = 6,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["kargmissile_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.6,
      circlegrowth       = 1,
      flashalpha         = 0.9,
      flashsize          = 40,
      ground             = true,
      ttl                = 15,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0.20000000298023,
      },
    },
  },

  ["vehhvyrocket_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.6,
      circlegrowth       = 2,
      flashalpha         = 0.9,
      flashsize          = 30,
      ground             = true,
      ttl                = 15,
      water              = true,
      color = {
        [1]  = 0.98400002717972,
        [2]  = 0.68699997663498,
        [3]  = 0.33500000834465,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        heat               = 15,
        heatfalloff        = 0.4,
        maxheat            = 20,
        pos                = [[-2 r4, 6, -2 r4]],
        size               = 20,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[spikeexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 5,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[-25 r50, 5, -25 r50]],
        size               = [[5 r-1.5]],
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[flowexplo]],
      },
    },
    smoke = {
      air                = true,
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[-3 r6, 7, -3 r6]],
        size               = 4,
        sizeexpansion      = 0.6,
        sizegrowth         = 1,
        speed              = [[0, 1 r2.3, 0]],
        startsize          = 1,
      },
    },
  },

  ["flash2"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 2,
      flashalpha         = 1.3,
      flashsize          = 25,
      ttl                = 4,
      color = {
        [1]  = 1,
        [2]  = 0.9,
        [3]  = 0.65,
      },
    },
  },

  ["starfire"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.6,
      circlegrowth       = 1,
      flashalpha         = 0.9,
      flashsize          = 40,
      ground             = true,
      ttl                = 15,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.3,
        [3]  = 0.2,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        heat               = 20,
        heatfalloff        = 0.6,
        maxheat            = 25,
        pos                = [[-2 r4, 8, -2 r4]],
        size               = 15,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[starexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 5,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[-25 r50, 5, -25 r50]],
        size               = [[5 r-1.5]],
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[explo]],
      },
    },
    smoke = {
      air                = true,
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[-3 r6, -3 r6, -3 r6]],
        size               = 4,
        sizeexpansion      = 0.6,
        speed              = [[0, 1 r2.3, 0]],
        startsize          = 1,
      },
    },
  },

  ["medmissile_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.5,
      circlegrowth       = 4,
      flashalpha         = 0.9,
      flashsize          = 70,
      ground             = true,
      ttl                = 17,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 7,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.4,
        maxheat            = 15,
        pos                = [[-2 r4, 3, -2 r4]],
        size               = 20,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[sakexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[-25 r50, 5, -25 r50]],
        size               = [[15 r-1.5]],
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[explo]],
      },
    },
    smoke = {
      air                = true,
      count              = 7,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[-3 r6, -3 r6, -3 r6]],
        size               = 10,
        sizeexpansion      = 0.6,
        speed              = [[0, 1 r2.3, 0]],
        startsize          = 2,
      },
    },
  },

  ["bigbomb_explosion3"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.5,
      circlegrowth       = 1,
      flashalpha         = 0.6,
      flashsize          = 35,
      ground             = true,
      ttl                = 60,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.60000002384186,
        [3]  = 0.40000000596046,
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 20,
        pos                = [[-55 r110, 5, -55 r110]],
        size               = 25,
        sizegrowth         = 0.9,
        speed              = [[-2 r4, 1 0, -2 r4]],
        texture            = [[cloudexplo]],
      },
    },
  },

  ["flashsmallbuildingex"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 0.8,
      circlegrowth       = 4.8,
      flashalpha         = 1.3,
      flashsize          = 128,
      ttl                = 14,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["bigbomb_explosion2"] = {
    dirtypoof = {
      class              = [[dirt]],
      count              = 5,
      ground             = true,
      properties = {
        alphafalloff       = 2,
        color              = [[0.4, 0.2, 0.10]],
        pos                = [[-100 r200, 0, -100 r200]],
        size               = 10,
        speed              = [[0.5 r-1, 2, 0.5 r-1]],
      },
    },
    groundflash = {
      air                = true,
      circlealpha        = 0.5,
      circlegrowth       = 6,
      flashalpha         = 0.8,
      flashsize          = 40,
      ground             = true,
      ttl                = 17,
      water              = true,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.81999999284744,
        [3]  = 0.73000001907349,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 5,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.4,
        maxheat            = 15,
        pos                = [[-2 r4, 3, -2 r4]],
        size               = 25,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[flowexplo]],
      },
    },
  },

  ["flash4"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 4,
      flashalpha         = 1.9,
      flashsize          = 55,
      ttl                = 6,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["bigmissile_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.5,
      circlegrowth       = 6,
      flashalpha         = 0.9,
      flashsize          = 70,
      ground             = true,
      ttl                = 17,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 7,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.4,
        maxheat            = 15,
        pos                = [[-2 r4, 3, -2 r4]],
        size               = 25,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[sparkexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[-25 r50, 5, -25 r50]],
        size               = [[20 r-1.5]],
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[explo]],
      },
    },
    smoke = {
      air                = true,
      count              = 7,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[-3 r6, -3 r6, -3 r6]],
        size               = 15,
        sizeexpansion      = 0.6,
        sizegrowth         = 5,
        speed              = [[0, 1 r2.3, 0]],
        startsize          = 5,
      },
    },
  },

  ["flash72"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 4,
      flashalpha         = 1.9,
      flashsize          = 72,
      ttl                = 6,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["flash144"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 7,
      flashalpha         = 2,
      flashsize          = 144,
      ttl                = 7,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["flash1nd"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 1,
      flashalpha         = 1.1,
      flashsize          = 10,
      ttl                = 3,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["flash96"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 5,
      flashalpha         = 1.9,
      flashsize          = 96,
      ttl                = 7,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["burnteal"] = {
    dirt = {
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alphafalloff       = 3,
        color              = [[0.2, 1.0, 1.0]],
        pos                = [[-10 r20, 0, -10 r20]],
        size               = 15,
        speed              = [[0.75 r-1.5, 1.7 r1.6, 0.75 r-1.5]],
      },
    },
    gfx = {
      count              = 25,
      water              = true,
      properties = {
        color              = 200,
        creationtime       = 2,
        lifetime           = 10,
        pos                = [[-8 r8, 0 r15, -8 r8]],
        speed              = [[0.5 r-0.5, 0.7 r1.6, 0.5 r-0.5]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 3,
      flashalpha         = 1,
      flashsize          = 25,
      ttl                = 8,
      color = {
        [1]  = 0,
        [2]  = 0.5,
        [3]  = 0.5,
      },
    },
  },

  ["flashnuke1280"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 4,
      circlegrowth       = 25,
      flashalpha         = 2.4,
      flashsize          = 1472,
      ttl                = 35,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["flashnuke480"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 14,
      flashalpha         = 2.1,
      flashsize          = 552,
      ttl                = 24,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["empflash640"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 18,
      flashalpha         = 1.2,
      flashsize          = 680,
      ttl                = 35,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.89999997615814,
        [3]  = 0,
      },
    },
  },

  ["vsmlmissile_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.6,
      circlegrowth       = 1,
      flashalpha         = 1.8,
      flashsize          = 20,
      ground             = true,
      ttl                = 15,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.53500002622604,
        [3]  = 0.46799999475479,
      },
    },
  },

  ["vehrocket_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.6,
      circlegrowth       = 0.5,
      flashalpha         = 0.9,
      flashsize          = 15,
      ground             = true,
      ttl                = 15,
      water              = true,
      color = {
        [1]  = 0.98400002717972,
        [2]  = 0.68699997663498,
        [3]  = 0.33500000834465,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        heat               = 15,
        heatfalloff        = 0.8,
        maxheat            = 20,
        pos                = [[-2 r4, 6, -2 r4]],
        size               = 10,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[spikeexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 5,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.4,
        maxheat            = 12,
        pos                = [[-25 r50, 5, -25 r50]],
        size               = 12,
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[flowexplo]],
      },
    },
    smoke = {
      air                = true,
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[-3 r6, 7, -3 r6]],
        size               = 4,
        sizeexpansion      = 0.6,
        sizegrowth         = 1,
        speed              = [[0, 1 r2.3, 0]],
        startsize          = 1,
      },
    },
  },

  ["flashnuke960"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 20,
      flashalpha         = 2.3,
      flashsize          = 1104,
      ttl                = 30,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["burnpurple"] = {
    dirt = {
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alphafalloff       = 3,
        color              = [[0.8, 0.1, 0.8]],
        pos                = [[-10 r20, 0, -10 r20]],
        speed              = [[0.75 r-1.5, 1.7 r1.6, 0.75 r-1.5]],
      },
    },
    gfx = {
      count              = 25,
      water              = true,
      properties = {
        color              = 200,
        creationtime       = 2,
        lifetime           = 10,
        pos                = [[-8 r8, 0 r15, -8 r8]],
        speed              = [[0.5 r-0.5, 0.7 r1.6, 0.5 r-0.5]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 3,
      flashalpha         = 1,
      flashsize          = 10,
      ttl                = 8,
      color = {
        [1]  = 0.5,
        [2]  = 0,
        [3]  = 0.5,
      },
    },
    heatcloud = {
      air                = true,
      count              = 6,
      ground             = true,
      properties = {
        heat               = 6,
        heatfalloff        = 2,
        maxheat            = 10,
        pos                = [[-10 r10, r10,-10 r10]],
        size               = 10,
        sizegrowth         = -0.2,
        speed              = [[-1 r2, r2, -1 r2]],
      },
    },
  },

  ["flash1"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 1,
      flashalpha         = 1.1,
      flashsize          = 10,
      ttl                = 3,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["flashnuke360"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 11,
      flashalpha         = 2,
      flashsize          = 414,
      ttl                = 21,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["flashnuke320"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 16,
      flashalpha         = 1.9,
      flashsize          = 368,
      ttl                = 18,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["flashjuno"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 0.7,
      circlegrowth       = 30,
      flashalpha         = 2,
      flashsize          = 1472,
      ttl                = 60,
      color = {
        [1]  = 0.69999998807907,
        [2]  = 0.89999997615814,
        [3]  = 0.55000001192093,
      },
    },
  },

  ["empflash400"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1.8,
      circlegrowth       = 11,
      flashalpha         = 1.1,
      flashsize          = 400,
      ttl                = 10,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.89999997615814,
        [3]  = 0,
      },
    },
  },

  ["aft"] = {
    heatcloud = {
      air                = true,
      count              = 1,
      ground             = false,
      water              = true,
      properties = {
        heat               = 75,
        heatfalloff        = 3,
        maxheat            = 100,
        pos                = [[0, 0, 0]],
        size               = 4,
        sizegrowth         = -0.25,
        speed              = [[0, 0, 0 r0.5]],
      },
    },
    smoke2 = {
      air                = true,
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        glowfalloff        = 10,
        pos                = [[0, 0, 0]],
        size               = 4,
        sizegrowth         = 2,
        speed              = [[-0.5 r1,-0.5 r1,-0.5 r1]],
      },
    },
  },

  ["explodeblue"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 3,
      flashalpha         = 1,
      flashsize          = 25,
      ttl                = 8,
      color = {
        [1]  = 0.20000000298023,
        [2]  = 0.20000000298023,
        [3]  = 0.5,
      },
    },
  },

  ["flash224"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 14,
      flashalpha         = 2.3,
      flashsize          = 200,
      ttl                = 14,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flash3"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 3,
      flashalpha         = 1.6,
      flashsize          = 40,
      ttl                = 5,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["flash2nd"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 2,
      flashalpha         = 1.3,
      flashsize          = 25,
      ttl                = 4,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.64999997615814,
      },
    },
  },

  ["flashmediumbuilding"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 2.9,
      circlegrowth       = 13,
      flashalpha         = 2.8,
      flashsize          = 172,
      ttl                = 13,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flashnuke240"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 14,
      flashalpha         = 1.8,
      flashsize          = 260,
      ttl                = 15,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["flash3blue"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 3,
      flashalpha         = 1.6,
      flashsize          = 40,
      ttl                = 5,
      color = {
        [1]  = 0.30000001192093,
        [2]  = 0.30000001192093,
        [3]  = 1,
      },
    },
  },

  ["flash1yellow2"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 1,
      flashalpha         = 1.3,
      flashsize          = 7,
      ttl                = 3,
      color = {
        [1]  = 1,
        [2]  = 1,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["bigbomb_explosion"] = {
    dirtypoof = {
      class              = [[dirt]],
      count              = 15,
      ground             = true,
      properties = {
        alphafalloff       = 2,
        color              = [[0.2, 0.1, 0.05]],
        pos                = [[-100 r200, 0, -100 r200]],
        size               = 5,
        speed              = [[0.5 r-1, 2, 0.5 r-1]],
      },
    },
    groundflash = {
      air                = true,
      circlealpha        = 0.5,
      circlegrowth       = 4,
      flashalpha         = 0.6,
      flashsize          = 35,
      ground             = true,
      ttl                = 14,
      water              = true,
      color = {
        [1]  = 0.60000002384186,
        [2]  = 0.5,
        [3]  = 0.46999999880791,
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[-55 r110, 5, -55 r110]],
        size               = [[20 r-1.5]],
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[flowexplo]],
      },
    },
  },

--  ["blue_explosion"] = {
--    generatorpop1 = {
--      air                = true,
--      class              = [[heatcloud]],
--      count              = 2,
--      ground             = true,
--      water              = true,
--      properties = {
--        heat               = 18,
--        heatfalloff        = 0.8,
--        maxheat            = 18,
--        pos                = [[0, 0 0, 0]],
--        size               = 60,
--        sizegrowth         = -0.2,
--        speed              = [[0.35 r-0.7, 0 0, 0.35 r-0.7]],
--        texture            = [[brightblueexplo]],
--      },
--    },
--    generatorpop2 = {
--      air                = true,
--      class              = [[heatcloud]],
--      count              = 2,
--      ground             = true,
--      water              = true,
--      properties = {
--        heat               = 10,
--        heatfalloff        = 0.7,
--        maxheat            = 15,
--        pos                = [[0, 0 0, 0]],
--        size               = 50,
--        sizegrowth         = -0.2,
--        speed              = [[1 r0.35, 0 0, 1 r0.35]],
--        texture            = [[blueexplo]],
--      },
--    },
--    groundflash = {
--      air                = true,
--      circlealpha        = 0.4,
--      circlegrowth       = 5,
--      flashalpha         = 0.9,
--      flashsize          = 110,
--      ground             = true,
--      ttl                = 20,
--      water              = true,
--      color = {
--        [1]  = 0.10000000149012,
--        [2]  = 0.10000000149012,
--        [3]  = 1,
--      },
--    },
--    smoke = {
--      air                = true,
--      count              = 8,
--      ground             = true,
--      water              = true,
--      properties = {
--        agespeed           = 0.04,
--        color              = 0.1,
--        pos                = [[0, -1, 0]],
--        size               = 30,
--        sizeexpansion      = -0.6,
--        sizegrowth         = 15,
--        speed              = [[0, 1 r1.3, 0]],
--        startsize          = 10,
--      },
--    },
--    smoke00 = {
--      air                = true,
--      class              = [[smoke]],
--      count              = 10,
--      ground             = true,
--      water              = true,
--      properties = {
--        agespeed           = 0.08,
--        color              = [[0.3 r0.3]],
--        pos                = [[0, 0 r4, 0]],
--        size               = [[15 r5]],
--        sizegrowth         = 1,
--        speed              = [[0 r-3, 0, 0 r-3]],
--      },
--    },
--    smoke01 = {
--      air                = true,
--      class              = [[smoke]],
--      count              = 10,
--      ground             = true,
--      water              = true,
--      properties = {
--        agespeed           = 0.08,
--        color              = [[0.3 r0.3]],
--        pos                = [[0, 0 r4, 0]],
--        size               = [[15 r5]],
--        sizegrowth         = 1,
--        speed              = [[0 r3, 0, 0 r3]],
--      },
--    },
--    smoke02 = {
--      air                = true,
--      class              = [[smoke]],
--      count              = 10,
--      ground             = true,
--      water              = true,
--      properties = {
--        agespeed           = 0.08,
--        color              = [[0.3 r0.3]],
--        pos                = [[0, 0 r4, 0]],
--        size               = [[15 r5]],
--        sizegrowth         = 1,
--        speed              = [[0 r3, 0, 0 r-3]],
--      },
--    },
--    smoke04 = {
--      air                = true,
--      class              = [[smoke]],
--      count              = 10,
--      ground             = true,
--      water              = true,
--      properties = {
--        agespeed           = 0.08,
--        color              = [[0.3 r0.3]],
--        pos                = [[0, 0 r4, 0]],
--        size               = [[15 r5]],
--        sizegrowth         = 1,
--        speed              = [[0 r-3, 0, 0 r3]],
--      },
--    },
--  },

  ["flashsmallunit"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 7,
      flashalpha         = 2.5,
      flashsize          = 72,
      ttl                = 7,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["empflash360"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1.6,
      circlegrowth       = 10,
      flashalpha         = 1,
      flashsize          = 360,
      ttl                = 10,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.89999997615814,
        [3]  = 0,
      },
    },
  },

  ["flashstriderbantha"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 2.2,
      circlegrowth       = 5,
      flashalpha         = 1.9,
      flashsize          = 38,
      ttl                = 6,
      color = {
        [1]  = 0.20000000298023,
        [2]  = 0.20000000298023,
        [3]  = 0.94999998807907,
      },
    },
  },

  ["flashmediumunitex"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 5,
      flashalpha         = 2.075,
      flashsize          = 64,
      ttl                = 5,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flashbigunit"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 4,
      flashalpha         = 2.65,
      flashsize          = 80,
      ttl                = 13,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["purple_explosion"] = {
    generatorpop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        heat               = 18,
        heatfalloff        = 0.8,
        maxheat            = 18,
        pos                = [[0, 0 0, 0]],
        size               = 60,
        sizegrowth         = -0.2,
        speed              = [[0.35 r-0.7, 0 0, 0.35 r-0.7]],
        texture            = [[purpleexplo]],
      },
    },
    generatorpop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.7,
        maxheat            = 15,
        pos                = [[0, 0 0, 0]],
        size               = 50,
        sizegrowth         = -0.2,
        speed              = [[1 r0.35, 0 0, 1 r0.35]],
        texture            = [[pinkexplo]],
      },
    },
    groundflash = {
      air                = true,
      circlealpha        = 0.4,
      circlegrowth       = 5,
      flashalpha         = 0.9,
      flashsize          = 110,
      ground             = true,
      ttl                = 20,
      water              = true,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.10000000149012,
        [3]  = 0.89999997615814,
      },
    },
    smoke = {
      air                = true,
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[0, -1, 0]],
        size               = 30,
        sizeexpansion      = -0.6,
        sizegrowth         = 15,
        speed              = [[0, 1 r1.3, 0]],
        startsize          = 10,
      },
    },
    smoke00 = {
      air                = true,
      class              = [[smoke]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[15 r5]],
        sizegrowth         = 1,
        speed              = [[0 r-3, 0, 0 r-3]],
      },
    },
    smoke01 = {
      air                = true,
      class              = [[smoke]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[15 r5]],
        sizegrowth         = 1,
        speed              = [[0 r3, 0, 0 r3]],
      },
    },
    smoke02 = {
      air                = true,
      class              = [[smoke]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[15 r5]],
        sizegrowth         = 1,
        speed              = [[0 r3, 0, 0 r-3]],
      },
    },
    smoke04 = {
      air                = true,
      class              = [[smoke]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.08,
        color              = [[0.3 r0.3]],
        pos                = [[0, 0 r4, 0]],
        size               = [[15 r5]],
        sizegrowth         = 1,
        speed              = [[0 r-3, 0, 0 r3]],
      },
    },
  },

  ["pilot2"] = {
    heatcloud = {
      air                = true,
      useairlos       = false,
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        heat               = 27,
        heatfalloff        = 1,
        maxheat            = 30,
        pos                = [[0, -1.5, 0]],
        size               = 7,
        sizegrowth         = -0.01,
        speed              = [[0 r0.3, 1.5 r0.5, 0 r0.3]],
        texture            = [[explo]],
      },
    },
  },

  ["lightarms"] = {
    groundflash = {
      circlealpha        = 0.35,
      circlegrowth       = 0.001,
      flashalpha         = 1.5,
      flashsize          = 12,
      ttl                = 14,
      color = {
        [1]  = 0.99599999189377,
        [2]  = 0.98000001907349,
        [3]  = 0.56599998474121,
      },
    },
  },

  ["flashbigunitex"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 5.5,
      flashalpha         = 2,
      flashsize          = 68,
      ttl                = 7,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flashbigbuildingex"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 2.2,
      circlegrowth       = 11,
      flashalpha         = 2.3,
      flashsize          = 144,
      ttl                = 11,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flashnuke1920"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 4,
      circlegrowth       = 30,
      flashalpha         = 2.5,
      flashsize          = 2208,
      ttl                = 40,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["flash3evul"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 3,
      flashalpha         = 1.6,
      flashsize          = 40,
      ttl                = 5,
      color = {
        [1]  = 0.89999997615814,
        [2]  = 0.80000001192093,
        [3]  = 0.20000000298023,
      },
    },
  },

  ["artillery_explosion"] = {
    groundflash = {
      air                = true,
      circlealpha        = 0.6,
      circlegrowth       = 8,
      flashalpha         = 0.9,
      flashsize          = 70,
      ground             = true,
      ttl                = 20,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.4,
        maxheat            = 15,
        pos                = [[-2 r4, 3, -2 r4]],
        size               = 55,
        sizegrowth         = 0.9,
        speed              = [[0, 1 0, 0]],
        texture            = [[redexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 5,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[-25 r50 5, -25 r50]],
        size               = [[45 r-1.5]],
        sizegrowth         = 0.9,
        speed              = [[-1 r2, 1 0, -1 r2]],
        texture            = [[explo]],
      },
    },
    smoke = {
      air                = true,
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        agespeed           = 0.04,
        color              = 0.1,
        pos                = [[-3 r6, -3 r6, -3 r6]],
        size               = 40,
        sizeexpansion      = 0.6,
        sizegrowth         = 15,
        speed              = [[0, 1 r2.3, 0]],
        startsize          = 10,
      },
    },
  },

  ["flash_teal7"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 1,
      flashalpha         = 1.3,
      flashsize          = 7,
      ttl                = 3,
      color = {
        [1]  = 0,
        [2]  = 1,
        [3]  = 1,
      },
    },
  },

  ["flashmediumunit"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 7,
      flashalpha         = 2.575,
      flashsize          = 76,
      ttl                = 7,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["bulletimpact"] = {
    dirt = {
      count              = 5,
      ground             = true,
      properties = {
        alphafalloff       = 2,
        color              = [[0.2, 0.1, 0.05]],
        pos                = [[-10 r20, 0, -10 r20]],
        size               = 10,
        speed              = [[0.75 r-1.5, 1.7 r1.6, 0.75 r-1.5]],
      },
    },
    gfx = {
      count              = 25,
      water              = true,
      properties = {
        color              = 200,
        creationtime       = 2,
        lifetime           = 10,
        pos                = [[-5 r20, 0 r10, -5 r20]],
        speed              = [[0.5 r-1.5, 0.7 r5.6, 0.5 r-1.5]],
      },
    },
  },

  ["flashantimine"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 2,
      circlegrowth       = 16,
      flashalpha         = 1,
      flashsize          = 720,
      ttl                = 26,
      color = {
        [1]  = 1,
        [2]  = 1,
        [3]  = 0.60000002384186,
      },
    },
  },

  ["flashnuke768"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 3,
      circlegrowth       = 17,
      flashalpha         = 2.2,
      flashsize          = 883,
      ttl                = 27,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.69999998807907,
      },
    },
  },

  ["flashsmallunitex"] = {
    usedefaultexplosions = true,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 4.8,
      flashalpha         = 1.3,
      flashsize          = 60,
      ttl                = 6,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.60000002384186,
      },
    },
  },

}

