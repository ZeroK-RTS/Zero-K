-- see http://springrts.com/wiki/Sounds.lua for help
local Sounds = {
	SoundItems = {
		--default = {
		--pitchMod = 0.04,
		--}
		IncomingChat = {
			--file = "sounds/talk.wav",
			file = nil,
		},
		--MultiSelect = {
		--   file = "sounds/button9.wav",
		--},
		MapPoint = {
			file = "sounds/beep4_decrackled.wav",
			maxconcurrent = 3,
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
		BladeSwing = {
			file = "sounds/weapon/blade/blade_swing.wav",
			pitchMod = 0.1,
			gainMod = 0.1,
			pitch = 0.8,
			gain = 0.9,
			priority = 1,
		},
		BladeHit = {
			file = "sounds/weapon/blade/blade_hit.wav",
			pitchMod = 0.5,
			gainMod = 0.2,
		},
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
		TorpedoHitVariable = {
			file = "sounds/explosion/wet/ex_underwater.wav",
			pitchMod = 0.1,
			gainMod = 0.05,
		},
	},
}

--------------------------------------------------------------------------------
-- Automagical sound handling
--------------------------------------------------------------------------------
local VFSUtils = VFS.Include('gamedata/VFSUtils.lua')

local defaultOpts = {
	pitchMod = 0, --0.02,
	gainMod = 0,
}
local replyOpts = {
	pitchMod = 0, --0.02,
	gainMod = 0,
}

local noVariation = {}

local ignoredExtensions = {
	["svn-base"] = true,
}

local function AutoAdd(subDir, opts)
	opts = opts or {}
	local dirList = RecursiveFileSearch("sounds/" .. subDir)
	--local dirList = RecursiveFileSearch("sounds/")
	for _, fullPath in ipairs(dirList) do
    	local path, key, ext = fullPath:match("sounds/(.*/(.*)%.(.*))")
		local pathPart = fullPath:match("(.*)[.]")
		pathPart = pathPart:sub(8, -1)	-- truncates extension fullstop and "sounds/" part of path
		if path ~= nil and (not ignoredExtensions[ext]) then
			--Spring.Echo(path,key,ext, pathPart)
			Sounds.SoundItems[pathPart] = {file = tostring('sounds/'..path), rolloff = opts.rollOff, dopplerscale = opts.dopplerScale, maxdist = opts.maxDist, maxconcurrent = opts.maxConcurrent, priority = opts.priority, gain = opts.gain, gainmod = opts.gainMod, pitch = opts.pitch, pitchmod = opts.pitchMod}
			--Spring.Echo(Sounds.SoundItems[key].file)
		end
	end
end

-- add sounds
AutoAdd("weapon", defaultOpts)
AutoAdd("explosion", defaultOpts)
AutoAdd("reply", replyOpts)
AutoAdd("music", noVariation)

return Sounds
