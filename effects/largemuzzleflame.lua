-- large_muzzle_flash_fx

return {
  ["large_muzzle_flash_fx"] = {
    muzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[0.9 0.8 0 0.01 0.9 0.9 0.9 0.01 0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0.25,
        fronttexture       = [[muzzlefront]],
        length             = 32,
        sidetexture        = [[muzzleside]],
        size               = 12,
        sizegrowth         = 0.5,
        ttl                = 4,
      },
    },
    muzzlesmoke = {
      air                = true,
      class              = [[CSmokeProjectile2]],
      count              = 30,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        agespeed           = 0.03125,
        glowfalloff        = 8,
        pos                = [[0, 0, 0]],
        size               = 8,
        speed              = [[r-0.5 r0.5, ri-0.05 ri0.05, r-0.5 r0.5]],
        wantedpos          = [[-8 r16, r8, -8 r16]],
      },
    },
  },

}

