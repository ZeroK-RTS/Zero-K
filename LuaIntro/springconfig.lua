--------------------------------------------------------------------------------------------
--- set some spring settings before the game/engine is really loaded yet
--------------------------------------------------------------------------------------------

-- set default unit rendering vars
Spring.SetConfigFloat("tonemapA", 4.75)
Spring.SetConfigFloat("tonemapB", 0.75)
Spring.SetConfigFloat("tonemapC", 3.5)
Spring.SetConfigFloat("tonemapD", 0.85)
Spring.SetConfigFloat("tonemapE", 1.0)
Spring.SetConfigFloat("envAmbient", 0.25)
Spring.SetConfigFloat("unitSunMult", 1.0)
Spring.SetConfigFloat("unitExposureMult", 1.0)
Spring.SetConfigFloat("modelGamma", 1.0)

-- Sets necessary spring configuration parameters, so shaded units look the way they should (pbr gadget also does this)
Spring.SetConfigInt("CubeTexGenerateMipMaps", 1)
Spring.SetConfigInt("CubeTexSizeReflection", 1024)

-- disable grass
Spring.SetConfigInt("GrassDetail", 0)

-- Revert BAR breaking the small font (which it doesn't seem to even draw anywhere)
Spring.SetConfigInt("SmallFontSize", 14) -- Engine default
Spring.SetConfigInt("UnitIconsAsUI", 0)
