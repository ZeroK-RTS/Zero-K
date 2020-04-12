local _, def = VFS.Include("gamedata/modularcomms/weapons/partillery.lua")

def.name = "Light Napalm Artillery"
def.areaOfEffect = def.areaOfEffect * 2
for armorType, damage in pairs (def.damage) do
	def.damage[armorType] = damage * 0.75
end
def.customParams.burntime = 450
def.customParams.burnchance = 1
def.customParams.setunitsonfire = 1
def.fireStarter = 100

def.explosiongenerator = "custom:napalm_koda"
def.rgbColor = "1 0.3 0.1"
def.soundHit = "weapon/burn_mixed"

return "commweapon_partillery_napalm", def
