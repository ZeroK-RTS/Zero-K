-- see http://springrts.com/wiki/Sounds.lua for help
local Sounds = {
	SoundItems = {
		default = {
		},
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
			pitchmod = 0.1,
			gainmod = 0.1,
			pitch = 0.8,
			gain = 0.9,
			priority = 1,
		},
		BladeHit = {
			file = "sounds/weapon/blade/blade_hit.wav",
			pitchmod = 0.5,
			gainmod = 0.2,
		},
		DefaultsForSounds = { -- this are default settings
			file = "ThisEntryMustBePresent.wav",
			gain = 1.0,
			pitch = 1.0,
			priority = 0,
			maxconcurrent = 4, --- some reasonable limits
			maxdist = nil, --- no cutoff at all (engine defaults to FLT_MAX)
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
		Launcher = {
			file = "sounds/weapon/launcher.wav",
			pitchmod = 0.05,
			gainmod = 0,
			gain = 2.4,
		},
		TorpedoHitVariable = {
			file = "sounds/explosion/wet/ex_underwater.wav",
			pitchmod = 0.1,
			gainmod = 0.05,
		},
		Jump = {
			file = "sounds/jump.wav",
			pitchmod = 0.1,
			gainmod = 0.05,
		},
		JumpLand = {
			file = "sounds/jump_land.wav",
			pitchmod = 0.1,
			gainmod = 0.05,
		},
	},
}

--------------------------------------------------------------------------------
-- Automagical sound handling
--------------------------------------------------------------------------------
local VFSUtils = VFS.Include('gamedata/VFSUtils.lua')

local optionOverrides = {
}

local defaultOpts = {
	pitchmod = 0, --0.02,
	gainmod = 0,
}
local replyOpts = {
	pitchmod = 0, --0.02,
	gainmod = 0,
}

local noVariation = {
	dopplerscale = 0,
	in3d = false,
	pitchmod = 0,
	gainmod = 0,
	pitch = 1,
	gain = 1,
}

local ignoredExtensions = {
	["svn-base"] = true,
}

local function AutoAdd(subDir, generalOpts)
	generalOpts = generalOpts or {}
	local opts
	local dirList = RecursiveFileSearch("sounds/" .. subDir)
	--local dirList = RecursiveFileSearch("sounds/")
	--Spring.Echo("Adding sounds for " .. subDir)
	for _, fullPath in ipairs(dirList) do
		local path, key, ext = fullPath:match("sounds/(.*/(.*)%.(.*))")
		local pathPart = fullPath:match("(.*)[.]")
		pathPart = pathPart:sub(8, -1)	-- truncates extension fullstop and "sounds/" part of path
		--Spring.Echo(pathPart)
		if path ~= nil and (not ignoredExtensions[ext]) then
			if optionOverrides[pathPart] then
				opts = optionOverrides[pathPart]
				--Spring.Echo("optionOverrides for " .. pathPart)
			else
				opts = generalOpts
			end
			--Spring.Echo(path,key,ext, pathPart)
			Sounds.SoundItems[pathPart] = {
				file = tostring('sounds/'..path),
				rolloff = opts.rollOff,
				dopplerscale = opts.dopplerscale,
				maxdist = opts.maxdist,
				maxconcurrent = opts.maxconcurrent,
				priority = opts.priority,
				in3d = opts.in3d,
				gain = opts.gain,
				gainmod = opts.gainmod,
				pitch = opts.pitch,
				pitchmod = opts.pitchmod
			}
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
