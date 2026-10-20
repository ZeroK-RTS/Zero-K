-- SPDX-License-Identifier: GPL-2.0-or-later
function gadget:GetInfo()
	return {name="Portal dots recording",desc="Opt-in all-team replay diagnostics",author="Codex",license="GPL v2 or later",layer=100000,enabled=true}
end
local result = VFS.Include("tools/portal_worlds/dots/recorder.lua", getfenv())
-- ZK retains the legacy gadget argument order, unlike the engine and BAR.
-- Normalize it here so the shared recorder receives real projectile/attacker IDs.
local recordDamage = gadget.UnitDamaged
if recordDamage then
	function gadget:UnitDamaged(id, def, team, damage, paralyzer, weapon, attacker, attackerDef, attackerTeam, projectile)
		return recordDamage(self, id, def, team, damage, paralyzer, weapon, projectile, attacker)
	end
end
return result
