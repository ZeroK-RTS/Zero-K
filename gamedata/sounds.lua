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
		PulseLaser = {
			file = "sounds/weapon/laser/pulse_laser_start.wav",
			pitchmod = 0.15,
			gainmod = 0.1,
			pitch = 1,
			gain = 1.5,
		},
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
		FireLaunch = {
			file = "sounds/weapon/cannon/cannon_fire3.wav",
			pitchmod = 0.1,
			gainmod = 0.1,
		},
		FireHit = {
			file = "sounds/explosion/ex_med6.wav",
			pitchmod = 0.4,
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
		DetrimentJump = {
			file = "sounds/detriment_jump.wav",
			pitchmod = 0.1,
			gainmod = 0.05,
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
		SiloLaunch = {
			file = "sounds/weapon/missile/tacnuke_launch.wav",
			gain = 1.0,
			pitch = 1.0,
			priority = 1,
			maxconcurrent = 30,
			maxdist = nil,
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

	local dirList = RecursiveFileSearch("sounds/" .. subDir)
	for i = 1, #dirList do
		local fullPath = dirList[i]
		local pathPart, ext = fullPath:match("sounds/(.*)%.(.*)")
		if not ignoredExtensions[ext] then
			local opts = optionOverrides[pathPart] or generalOpts
			Sounds.SoundItems[pathPart] = {
				file = fullPath,
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
		end
	end
end

-- add sounds
AutoAdd("weapon", defaultOpts)
AutoAdd("explosion", defaultOpts)
AutoAdd("reply", replyOpts)
AutoAdd("music", noVariation)

return Sounds
