--
-- Custom Options Definition Table format
--
-- A detailed example of how this format works can be found
-- in the spring source under:
-- AI/Skirmish/NullAI/data/AIOptions.lua
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local options = {
	{ -- section
		key    = 'performance',
		name   = 'Performance Relevant Settings',
		desc   = 'These settings may be relevant for both CPU usage and AI difficulty.',
		type   = 'section',
	},
	{ -- list
		key     = 'difficulty',
		name    = 'Difficulty',
		desc    = 'How tough the AI should be.\nkey: difficulty',
		type    = 'list',
		section = 'performance',
		def     = 'normal',
		items   = {
			{
				key  = 'easy',
				name = 'Easy',
				desc = 'Easy AI.',
			},
			{
				key  = 'normal',
				name = 'Normal',
				desc = 'Casual AI.',
			},
			{
				key  = 'hard',
				name = 'Hard',
				desc = 'Los-cheating AI.',
			},
		},
	},
	{ -- bool
		key     = 'ally_aware',
		name    = 'Alliance awareness',
		desc    = 'Consider allies presence while making expansion desicions',
		type    = 'bool',
		section = 'performance',
		def     = true,
	},
	{ -- bool
		key     = 'comm_merge',
		name    = 'Merge neighbour Circuits',
		desc    = 'Merge spatially close Circuit ally commanders',
		type    = 'bool',
		section = 'performance',
		def     = true,
	},
	{ -- string
		key     = 'config',
		name    = 'Config',
		desc    = 'Play with arbitrary config of your choice.\nkey: config',
		type    = 'string',
		def     = '',
	},
--	{ -- string
--		key     = 'json',
--		name    = 'JSON',
--		desc    = 'Per-AI config.\nkey: json',
--		type    = 'string',
--		def     = '',
--	},
	{ -- string
		key     = 'disabledunits',
		name    = 'Disabled units',
		desc    = 'Disable usage of specific units.\nSyntax: armwar+cloakraid+raveparty\nkey: disabledunits',
		type    = 'string',
		def     = '',
	},
	{ -- string
		key     = 'version',
		name    = 'AI version',
		desc    = 'This value is used for parsing!',
		type    = 'string',
		def     = '0.9.15.a',
	},
}

return options
