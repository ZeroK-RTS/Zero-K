   
-- $Id: ModOptions.lua 4642 2009-05-22 05:32:36Z carrepairer $


--  Custom Options Definition Table format
--  NOTES:
--  - using an enumerated table lets you specify the options order

--
--  These keywords must be lowercase for LuaParser to read them.
--
--  key:      the string used in the script.txt
--  name:     the displayed name
--  desc:     the description (could be used as a tooltip)
--  type:     the option type ('list','string','number','bool')
--  def:      the default value
--  min:      minimum value for number options
--  max:      maximum value for number options
--  step:     quantization step, aligned to the def value
--  maxlen:   the maximum string length for string options
--  items:    array of item strings for list options
--  section:  so lobbies can order options in categories/panels
--  scope:    'all', 'player', 'team', 'allyteam'      <<< not supported yet >>>
--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Example ModOptions.lua
--

local options = {
-- do deployment and tactics even work?
  {
    key    = 'a_important',
    name   = 'Important',
    desc   = 'Commonly used options.',
    type   = 'section',
  },
  {
    key    = 'startconds',
    name   = 'Start',
    desc   = 'Start condition settings.',
    type   = 'section',
  },
  {
    key    = 'mapsettings',
    name   = 'Map',
    desc   = 'Map settings.',
    type   = 'section',
  },
  {
    key    = 'multipliers',
    name   = 'Multipliers',
    desc   = 'Statistics multipliers.',
    type   = 'section',
  },
  {
    key    = 'silly', -- lava, fun, zombies
    name   = 'Silly',
    desc   = 'Silly options for trolling.',
    type   = 'section',
  },
  {
    key    = 'commends',
    name   = 'Team Commander Ends',
    desc   = 'Causes an allyteam to lose if they have no commanders left on their team',
    type   = 'bool',
    def    = false,
    section= 'a_important',
  },

	{
		key     = 'sharemode',
		name    = 'Commshare',
		desc    = 'Determines whether players can merge together during gameplay.',
		type    = 'list',
		section = 'a_important',
		def     = 'invite',
		items   = {
			{ key='all', name = "Merge All", desc = 'Merges all at game start. Recommend using allowunmerge = false with this.' },
			{ key='invite', name = "Invite Only", desc = 'Allows players to merge only if both give consent.' },
			{ key='none', name = "Off", desc = 'Turns commsharing off.' },
		},
	},
	
  {
    key = "noelo",
    name = "No Elo",
    desc = "Prevent battle from affecting Elo rankings",
    type = "bool",
    section= 'a_important',
    def = false,
  },
	{
		key     = 'mutespec',
		name    = 'Mute Spectators',
		desc    = 'Determines whether spectators can talk to players.',
		type    = 'list',
		section = 'a_important',
		def     = 'autodetect',
		items   = {
			{ key='mute', name = "Mute", desc = 'Mutes spectators.' },
			{ key='autodetect', name = "Autodetect", desc = 'Mutes spectators in FFA (more than two teams).' },
			{ key='nomute', name = "No Mute", desc = 'Does not mute spectators.' },
		},
	},
	{
		key     = 'mutelobby',
		name    = 'Mute Lobby',
		desc    = 'Determines whether chat in the lobby is visible ingame.',
		type    = 'list',
		section = 'a_important',
		def     = 'autodetect',
		items   = {
			{ key='mute', name = "Mute", desc = 'Mutes the lobby.' },
			{ key='autodetect', name = "Autodetect", desc = 'Mutes the lobby in FFA (more than two teams).' },
			{ key='nomute', name = "No Mute", desc = 'Does not mute the lobby.' },
		},
	},
  {
    key    = 'zombies',
    name   = 'Enable zombies',
    desc   = "All features self-resurrect.",
    type   = 'bool',
    section= 'silly',
    def    = false,
  },
  {
    key    = 'zombies_delay',
    name   = 'Zombie min spawn time',
    desc   = "In seconds, unit will resurrection no faster than this.",
    type   = 'number',
    section= 'silly',
    def=10,
    min=1,
    max=600,
    step=1,
  },
  {
    key    = 'zombies_rezspeed',
    name   = 'Zombie resurrection speed',
    desc   = "In metal per second.",
    type   = 'number',
    section= 'silly',
    def=12,
    min=1,
    max=10000,
    step=1,
  },
  {
    key    = 'zombies_permaslow',
    name   = 'Zombie permaslow modifier',
    desc   = "If more than 0 zombies are permaslowed to half of that amount, so 1 means 50% slow.",
    type   = 'number',
    section= 'silly',
    def=1,
    min=0,
    max=1,
    step=0.01,
  },
  {
    key    = 'zombies_partial_reclaim',
    name   = 'Zombies partially reclaimable',
    desc   = "Partially reclaimed zombies are partially damaged.",
    type   = 'bool',
    section= 'silly',
    def = false,
  },
  {
    key = "max_com_level",
    name = "Commander level limit",
    desc = "Choose the commander level limit. 0 for unlimited.",
    type = "number",
    section= 'startconds',
    def = 0,
    min = 0,
    step = 1,
    max = 20,
  },
  {
	key		= "disabledunits",
	name	= "Disable units",
	desc	= "Prevents specified units from being built ingame. Specify multiple units by using + ",
	section	= 'startconds',
	type	= "string",
	def		= "",
  },
	{
		key = 'globallos',
		name = 'Full visibility',
		desc = 'No fog of war, everyone can see the entire map.',
		type = 'bool',
		section = 'startconds',
		def = false,
	},
  {
    key = "overdrivesharingscheme",
    name = "Economy returns investment",
    desc = "In a team game, resource gathering buildings return their cost over time to the players who build them.",
    type = 'bool',
    section= 'a_important',
    def = true,
  },
  {
    key = "enablelagmonitor",
    name = "Enable Inactivity Sharing",
    desc = "In a team game, automatically share units of inactive players.",
    type = 'bool',
    section= 'a_important',
    def = true,
  },
  {
    key         = "allyreclaim",
    name        = "Reclaimable allies",
    desc        = "Allows reclaiming allied units and structures",
    type        = "bool",
    section     = "experimental",
    def         = false,
  },
  {
    key    = "shuffle",
    name   = "Start Boxes",
    desc   = "Start box settings.",
    type   = "list",
    section= 'startconds',
    def    = "auto",
    items  = {
      {
        key  = "off",
        name = "Fixed",
        desc = "Startboxes have a fixed correspondence to teams.",
      },
      {
        key  = "shuffle",
        name = "Shuffle",
        desc = "Shuffle among boxes that would be used.",
      },
      {
        key  = "allshuffle",
        name = "All Shuffle",
        desc = "Shuffle all present boxes.",
      },
      {
        key  = "auto",
        name = "Autodetect",
        desc = "Shuffle if FFA.",
      },
      {
        key  = "disable",
        name = "Start Anywhere",
        desc = "Allow to place anywhere. Boxes are still drawn for reference but are not obligatory.",
      },
    },
  },
  {
    key='setaispawns',
    name='Set AI Spawns',
    desc='Allow players to set the start positions of AIs.',
    type='bool',
    section= 'startconds',
    def=false,
  },
  {
    key='campaign_chassis',
    name='Allow campaign commander chassis',
    desc='Allows you to choose the campaign commander chassis.',
    type='bool',
    section= 'startconds',
    def=false,
  },
  {
    key='typemapsetting',
    name='No roads',
    desc='Some maps have roads that allow faster unit movement. When enabled, units will move at their regular unboosted speed on roads.',
    type='bool',
    section= 'mapsettings',
    def=false,
  },
  { -- Might cause desync, check if they occur.
    key    = 'waterlevel',
    name   = 'Manual Water Level',
    desc   = 'How much to raise water level, in elmos.',
    type   = 'number',
    section= 'mapsettings',
    def    = 0,
    min    = -2000,
    max    = 2000,
    step   = 1,
  },
  {
    key    = 'waterpreset',
    name   = 'Water Level',
    desc   = 'Adjusts the water level of the map',
    type   = "list",
    section= 'mapsettings',
    def    = 'manual',
    items  = {
      {
        key  = "manual",
        name = "Manual",
        desc = "Input height manually",
      },
      {
        key  = "dry",
        name = "Dry",
        desc = "Drain the map of water",
      },
      {
        key  = "flooded",
        name = "Flooded",
        desc = "Cover half the map area with water",
      },
    },
  },
  {
    key    = 'metalmult',
    name   = 'Metal Extraction Multiplier',
    desc   = 'Multiplies metal extraction rate. For use in large team games when there are fewer mexes per player.',
    type   = 'number',
    section= 'multipliers',
    def    = 1,
    min    = 0,
    max    = 100,
    step   = 0.05,  -- quantization is aligned to the def value
                    -- (step <= 0) means that there is no quantization
  },
  {
    key    = 'energymult',
    name   = 'Energy Production Multiplier',
    desc   = 'Useful for speed games without relying on map units.',
    type   = 'number',
    section= 'multipliers',
    def    = 1,
    min    = 0,
    max    = 100,
    step   = 0.05,  -- quantization is aligned to the def value
                    -- (step <= 0) means that there is no quantization
  },
  {
    key    = 'experimental',
    name   = 'Experimental',
    desc   = 'Experimental.',
    type   = 'section',
  },
  {
    key    = 'shield_merge',
    name   = 'Shield type',
    desc   = 'Shield merge method.',
    type   = 'list',
    section= 'experimental',
    def    = 'none',
    items = {
      {key = 'none', name = "None", desc = 'Shield link only'},
      {key = 'share', name = "Impact sharing", desc = 'On impact, neighbours contribute charge to make up the required charge.'},
      {key = 'penetrate', name = "Partial Penetrate", desc = 'Projectiles drain shields that they penetrate but lose effective damage for subsequent shield impacts.'},
    },
  },
  {
    key    = 'terracostmult',
    name   = 'Terraform Cost Multiplier',
    desc   = 'Multiplies the cost of terraform.',
    type   = 'number',
    section= 'multipliers',
    def    = 1,
    min    = 0.01,
    max    = 100,
    step   = 0.01,
  },
  {
    key    = 'terrarestoreonly',
    name   = 'Terraform Restore Only',
    desc   = 'Restore is the only terraform option available.',
    type   = 'bool',
    section= 'experimental',
    def    = false,
  },  
--[[  
  {
    key    = 'damagemult',
    name   = 'Damage Multiplier',
    desc   = 'Multiplies the damage dealt by all weapons, except for D-guns; autoheal; repair; and capture.',
    type   = 'number',
    section= 'experimental',
    def    = 1,
    min    = 0.01,
    max    = 10,
    step   = 0.01,
  },
  {
    key    = 'unitspeedmult',
    name   = 'Unit Speed Multiplier',
    desc   = 'Multiplies the speed, acceleration, and turn rate of all units.',
    type   = 'number',
    section= 'experimental',
    def    = 1,
    min    = 0.01,
    max    = 10,
    step   = 0.01,
  },
]]--
  {
    key    = 'cratermult',
    name   = 'Cratering Multiplier',
    desc   = 'Multiplies the depth of craters.',
    type   = 'number',
    section= 'multipliers',
    def    = 1,
    min    = 0,
    max    = 1000,
    step   = 0.01,
  },
  {
    key    = 'hpmult',
    name   = 'Unit Health Multiplier',
    desc   = 'Multiplies all unit HPs.',
    type   = 'number',
    section= 'multipliers',
    def    = 1,
    min    = 0.000001,
    max    = 10000,
    step   = 0.05,
  },
  {
    key    = 'xmas',
    name   = 'Enable festive units',
    desc   = "Zero K units get into the spirit of the season with a festive new look.",
    type   = 'bool',
    section= 'silly',
    def    = false,
  },
	{
		key     = 'maxunits',
		name    = 'Max units',
		desc    = 'Determines how many units and buildings a player is allowed to own at a time',
		type    = 'number',
		section = 'multipliers',
		def     = 10000, -- don't change to anything reachable, won't take effect; engine default is ~10K 
		                 -- (actually 32K / #teams so 1v1+gaia allows ~10K each)
		min     = 10,
		max     = 10000,
		step    = 10,
	},
	{
		key     = 'minspeed',
		name    = 'Minimum game speed',
		desc    = 'Sets the minimum speed that the players will be allowed to change to',
		type    = 'number',
		section = 'multipliers',
		def     = 0.3, -- don't change, won't take effect as this is engine value
		min     = 0.1,
		max     = 2.0,
		step    = 0.1,
	},
	{
		key     = 'maxspeed',
		name    = 'Maximum game speed',
		desc    = 'Sets the maximum speed that the players will be allowed to change to',
		type    = 'number',
		section = 'multipliers',
		def     = 20.0, -- don't change, won't take effect as this is engine value
		min     = 0.5,
		max     = 20.0,
		step    = 0.1,
	},
	{
		key     = 'disablemapdamage',
		name    = 'Disable map deformation',
		desc    = 'Prevents the map shape from being changed by weapons and terraforming',
		type    = 'bool',
		section = 'mapsettings',
		def     = false, -- don't change, won't take effect as this is engine value
	},
	--[[ Engine option, would need proper UI before enabling
	{
		key     = 'fixedallies',
		name    = 'Disallow ceasefire',
		desc    = 'Is ceasefire banned? For FFA.',
		type    = 'bool',
		section = 'experimental',
		def     = true, -- don't change, won't take effect as this is engine value
	},
	]]

  --{
  --  key		= "enableunlocks",
  --  name	= "Enable unlock system",
  --  desc	= "Enables the unlock system (disabling will enable all units by default)",
  --  type	= "bool",
  --  def		= true,
  --  section	= "experimental",
  --},  
--  { -- Causes desync https://springrts.com/mantis/view.php?id=5936
--    key		= "pathfinder",
--    name	= "Pathfinder type",
--    desc	= "Sets the pathfinding system used by units.",
--    type	= "list",
--    def		= "standard",
--    section	= "experimental",
--    items  = {
--      {
--	key  = 'standard',
--	name = 'Standard',
--	desc = 'Standard pathfinder',
--      },
--      {
--	key  = 'qtpfs',
--	name = 'QTPFS',
--	desc = 'New Quadtree Pathfinding System (experimental)',
--      },
--    --  {
--	--	key  = 'classic',
--	--	name = 'Classic',
--	--	desc = 'An older pathfinding system without turninplace or reverse',
--    --  }
--    },	
--  },  
  
  {
    key    = 'chicken',
    name   = 'Chicken',
    desc   = 'Settings for Chicken: Custom',
    type   = 'section',
  },
  {
    key    = 'chickenailevel',
    name   = 'Chicken AI Difficulty',
    desc   = "Option for automatically adding an AI to the script. Implemented by Springies and Chobby.",
    type   = 'list',
    section= 'chicken',
    def    = 'none',
    items = {
      { key = 'none', name = "none", desc = 'No chickens at all.' },
      { key = 'Chicken: Very Easy', name = "Chicken: Very Easy", desc = 'Very Easy Chicken.' },
      { key = 'Chicken: Easy', name = "Chicken: Easy", desc = 'Easy Chicken.' },
      { key = 'Chicken: Normal', name = "Chicken: Normal", desc = 'Normal Chicken.' },
      { key = 'Chicken: Hard', name = "Chicken: Hard", desc = 'Hard Chicken.' },
      { key = 'Chicken: Suicidal', name = "Chicken: Suicidal", desc = 'Suicidal Chicken.' },
      { key = 'Chicken: Custom', name = "Chicken: Custom", desc = 'Customize your chicken.' },
    },
  },
  {
    key = "playerchickens",
    name = "Players as chickens",
    desc = "Shared chickens with players, take commanders away",
    type = "bool",
    def = false,
    section = 'chicken',
  },
  {
    key	= "eggs",
    name = "Chicken Eggs",
    desc = "Enables eggs mode (applies to all chicken difficulties); metal extractors are disabled but chickens drop twice as many eggs",
    type = "bool",
    def	= false,
    section = 'chicken',
  },
  {
    key	= "speedchicken",
    name = "Speed Chicken",
    desc = "Game lasts half as long; no miniqueens (applies to all chicken difficulties)",
    type = "bool",
    def	= false,
    section = 'chicken',
  },
  {
    key    = 'chickenspawnrate',
    name   = 'Chicken Spawn Rate',
    desc   = 'Sets the frequency of chicken waves in seconds.',
    type   = 'number',
    section= 'chicken',
    def    = 50,
    min    = 5,
    max    = 200,
    step   = 1,
  },
  {
    key    = 'burrowspawnrate',
    name   = 'Burrow Spawn Rate',
    desc   = 'Sets the frequency of burrow spawns in seconds (modified by playercount and number of existing burrows).',
    type   = 'number',
    section= 'chicken',
    def    = 45,
    min    = 1,
    max    = 200,
    step   = 1,
  },
  {
    key    = 'wavesizemult',
    name   = 'Wave size mult',
    desc   = 'Increases or decreases the size of each chicken wave.',
    type   = 'number',
    section= 'chicken',
    def    = 1,
    min    = 0.1,
    max    = 40,
    step   = 0.05,
  },
  {
    key    = 'queentime',
    name   = 'Queen Time',
    desc   = 'How soon the queen appears on her own, minutes.',
    type   = 'number',
    section= 'chicken',
    def    = 60,
    min    = 1,
    max    = 300,
    step   = 1,
  },
  {
    key    = 'queenhealthmod',
    name   = 'Queen Health Mult',
    desc   = 'Queen health multiplier',
    type   = 'number',
    section= 'chicken',
    def    = 1,
    min    = 0.1,
    max    = 30,
    step   = 0.05,
  },
  {
    key     = 'chicken_endless',
    name    = 'Infinite Chicken',
    desc    = 'Queen does not spawn, waves go on forever.',
    type    = "bool",
    def     = false,
    section = 'chicken',
  },
  {
    key    = 'graceperiod',
    name   = 'Grace Period',
    desc   = 'Delay before the first wave appears, minutes.',
    type   = 'number',
    section= 'chicken',
    def    = 2.5,
    min    = 0,
    max    = 120,
    step   = 0.5,
  },
  {
    key    = 'miniqueentime',
    name   = 'Dragon Time',
    desc   = 'Time when the White Dragons appear, as a proportion of queen time. 0 disables.',
    type   = 'number',
    section= 'chicken',
    def    = 0.6,
    min    = 0,
    max    = 1,
    step   = 0.05,
  },
  {
    key    = 'techtimemult',
    name   = 'Tech Time Mult',
    desc   = 'Multiplier for the appearance times of advanced chickens.',
    type   = 'number',
    section= 'chicken',
    def    = 1,
    min    = 0,
    max    = 5,
    step   = 0.05,
  },
  {
    key    = 'chicken_maxtech',
    name   = 'Max Tech Level',
    desc   = 'Maximum timer for chicken tech level progression, in seconds. Lowering this value will exclude some or most chicken types. Applies to all difficulties.',
    type   = 'number',
    section= 'chicken',
    def    = 9000,
    min    = 0,
    max    = 9000,
    step   = 60,
  },
--[[  
  {
	key    = 'burrowtechtime',
	name   = 'Burrow Tech Time',
	desc   = 'How much time each burrow shaves off chicken appearance times per wave (divided by playercount), seconds',
	type   = 'number',
	section= 'chicken',
	def    = 12,
	min    = 0,
	max    = 60,
	step   = 1,  
  },
]]--  
  {
	key    = 'burrowqueentime',
	name   = 'Burrow Queen Time',
	desc   = 'How much time each burrow death subtracts from queen appearance time, seconds.',
	type   = 'number',
	section= 'chicken',
	def    = 15,
	min    = 0,
	max    = 120,
	step   = 1,  
  },
}

--// add key-name to the description (so you can easier manage modoptions in springie)
for i=1,#options do
  local opt = options[i]
  opt.desc = opt.desc .. '\nkey: ' .. opt.key
end

return options
