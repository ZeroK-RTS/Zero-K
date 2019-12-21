local _, def = VFS.Include("gamedata/modularcomms/weapons/lightninggun.lua")

def.name = "Heavy " .. def.name
def.paralyzeTime = def.paralyzeTime + 2
def.customParams.extra_damage_mult = def.customParams.extra_damage_mult * 1.25

def.customParams.light_radius = def.customParams.light_radius + 20
def.thickness = def.thickness + 3
def.rgbColor = "0.65 0.65 1"

return "commweapon_lightninggun_improved", def
