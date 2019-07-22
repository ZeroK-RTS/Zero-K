local ret = {
	"dyntrainer_recon_base",
	"dyntrainer_support_base",
	"dyntrainer_assault_base",
	"dyntrainer_strike_base",
}

if Spring.GetModOptions().campaign_chassis == "1" then
	--[[ Not sure about this, nabs like to feel special.
	     We could always limit it to hard/brutal and it's
	     not that amazing anyway ]]
	ret[#ret + 1] = "dyntrainer_knight_base"
end

return ret