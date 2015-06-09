  
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
    key    = 'silly', -- lava, oremex, fun, zombies
    name   = 'Silly',
    desc   = 'Silly options for trolling.',
    type   = 'section',
  },
  {
    key    = 'zkmode',
    name   = 'Game Mode',
    desc   = 'Change the game mode.',
    type   = 'list',
    section= 'silly',
    def    = 'normal',
    items  = {
      {
        key  = 'normal',
        name = 'Normal',
        desc = 'Normal game mode',
      },
      {
	key  = 'lavarise',
	name = 'Lava Rising',
	desc = 'Endlessly rising lava!  Fiery fun for the whole family!',
      },
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
        key='lavarisecycles',
        name='Number of cycles',
        desc='Set how many cycles before map floods completely.  The more cycles, the slower the map floods. ',
        type='number',
        def=7,
        min=1,
        max=2000,
        step=1.0,
        section='silly',
    },

    {
        key='lavariseperiod',
        name='Length of lava cycle',
        desc='How long each rise will wait for the next in seconds. ',
        type='number',
        def=120,
        min=1,
        max=6000,
        step=1,
        section='silly',
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
    key    = 'oremex',
    name   = 'Enable CNC style mexes',
    desc   = "You have to reclaim ore with this option being enabled.",
    type   = 'bool',
    section= 'silly',
    def    = false,
  },
  {
    key    = 'oremex_prespawn',
    name   = 'Ore mex prespawn',
    desc   = "With this you get prespawned ore extractors.",
    type   = 'bool',
    section= 'silly',
    def    = true,
  },
  {
    key='oremex_metal',
    name='Prespawned ore amount',
    desc='Set how much metal should be prespawned.',
    type='number',
    def=35,
    min=0,
    max=10000,
    step=1,
    section='silly',
  },
  {
    key    = 'oremex_invul',
    name   = 'Ore mex invulnerability',
    desc   = "With this you can't damage ore extractors.",
    type   = 'bool',
    section= 'silly',
    def    = true,
  },
  {
    key    = 'oremex_overdrive',
    name   = 'Ore mex overdrive',
    desc   = "Overdrive ore extractors to produce more ore.",
    type   = 'bool',
    section= 'silly',
    def    = true,
  },
  {
    key    = 'oremex_inf',
    name   = 'Ore mex infinite growth',
    desc   = "With this you can have crystal apocalypse should it hurt units...",
    type   = 'bool',
    section= 'silly',
    def    = false,
  },
  {
    key    = 'oremex_uphill',
    name   = 'Ore mex slower uphill growth',
    desc   = "With this you can try to use terraform to slow growth.",
    type   = 'bool',
    section= 'silly',
    def    = true,
  },
  {
    key    = 'oremex_crystal',
    name   = 'Ore mex crystal models',
    desc   = "If true, ore will look like crystal, otherwise will look like metal chunks.",
    type   = 'bool',
    section= 'silly',
    def    = true,
  },
  {
    key    = 'oremex_communism',
    name   = 'Ore mex communism',
    desc   = "If true, ore income will be fully equally shared between active&alive players.",
    type   = 'bool',
    section= 'silly',
    def    = true,
  },
  {
    key='oremex_harm',
    name='Ore damage',
    desc='Set how much damage should ore inflict on contact, it stacks. Some units are ore proof.',
    type='number',
    def=0,
    min=0,
    max=10000,
    step=0.01,
    section='silly',
  },
  {
    key = "forcejunior",
    name = "Force Junior",
    desc = "Choose whether everyone gets a standard Junior Comm chassis.",
    type = "bool",
    section= 'startconds',
    def = false,
  },
  {
	key		= "disabledunits",
	name	= "Disable units",
	desc	= "Prevents specified units from being built ingame. Specify multiple units by using + ",
	section	= 'startconds',
	type	= "string",
	def		= nil,
  },
  {
    key = "overdrivesharingscheme",
    name = "Overdrive Resource Distribution Scheme",
    desc = "Different scheme designed for distributing overdrive share.",
    type = "list",
    section= 'a_important',
    def = "investmentreturn",
    items = {
      {
        key  = "investmentreturn",
        name = "Investment Return",
        desc = "Extra income is given to active players who built economy structure until the cost of the structure is paid.",
      },
      {
        key  = "investmentreturn_od",
        name = "Overdrive Return",
        desc = "Extra overdrive is given to active players who built energy structure until the cost of the structure is paid.",
      },
      {
        key  = "investmentreturn_base",
        name = "Extractor Return",
        desc = "Extra income is given to active players who built metal extractor until the cost of the structure is paid.",
      },
      {
        key  = "communism",
        name = "Equal Sharing",
        desc = "All overdrive is shared equally among active players at all time.",
      },
    },
  },  
  {
    key         = "allyreclaim",
    name        = "Reclaimable allies",
    desc        = "Allows reclaiming allied units and structures",
    type        = "bool",
    section     = "modifiers",
    def         = false,
  },
  {
    key    = "shuffle",
    name   = "Shuffle Start Boxes",
    desc   = "Shuffles start boxes.",
    type   = "list",
    section= 'startconds',
    def    = "off",
    items  = {
      {
        key  = "off",
        name = "Off",
        desc = "Do nothing.",
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
    },
  },

  {
    key    = 'noceasefire',
    name   = 'Disable ceasefire panel',
    desc   = 'Disable ceasefire control panel (When "Fixed ingame alliances" is off).',
    type   = 'bool',
    section = 'diplomacy',
    def    = false,
  },
  {
    key='typemapsetting',
    name='Terrain Speed Boost',
    desc='Choose which map Speed Boost to use',
    type='list',
    section= 'mapsettings',
    def='auto',
    items = {
      { key='auto', name="Automatic", desc='Use one of the other options based on a mod-defined list, defaulting to Keep Equal' },
      { key='mapdefault', name="Map Default", desc='Use map speed boost' },
      { key='average', name="Average", desc='Each terrain types speed boost is averaged' },
      { key='keepequal', name="Keep Equal", desc='Non-equal speedboost removed' },
      { key='onlyimpassable', name="Only Impassable", desc='Override all speedboost except impassable terrain' },
      { key='alloff', name="All Off", desc='Disable all speed boost' },
    },
  },
    {
    key    = 'waterlevel',
    name   = 'Water Level',
    desc   = 'Adjusts the water level of the map',
    type   = 'number',
    section= 'mapsettings',
    def    = 0,
    min    = -2000,
    max    = 2000,
    step   = 1,
  },
  {
    key    = 'metalmult',
    name   = 'Metal Extraction Multiplier',
    desc   = 'Multiplies metal extraction rate. For use in large team games when there are fewer mexes per player.',
    type   = 'number',
    section= 'mapsettings',
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
    section= 'mapsettings',
    def    = 1,
    min    = 0,
    max    = 100,
    step   = 0.05,  -- quantization is aligned to the def value
                    -- (step <= 0) means that there is no quantization
  },
  {
    key    = 'experimental',
    name   = 'Experimental Settings',
    desc   = 'Experimental settings.',
    type   = 'section',
  },
  {
    key    = 'marketandbounty',
    name   = 'Enable MarketPlace and Bounties (dysfunctional)',
    desc   = 'Adds option to sell your units, buy units from allies (including temporary allies). Also allows you to place a bounty on a unit.',
    type   = 'bool',
    section= 'experimental',
    def    = false,
  },
  {
    key    = 'terracostmult',
    name   = 'Terraform Cost Multiplier',
    desc   = 'Multiplies the cost of terraform.',
    type   = 'number',
    section= 'experimental',
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
    section= 'experimental',
    def    = 1,
    min    = 0,
    max    = 1000,
    step   = 0.01,
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
    key    = 'iwinbutton',
    name   = 'Enable giant expensive "I Win" button',
    desc   = "For speed games. Race to build it!",
    type   = 'bool',
    section= 'silly',
    def    = false,
  },
  {
    key    = "coop",
    name   = "Cooperation Mode",
    desc   = "Cooperation Mode",
    type   = "bool",
    section= "startconds",
    def    = false,
  },
  --{
  --  key		= "enableunlocks",
  --  name	= "Enable unlock system",
  --  desc	= "Enables the unlock system (disabling will enable all units by default)",
  --  type	= "bool",
  --  def		= true,
  --  section	= "experimental",
  --},  
  {
    key		= "impulsejump",
    name	= "Impulses Jump",
    desc	= "Allow jumps that is effected by Newton and can jump anywhere (no restriction). Compatible for Spring 93.2 and above",
    type	= "bool",
    def		= false,
    section	= "experimental",
  },  
  {
    key		= "pathfinder",
    name	= "Pathfinder type",
    desc	= "Sets the pathfinding system used by units.",
    type	= "list",
    def		= "standard",
    section	= "experimental",
    items  = {
      {
	key  = 'standard',
	name = 'Standard',
	desc = 'Standard pathfinder',
      },
      {
	key  = 'qtpfs',
	name = 'QTPFS',
	desc = 'New Quadtree Pathfinding System (experimental)',
      },
    --  {
	--	key  = 'classic',
	--	name = 'Classic',
	--	desc = 'An older pathfinding system without turninplace or reverse',
    --  }
    },	
  },  
  
  {
    key    = 'chicken',
    name   = 'Chicken',
    desc   = 'Settings for Chicken: Custom',
    type   = 'section',
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
    min    = 20,
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
    min    = 20,
    max    = 200,
    step   = 1,
  },
  {
    key    = 'queentime',
    name   = 'Queen Time',
    desc   = 'How soon the queen appears on her own, minutes.',
    type   = 'number',
    section= 'chicken',
    def    = 60,
    min    = 1,
    max    = 200,
    step   = 1,
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
	desc   = 'How much time each burrow death subtracts from queen appearance time, seconds',
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
