-- default
-- none

local effects = {
  ["default"] = {
    usedefaultexplosions = true,
  },

  ["none"] = {
  },

}

for i = 0, 32 do
	effects["none" .. i] = {
	--muzzleflame = {
    --  air                = true,
    --  class              = [[CBitmapMuzzleFlame]],
    --  count              = i,
    --  ground             = true,
    --  underwater         = 1,
    --  water              = true,
    --  properties = {
    --    colormap           = [[0.9 0.8 0 0.01 0.9 0.9 0.9 0.01 0 0 0 0.01]],
    --    dir                = [[dir]],
	--	pos                = [[0 i60, 0, 0]],
    --    frontoffset        = 0.25,
    --    fronttexture       = [[muzzlefront]],
    --    length             = 32,
    --    sidetexture        = [[muzzleside]],
    --    size               = 12,
    --    sizegrowth         = 0.5,
    --    ttl                = 20,
    --  },
    --},
	}
end

return effects