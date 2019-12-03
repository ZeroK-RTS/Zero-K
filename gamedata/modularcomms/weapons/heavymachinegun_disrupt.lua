local _, def = VFS.Include("gamedata/modularcomms/weapons/heavymachinegun.lua")

def.name = "Disruptor " .. def.name
def.customParams.timeslow_damagefactor = 2
for armorType, damage in pairs (def.damage) do
	def.damage[armorType] = damage * 0.75
end

def.customParams.light_color = "1.3 0.5 1.6"
def.customParams.altforms = nil -- baseline also has a lime variant, disruptor doesn't yet
def.explosionGenerator = "custom:BEAMWEAPON_HIT_PURPLE"
def.rgbColor = "0.9 0.1 0.9"

return "commweapon_heavymachinegun_disrupt", def