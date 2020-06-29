local _, def = VFS.Include("gamedata/modularcomms/weapons/riotcannon.lua")

def.name = "Napalm " .. def.name
def.areaOfEffect = def.areaOfEffect * 1.25
for armorType, damage in pairs (def.damage) do
	def.damage[armorType] = damage * 0.75
end
def.craterBoost = 1
def.craterMult = 1

def.customParams.burntime = 420 -- blaze it!
def.customParams.burnchance = 1
def.customParams.setunitsonfire = 1
def.explosiongenerator = "custom:napalm_phoenix"
def.rgbColor = "1 0.3 0.1"
def.soundHit = "weapon/burn_mixed"

return "commweapon_riotcannon_napalm", def
