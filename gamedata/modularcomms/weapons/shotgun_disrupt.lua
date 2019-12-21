local _, def = VFS.Include("gamedata/modularcomms/weapons/shotgun.lua")

def.name = "Disruptor " .. def.name
def.customParams.timeslow_damagefactor = 2
for armorType, damage in pairs (def.damage) do
	def.damage[armorType] = damage * 0.75
end

def.customParams.light_color = "0.3 0.05 0.3"
def.customParams.altforms = nil -- baseline also has a green variant, disruptor doesn't yet
def.explosionGenerator = "custom:BEAMWEAPON_HIT_PURPLE"
def.rgbColor = "0.9 0.1 0.9"

return "commweapon_shotgun_disrupt", def
