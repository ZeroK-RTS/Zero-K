local MergeTable = Spring.Utilities.MergeTable

local fx = {
    flame_heat = {
      class        = 'JitterParticles2',
      colormap     = { {1,1,1,1},{1,1,1,1} },
      count        = 6,
      life         = 24,
      delaySpread  = 25,
      force        = {0,1.5,0},
      --forceExp     = 0.2,

      emitRotSpread= 10,

      speed        = 10,
      speedSpread  = 0,
      speedExp     = 1.5,

      size         = 15,
      sizeGrowth   = 5.0,

      scale        = 1.5,
      strength     = 1.0,
      heat         = 2,
    },

    flame1 = {
      class        = 'SimpleParticles2',
      colormap     = { {1, 1, 1, 0.01},
                       {1, 1, 1, 0.01},
                       {0.75, 0.5, 0.5, 0.01},
                       {0.35, 0.15, 0.15, 0.25},
                       {0.1, 0.035, 0.01, 0.2},
                       {0, 0, 0, 0.01} },
      count        = 4,
      life         = 24,
      delaySpread  = 25,

      force        = {0,1,0},
      --forceExp     = 0.2,

      emitRotSpread= 8,

      rotSpeed     = 1,
      rotSpread    = 360,
      rotExp       = 9,

      --speed        = 10,
      --speedSpread  = 0,
      --speedExp     = 1.5,

      size         = 2,
      sizeGrowth   = 4.0,
      sizeExp      = 0.7,

      --texture     = "bitmaps/smoke/smoke06.tga",
      texture     = altFlameTexture and "bitmaps/GPL/flame_alt.png" or "bitmaps/GPL/flame.png",
    },

    flame2 = {
      class        = 'SimpleParticles2',
      colormap     = { {1, 1, 1, 0.01}, {0, 0, 0, 0.01} },
      count        = 20,
      --delay        = 20,
      life         = 6,
      lifeSpread   = 20,
      delaySpread  = 15,

      force        = {0,1,0},
      --forceExp     = 0.2,

      emitRotSpread= 3,

      rotSpeed     = 1,
      rotSpread    = 360,
      rotExp       = 9,

      --speed        = 10,
      --speedSpread  = 0,

      size         = 2,
      sizeGrowth   = 4.0,
      sizeExp      = 0.65,

      --texture     = "bitmaps/smoke/smoke06.tga",
      texture     = altFlameTexture and "bitmaps/GPL/flame_alt.png" or "bitmaps/GPL/flame.png",
    },
}


local tbl = {
	--[[
	corpyro_flamethrower = {
		{class = "JitterParticles2", options = fx.flame_heat},
		{class = "SimpleParticles2", options = fx.flame1},
		{class = "SimpleParticles2", options = fx.flame2},
	},
	]]--
}
local tbl2 = {}

for weaponName, data in pairs(tbl) do
  local weaponDef = WeaponDefNames[weaponName] or {}
  local weaponID = weaponDef.id
  if weaponID then
    tbl2[weaponID] = data
  end
end

return tbl2