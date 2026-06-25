-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- RETIRED. Hovering unit-state icons are now rendered by the "Unit Overlay GL4" widget
-- (gui_unit_overlay_gl4.lua), which owns the WG.icons backend (instanced, unified row layout).
--
-- This file used to be a second WG.icons backend: it claimed `WG.icons`, stored the provider
-- data in its own tables, and drew the icons immediate-mode at full unit height. With the GL4
-- overlay also providing WG.icons, the two fought over the global depending on load order -- when
-- this widget won, the overlay never received the provider data (its row stayed empty) and the
-- icons were drawn here at the wrong (full) height instead of in the overlay's row.
--
-- It is now an inert stub: it does NOT touch WG.icons and draws nothing, so the overlay is the
-- sole owner regardless of load order and the provider widgets (unit_state_icons, unit_rank_icons,
-- api_gadget_icons, unit_global_build_command) feed the overlay directly. Kept (rather than deleted)
-- only so existing "enabled" widget configs load cleanly; safe to leave enabled or disabled.
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
	name      = "Unit Icons",
	desc      = "Retired: hovering state icons are rendered by Unit Overlay GL4 (which backs WG.icons). Inert stub, draws nothing.",
	author    = "CarRepairer and GoogleFrog",
	date      = "2012-01-28",
	license   = "GNU GPL, v2 or later",
	layer     = -13,
	enabled   = false,
  }
end
