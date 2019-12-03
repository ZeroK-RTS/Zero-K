local _, def = VFS.Include("gamedata/modularcomms/weapons/multistunner.lua")

def.name = "Heavy " .. def.name
def.paralyzeTime = def.paralyzeTime + 2
for armorType, damage in pairs (def.damage) do
	def.damage[armorType] = damage * 1.25
end

def.customParams.light_color = "0.75 0.75 0.22"
def.customParams.light_radius = def.customParams.light_radius + 30
def.thickness = def.thickness + 5
def.rgbColor = "1 1 0.25"

return "commweapon_multistunner_improved", def