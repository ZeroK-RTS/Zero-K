local _, def = VFS.Include("gamedata/modularcomms/weapons/rocketlauncher.lua")

def.name = "Napalm " .. def.name
def.areaOfEffect = def.areaOfEffect * 1.5 -- other napalms are 1.25 tho?
for armorType, damage in pairs (def.damage) do
	def.damage[armorType] = damage * 0.75
end
def.craterBoost = 1
def.craterMult = 1

def.customParams.light_color = "0.95 0.5 0.25"
def.customParams.light_radius = def.customParams.light_radius * 1.25
def.customParams.light_camera_height = def.customParams.light_camera_height + 600
def.explosiongenerator = "custom:napalm_phoenix"
def.soundHit = "weapon/burn_mixed"

return "commweapon_rocketlauncher_napalm", def
