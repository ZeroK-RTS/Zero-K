--------------------------------------------------------------------------------
-- Overdrive Cables — Settings menu entry
--
-- Pure UI bridge for the unsynced gadget gfx_overdrive_cables.lua. Exposes a
-- three-state radio button under Settings/Graphics so users can pick the
-- detail level without typing chat commands. Persistence lives on the gadget
-- side (Spring.GetConfigInt("OverdriveCableDetail")) so disabling this
-- widget doesn't lose the user's choice — the gadget keeps reading its own
-- config key on reload.
--
-- Communication: this widget never touches the gadget directly; it just
-- fires `/luarules cabletree detail <key>` via Spring.SendCommands. The
-- gadget's chat handler updates state and writes Spring config.
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Overdrive Cables Settings",
		desc      = "Settings menu entry for the overdrive cable visualization.",
		author    = "Licho",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		handler   = false,
	}
end

local DETAIL_KEY = "OverdriveCableDetail"
local GHOSTS_KEY = "OverdriveCableGhosts"
local KEY_BY_LEVEL = { [0] = 'off', [1] = 'noflow', [2] = 'full' }
local LEVEL_BY_KEY = { off = 0, noflow = 1, full = 2 }

local function readCurrentDetailKey()
	local v = Spring.GetConfigInt(DETAIL_KEY, 2) or 2
	return KEY_BY_LEVEL[v] or 'full'
end

local function readCurrentGhosts()
	return (Spring.GetConfigInt(GHOSTS_KEY, 1) or 1) ~= 0
end

options_path = 'Settings/Graphics/Overdrive Cables'
options_order = { 'cabletree_detail', 'cabletree_ghosts' }

options = {
	cabletree_detail = {
		name  = 'Overdrive cable visualization',
		desc  = 'Off: no cables drawn. Static: gray pipes only (cheapest). Full: animated bubbles indicating flow (default).',
		type  = 'radioButton',
		items = {
			{ key = 'full',   name = 'Full (animated bubbles)',         desc = 'Default. Bubbles indicate flow direction and rate.' },
			{ key = 'noflow', name = 'Static (no flow animation)',      desc = 'Cheaper: gray pipes only, no per-tick flow reads or shader bubble pass.' },
			{ key = 'off',    name = 'Off (no cables)',                  desc = 'Hide the overdrive grid entirely.' },
		},
		value = 'full',
		OnChange = function(self)
			Spring.SendCommands("luarules cabletree detail " .. self.value)
		end,
		noHotkey = true,
	},
	cabletree_ghosts = {
		name  = 'Show cable ghosts in fog',
		desc  = 'When on, segments of enemy cables you have scouted at least once stay visible as a flat ghost when they drop out of LOS, until you re-scout the area and confirm it is empty.',
		type  = 'bool',
		value = true,
		OnChange = function(self)
			Spring.SendCommands("luarules cabletree ghosts " .. (self.value and "on" or "off"))
		end,
		noHotkey = true,
	},
}

function widget:Initialize()
	-- Sync the widget's displayed value to the gadget's persisted state.
	-- The gadget loads first and reads its own Spring.SetConfigInt key, so
	-- whatever it's running at right now is the authoritative value. Push
	-- it back into the option so the menu reflects truth.
	options.cabletree_detail.value = readCurrentDetailKey()
	options.cabletree_ghosts.value = readCurrentGhosts()
	-- And ensure the gadget agrees with whatever was saved (idempotent —
	-- the gadget's setters return early if state is unchanged).
	Spring.SendCommands("luarules cabletree detail " .. options.cabletree_detail.value)
	Spring.SendCommands("luarules cabletree ghosts " .. (options.cabletree_ghosts.value and "on" or "off"))
end

-- Persistence: the gadget owns the truth via Spring.GetConfigInt. We let the
-- widget framework's per-widget config (ZK_data.lua) hold a redundant copy
-- of the value so the radio button shows correctly the moment the menu opens
-- — but on Initialize we override it with the gadget's actual value.
function widget:GetConfigData()
	return {
		value  = options.cabletree_detail.value,
		ghosts = options.cabletree_ghosts.value,
	}
end

function widget:SetConfigData(data)
	if data and data.value and LEVEL_BY_KEY[data.value] then
		options.cabletree_detail.value = data.value
	end
	if data and type(data.ghosts) == "boolean" then
		options.cabletree_ghosts.value = data.ghosts
	end
end
