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
		SiloLaunchEmp = {
			file = "sounds/weapon/missile/tacnuke_launch.wav",
			gain = 1.0,
			pitch = 1.0,
			priority = 1,
			maxconcurrent = 30,
			maxdist = nil,
		},
		SiloLaunch = {
			file = "sounds/weapon/missile/tacnuke_launch.wav",
			gain = 0.4,
			pitch = 1.0,
			priority = 1,
			maxconcurrent = 30,
			maxdist = nil,
		},
		SonicLow = {
			file = "sounds/weapon/sonicgun2.wav",
			pitchmod = 0,
			gainmod = 0,
			pitch = 0.95,
		},
		SonicHitLow = {
			file = "sounds/weapon/sonicgun_hit.wav",
			pitchmod = 0,
			gainmod = 0,
			pitch = 0.9,
		},
		FirewalkerHit = {
			file = "sounds/weapon/cannon/wolverine_hit.wav",
			pitchmod = 0.008,
		},
		ex_med5_flat_pitch = {
			file = "sounds/explosion/ex_med5.wav",
			pitchmod = 0,
		},
		heavy_laser3_flat_pitch = {
			file = "sounds/weapon/laser/heavy_laser3.wav",
			pitchmod = 0,
		},
		gravity_fire = {
			file = "sounds/weapon/gravity_fire.wav",
			gainmod = 0.8,
			pitchmod = 0.01,
		},
		dgun_hit = {
			file = "sounds/explosion/ex_med6.wav",
			gainmod = 0.7,
			pitchmod = 0,
		},
	},
}

--------------------------------------------------------------------------------
-- Automagical sound handling
--------------------------------------------------------------------------------

local optionOverrides = {
	["weapon/missile/missile_launch_short"] = {
		pitchmod = 0,
		gainmod = 0,
		maxconcurrent = 5,
	},
	["weapon/burning_fixed"] = {
		pitchmod = 0.03,
		gainmod = 0.1,
		maxconcurrent = 10,
		rolloff = 0.75,
	},
	["weapon/cannon/plasma_fire_extra2"] = {
		gain = 20,
	},
}
local lowPitchMod = {
	"weapon/heatray_fire",
	"weapon/emg",
	"explosion/burn_explode",
	"weapon/bomb_drop_short",
	"impacts/shotgun_impactv5",
	"explosion/ex_large5",
	"weapon/laser/mini_laser",
}

local lowestPitchMod = {
	"weapon/laser/pulse_laser3",
}

local noPitchMod = {
	"weapon/missile/missile_fire9_heavy",
	"weapon/missile/rapid_rocket_fire2",
	"weapon/cannon/wolverine_fire",
	"weapon/laser/pulse_laser2",
	"weapon/shotgun_firev4",
	"weapon/cannon/cannon_fire4",
	"weapon/missile/rapid_rocket_fire",
	"weapon/small_lightning",
	"explosion/ex_large4",
	"weapon/gauss_fire_short",
	"weapon/missile/rapid_rocket_hit",
}

for i = 1, #noPitchMod do 
	optionOverrides[noPitchMod[i]] = {pitchmod = 0}
end

for i = 1, #lowPitchMod do 
	optionOverrides[lowPitchMod[i]] = {pitchmod = 0.015}
end

for i = 1, #lowestPitchMod do 
	optionOverrides[lowestPitchMod[i]] = {pitchmod = 0.006}
end

local defaultOpts = {
	pitchmod = 0.04,
	gainmod = 0,
}
local replyOpts = {
	pitchmod = 0, 
	gainmod = 0,
}
local explosionOpts = {
	pitchmod = 0.07,
	gainmod = 0,
}

local noVariation = {
	dopplerscale = 0,
	in3d = false,
	gainmod = 0,
	pitchmod = 0,
	pitch = 1,
	gain = 1,
}

local ignoredExtensions = {
	["svn-base"] = true,
}

local function AutoAdd(subDir, generalOpts)
	generalOpts = generalOpts or {}

	local dirList = VFS.DirList("sounds/" .. subDir, nil, nil, true)
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
AutoAdd("reply", replyOpts)
AutoAdd("explosion", explosionOpts)
AutoAdd("music", noVariation)

return Sounds
