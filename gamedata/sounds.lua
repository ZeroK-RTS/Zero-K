-- $Id$
--- Valid entries used by engine: IncomingChat, MultiSelect, MapPoint
--- other than that, you can give it any name and access it like before with filenames
local Sounds = {
   SoundItems = {
      IncomingChat = {
         file = "sounds/talk.wav",
      },
      --MultiSelect = {
      --   file = "sounds/button9.wav",
      --},
      MapPoint = {
         file = "sounds/marker_place.wav",
      },
--[[
      MyAwesomeSounds = {
         file = "sounds/booooom.wav",
         gain = 2.0, --- for uber-loudness
         pitch = 0.2, --- bass-test
         priority = 15, --- very high
         maxconcurrent = 1, ---only once
         maxdist = 500, --- only when near
         preload = true, --- you got it
         in3d = true,
         looptime = "1000", --- in miliseconds, can / will be stopped like regular items
 MapEntryValExtract(items, "dopplerscale", dopplerScale);
  MapEntryValExtract(items, "rolloff", rolloff);
      },
--]]
      DefaultsForSounds = { -- this are default settings
         file = "ThisEntryMustBePresent.wav",
         gain = 1.0,
         pitch = 1.0,
         priority = 0,
         maxconcurrent = 4, --- some reasonable limits
         maxdist = FLT_MAX, --- no cutoff at all
      },
	  Sparks = {
         file = "sounds/sparks.wav",
         priority = -10,
         maxconcurrent = 1,
         maxdist = 1000,
         preload = false,
         in3d = true,
         rolloff = 4,
      },
   },
}

return Sounds