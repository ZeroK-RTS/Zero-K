-- $Id: deployment.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    LuaRules/Configs/deployment.lua
--  brief:   LuaRules deployment mode configuration
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local noCustomBuilds = true


local deployment = {

  maxFrames = 50 * Game.gameSpeed,

  maxUnits  = 300,

  maxMetal  = 1000,
  maxEnergy = 1000,

  maxRadius = 512,

  maxAutoBuildLevels = 2,

  customBuilds = {

    ['armcom'] = {
      allow = {
        --'armcom',
        --'armmav',
      },
      forbid = {},
    },

    ['corcom'] = {
      allow = {
        --'corcom',
        --'corpyro',
      },
      forbid = {},
    },
  },
}


if (noCustomBuilds) then
  deployment.customBuilds = {}  -- FIXME --
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return deployment

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
