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
			file = "sounds/weapon/blade/blade_swing2.wav",
			pitchmod = 0.1,
			gainmod = 0.1,
			pitch = 0.8,
			gain = 0.9,
			priority = 2,
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
			maxconcurrent = 4, --- some reasonable limits (default appears to actually be 16)
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
			priority = 1,
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
			priority = 3,
			maxconcurrent = 30,
			maxdist = nil,
		},
		SiloLaunch = {
			file = "sounds/weapon/missile/tacnuke_launch.wav",
			gain = 1.0,
			pitch = 1.0,
			priority = 3,
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
			maxconcurrent = 10, --- firewalker
		},
		CaptureRay = {
			file = "sounds/weapon/laser/capture_ray.wav",
			gainmod = 0.5,
			gain = 0.6,
		},
		ex_med5_flat_pitch = {
			file = "sounds/explosion/ex_med5.wav",
			pitchmod = 0,
		},
		heavy_laser3_flat_pitch = {
			file = "sounds/weapon/laser/heavy_laser3.wav",
			priority = 0.5,
			pitchmod = 0,
		},
		gravity_fire = {
			file = "sounds/weapon/gravity_fire.wav",
			gainmod = 0.8,
			pitchmod = 0,
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

local DISABLE_PITCHMOD = true

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
	["weapon/laser/rapid_laser"] = {
		maxconcurrent = 6, --- raptor toad detriment
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/laser/rapid_laser2"] = {
		maxconcurrent = 8, --- gremlin hercules
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/cannon/brawler_emg"] = {
		maxconcurrent = 5, --- toad
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/cannon/brawler_emg3"] = {
		maxconcurrent = 5, --- nimbus
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/cannon/emg_hit3"] = {
		maxconcurrent = 5, --- nimbus
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/laser/small_laser_fire2"] = {
		maxconcurrent = 6, --- bandit
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/laser/lasercannon_hit"] = {
		maxconcurrent = 6, --- hercules punisher swift bandit zephyr welder razor
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/laser/laser_burn8"] = {
		maxconcurrent = 6, --- lotus
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/heatray_fire7"] = {
		maxconcurrent = 7, --- scorcher
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/emg"] = {
		maxconcurrent = 8, --- glaive
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/heavy_emg"] = {
		maxconcurrent = 10, --- stardust, reaver
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/cannon/emg_hit"] = {
		maxconcurrent = 6, --- stardust, reaver
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/laser/lasercannon_fire"] = {
		maxconcurrent = 6, --- hercules zephyr welder razor
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/laser/mini_laser"] = {
		maxconcurrent = 8, --- spicula, firefly, trisula, redback, scorpion
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/laser/small_laser_fire"] = {
		maxconcurrent = 10, --- flea
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/flamethrower"] = {
		maxconcurrent = 10, --- pyro dante tiamat
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/cannon/tremor_fire"] = {
		maxconcurrent = 5, --- tremor
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/cannon/cannon_hit5"] = {
		maxconcurrent = 10, --- tremor
		gain = 1.0,
		pitch = 1.0,
	},
	["weapon/cannon/wolverine_fire"] = {
		maxconcurrent = 10, --- firewalker
		gain = 1.0,
		pitch = 1.0,
	},

}

local priority = {
	["weapon/laser/heavy_laser6"] = 1,
	["weapon/laser/heavy_laser3"] = 1,
	["weapon/missile/liche_fire"] = 1,
	["weapon/missile/liche_hit"] = 1,
	["explosion/ex_ultra8"] = 2,
	["explosion/mini_nuke"] = 1, --- Claymore, Skuttle, Disco Rave Party, Snitch, Detriment, Lancelet, Scylla, Eos
	["weapon/missile/emp_missile_hit"] = 1, --- Shockley, Reef, Disco Rave Party
	["explosion/ex_large4"] = 1, --- Disco Rave Party, Quake
	["weapon/aoe_aura3"] = 1, --- Zeno
	["weapon/aoe_aura2"] = 1, --- Disco Rave Party, limpet
	["weapon/missile/nalpalm_missile_hit"] = 1, --- Inferno, Disco Rave Party
	["weapon/more_lightning"] = 1, --- Imp
	["weapon/lightningbolt3"] = 1, --- Widow
	["weapon/gauss_fire"] = 1, --- Phantom
	["weapon/snipe_hit"] = 1, --- Phantom
	["weapon/lightningbolt"] = 1, --- Thunderbird
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
	"weapon/laser/laser_burn10",
	"weapon/laser/laser_burn9",
}

for i = 1, #noPitchMod do 
	optionOverrides[noPitchMod[i]] = {pitchmod = 0}
end

for i = 1, #lowPitchMod do 
	optionOverrides[lowPitchMod[i]] = {pitchmod = DISABLE_PITCHMOD and 0 or 0.015}
end

for i = 1, #lowestPitchMod do 
	optionOverrides[lowestPitchMod[i]] = {pitchmod = DISABLE_PITCHMOD and 0 or 0.006}
end

local defaultOpts = {
	pitchmod = DISABLE_PITCHMOD and 0 or 0.04,
	gainmod = 0,
	maxconcurrent = 12,
	rolloff = 1.2,
}
local replyOpts = {
	pitchmod = 0, 
	gainmod = 0,
	rolloff = 0,
}
local explosionOpts = {
	pitchmod = 0.00,
	gainmod = 0,
	maxconcurrent = 12,
	rolloff = 1.2,
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
			Spring.Echo(pathPart, opts.priority or priority[pathPart] or 0)
			Sounds.SoundItems[pathPart] = {
				file = fullPath,
				rolloff = (opts.rolloff ~= nil and opts.rolloff) or (generalOpts and generalOpts.rolloff) or opts.rollOff,
				dopplerscale = opts.dopplerscale,
				maxdist = opts.maxdist,
				maxconcurrent = (opts.maxconcurrent ~= nil and opts.maxconcurrent) or generalOpts.maxconcurrent,
				priority = opts.priority or priority[pathPart] or 0,
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
