-- $Id: ValidMaps.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  ValidMaps.lua
--
--  This file can be added to a mod to dictate which maps
--  can (and can not) be used with it. The map information
--  is the map's default information, and is done before
--  MapOptions.lua can be used by maps.
-- 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Map specific call-outs:
--
--   Spring.GetMapList() -> { 'map1.smf', 'map2.smf', 'map3.sm3', etc... }
--  
--   Spring.GetMapInfo('map1') -> {
--     author  = 'string',
--     desc    = 'string',
--     mapX    = number,
--     mapY    = number,
--     tidal   = number,
--     gravity = number,
--     metal   = number,
--     windMin = number,
--     windMax = number,
--     extractorRadius = number,
--     startPos = {
--       [1] = { x = number, z = number },
--       [2] = { x = number, z = number },
--       [3] = { x = number, z = number },
--       etc ...
--     },
--   }
-- 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Example filtering code
--

if (false) then
  local mapList = Spring.GetMapList()
  local validMaps = {}
  for _, mapName in ipairs(mapList) do
    if (mapName:lower():find('metal')) then
      local mapInfo = Spring.GetMapInfo(mapName)
      local minX = (16 * 512)
      local minY = (8  * 512)
      if ((mapInfo.mapX >= minX) and
          (mapInfo.mapY >= minY)) then
        validMaps[#validMaps + 1] = mapName
      end
    end
  end
  if (#validMaps == 0) then
    return { 'FAKEMAP' }
  else 
    return validMaps
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return {}  --  returning an empty table means  *ALL MAPS*  are valid
           --  for *NO MAPS*, return a fake map name, ex: { 'FakeMap' }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
