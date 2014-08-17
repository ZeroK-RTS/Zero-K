local names = {
	["Strike Trainer"] = "comm_trainer_strike",
	["Battle Trainer"] = "comm_trainer_battle",
	["Recon Trainer"] = "comm_trainer_recon",
	["Support Trainer"] = "comm_trainer_support",
	["Siege Trainer"] = "comm_trainer_siege",
}

local comms = {}
for name, unitName in pairs(names) do
	comms[name] = {trainer = true}
	for i=1,6 do
		comms[name][i] = unitName .. "_" .. (i - 1)
	end
end

return comms, names