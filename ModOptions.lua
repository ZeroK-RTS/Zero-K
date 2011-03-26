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
    key    = 'zkmode',
    name   = 'Game Mode',
    desc   = 'Change the game mode.',
    type   = 'list',
    section= 'modifiers',
    def    = 'normal',
    items  = {
      {
        key  = 'normal',
        name = 'Normal',
        desc = 'Normal game mode',
      },
      {
        key  = 'deploy',
        name = 'Deployment',
        desc = 'Players deploy a limited number of units before the game starts',
      },
      {
        key  = 'tactics',
        name = 'Tactics',
        desc = 'Players select a limited number of units before the game starts (without any factories)',
      },
      {
		key  = 'kingofthehill',
		name = 'King of the Hill',
		desc = 'Control the hill for a set amount of time to win! See King of the Hill section.',
      },
    },

  },
    {
    key    = 'koth',
    name   = 'King of the Hill Settings',
    desc   = 'Settings for King of the Hill mode.',
    type   = 'section',
    },
    {
        key='hilltime',
        name='Hill control time',
        desc='Set how long a team has to control the hill for (in minutes).',
        type='number',
        def=10,
        min=1,
        max=30,
        step=1.0,
        section='koth',
    },

    {
        key='gracetime',
        name='No control grace period',
        desc='No player can control the hill until period is over.',
        type='number',
        def=2,
        min=0,
        max=5,
        step=0.5,
        section='koth',
    },

  {
    key = "startingresourcetype",
    name = "Starting Resource Type",
    desc = "Choose the form in which starting resources are given.",
    type = "list",
    section= 'startconds',
    def = "facplop",
    items = {
      {
        key  = "facplop",
        name = "Factory Plop",
        desc = "First factory is free and built very fast.",
      },
      {
        key  = "facplopboost",
        name = "Factory Plop and Boost",
        desc = "Commander starts with boost instead of initial resources. First factory is free and built very fast.",
      },
      {
        key  = "boost",
        name = "Boost",
        desc = "Commanders start with boost instead of initial resources, which allows them to build using those resources at increased speed.",
      },
	  --[[
      {
        key  = "limitboost",
        name = "Limited Boost",
        desc = "Boost mode only commander cannot boostbuild anything with a weapon (uses normal build instead).",
      },
	  --]]
      {
        key  = "classic",
        name = "Classic",
        desc = "Classic mode.",
      },
    },
  },
  {
    key    = "shuffle",
    name   = "Shuffle Start Points",
    desc   = "Shuffles start positions.",
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
        key  = "box",
        name = "Within Boxes",
        desc = "Shuffle start positions within each team's box.",
      },
      {
        key  = "all",
        name = "All",
        desc = "Shuffle start positions of all commanders. Use this in place of random for autohosts.",
      },
      {
        key = "allboxes",
        name = "Distribute over all boxes",
        desc = "Distribute commanders over all boxes.",
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
    key    = 'sharemode',
    name   = 'Share Mode',
    desc   = 'Determines to which teams you may share units.',
    type   = 'list',
    section = 'diplomacy',
    def    = 'teammates',
    items = {
      { key='teammates', name="Teammates Only", desc='Share only to teammates.' },
      { key='ceasefire', name="Teammates and Ceasefired", desc='May also share to temporary ceasefired allies.' },
      { key='anyone', name="Anyone", desc='Share to anyone, including enemies.' },
    },
  },
  {
    key='typemapsetting',
    name='Terrain Speed Boost',
    desc='Choose which map Speed Boost to use',
    type='list',
    section= 'mapsettings',
    def='keepequal',
    items = {
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
    key    = 'MetalMult',
    name   = 'Metal Extraction Multiplier',
    desc   = 'Multiplies metal extraction rate. For use in large team games when there is less mexes by player.',
    type   = 'number',
    section= 'mapsettings',
    def    = 1,
    min    = 0,
    max    = 100,
    step   = 0.05,  -- quantization is aligned to the def value
                    -- (step <= 0) means that there is no quantization
  },
  {
    key    = 'EnergyMult',
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
    key    = 'minwind',
    name   = 'Minimum Wind',
    desc   = 'Minimum wind strength. Entering a negative value will use map\'s default.',
    type   = 'number',
    section= 'mapsettings',
    def    = 0,
    min    = -0.1,
    max    = 20,
    step   = 0.1,  -- quantization is aligned to the def value
                    -- (step <= 0) means that there is no quantization
  },
  {
    key    = 'maxwind',
    name   = 'Maximum Wind',
    desc   = 'Maximum wind strength. Entering a negative value will use map\'s default.',
    type   = 'number',
    section= 'mapsettings',
    def    = 2.5,
    min    = -0.1,
    max    = 20,
    step   = 0.1,  -- quantization is aligned to the def value
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
	name   = 'Enable MarketPlace and Bounties',
	desc   = 'Adds option to sell your units, buy units from allies (including temporary allies). Also allows you to place a bounty on a unit.',
	type   = 'bool',
	section= 'experimental',
	def    = true,
  },
  {
    key    = 'animation',
    name   = 'Animation Mode',
    desc   = 'Enables the animation control panel.',
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
    key    = 'doesnotcountmode',
    name   = 'DoesNotCount Mode',
    desc   = "Does Not Count mode.",
    type   = 'list',
    section= 'experimental',
    def    ='debug',
    items = {
      { key='debug', name="Debug", desc='Does nothing.' },
      { key='destroy', name="Destroy Alliance", desc='Destroys the alliance if they have only "doesnotcount units."' },
      { key='losecontrol', name="Lose Control", desc='Alliance loses control of their units they have only "doesnotcount units" (not yet implemented).' },

    },
  },
  --[[
  {
    key    = 'easymetal',
    name   = 'Easy Metal',
    desc   = 'Metal extractors are restricted to metal spots in the same way geo plants are. Spots are pre-analyzed but certain maps will provide strange results, such as Azure or Speedmetal.',
    type   = 'bool',
    section= 'experimental',
    def    = false,
  },
  --]]
  {
    key    = 'stayonteam',
    name   = 'Stay On Team (Dysfunctional)',
    desc   = 'Players are only removed from a team when they resign/drop. To become a spec, select all units and share them.',
    type   = 'bool',
    section= 'experimental',
    def    = false,
  },

  {
    key    = 'specialpower',
    name   = 'Special Advanced Powerplants',
    desc   = 'Rather than explode like a nuke, Adv Fusion do a massive implosion.',
    type   = 'bool',
    section= 'experimental',
    def    = false,
  },
  {
    key    = 'specialdecloak',
    name   = 'Special Decloak Behavior',
    desc   = 'Overrides engine\'s decloak. Shows cloaked units only to team that reveals them, also fixes cloak behavior in FFA games with ceasefires.',
    type   = 'bool',
    section= 'experimental',
    def    = false,
  },
  {
    key    = 'fun',
    name   = 'Fun Stuff',
    desc   = 'Fun stuff.',
    type   = 'section',
  },
  {
    key    = 'xmas',
    name   = 'Enable festive units',
    desc   = "Zero K units get into the spirit of the season with a festive new look.",
    type   = 'bool',
    section= 'fun',
    def    = false,
  },
  --[[{
	key    = 'communism',
    name   = 'Communism - resource sharing',
    desc   = 'Overdrive energy and metal extractors are used for common good, resulting metal is shared equally.',
    type   = 'bool',
    section= 'modifiers',
    def    = true,
  },--]]
  {
    key    = "disablefeatures",
    name   = "Disable Features",
    desc   = "Disable features (no wreackages).",
    type   = "bool",
    section= "mapsettings",
    def    = false,
  },
  {
    key    = 'factorycostmult',
    name   = 'Factory Cost Multiplier',
    desc   = 'Multiplies the cost of factories.',
    type   = 'number',
    section= 'experimental',
    def    = 1,
    min    = 0.01,
    max    = 100,
    step   = 0.01,
  },
  {
    key    = 'wreckagemult',
    name   = 'Wreckage Metal Multiplier',
    desc   = 'Multiplies the metal of wreckages and debris.',
    type   = 'number',
    section= 'experimental',
    def    = 1,
    min    = 0.01,
    max    = 100,
    step   = 0.01,
  },
  {
    key    = "coop",
    name   = "Cooperation Mode",
    desc   = "Cooperation Mode",
    type   = "bool",
    section= "startconds",
    def    = true,
  },
  {
    key    = 'planetwars',
    name   = 'Planet Wars Options',
    desc   = 'A string is put here by the Planet Wars server to set up ingame conditions.',
    type   = 'string',
    def    = false,
  },
  {
    key    = 'commandertypes',
    name   = 'Commander Types',
    desc   = 'A string is put here by Springie to determine number and types of custom commanders.',
    type   = 'string',
    def    = false,
	section	= "experimental",
  },
  {
	key		= "enableunlocks",
	name	= "Enable unlock system",
	desc	= "Enables the experimental unlock system (disabling will enable all units by default)",
	type	= "bool",
	def		= true,
	section	= "experimental",
  },
  {
    key    = 'chicken',
    name   = 'Chicken',
    desc   = 'Settings for Chicken: Custom',
    type   = 'section',
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
  {
	key    = 'burrowqueentime',
	name   = 'Burrow Queen Time',
	desc   = 'How much time each burrow death subtracts from queen appearance time (divided by playercount), seconds',
	type   = 'number',
	section= 'chicken',
	def    = 100,
	min    = 0,
	max    = 1200,
	step   = 1,  
  },
--[[
  {
    key    = 'noawards',
    name   = 'Disable Awards',
    desc   = "Turn off the shiny trophies at the end of the battle.",
    type   = 'bool',
    def    = false,
  },
  {
    key    = 'activeradars',
    name   = 'Active Radars',
    desc   = 'Radars will be always visible for the enemy.',
    type   = 'bool',
    def    = false,
  },
  {
    key = "specialair",
    name = "Special Air Units",
    desc = "Choose the type of air units.",
    type = "list",
    def = "false",
    items = {
      { key = "false", name = "Standard Air Units", desc = "Standard air units." },
      { key = "lasers", name = "Laser Bombers", desc = "Arm bombers fire lasers instead of bombs, Core Krow has an antigravity field instead of lasers." },
      { key = "seaplanes", name = "Seaplanes", desc= "Seaplanes replace many standard air units." },
    },
  },
  {
    key    = 'string_opt',
    name   = 'String Option',
    desc   = 'an unused string option',
    type   = 'string',
    def    = 'BiteMe',
    maxlen = 12,
  },
--]]
}

--// add key-name to the description (so you can easier manage modoptions in springie)
for i=1,#options do
  local opt = options[i]
  opt.desc = opt.desc .. '\nkey: ' .. opt.key
end

return options
