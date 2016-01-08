local buildOpts = {
	[[cormex]],
	[[armsolar]],
	[[armfus]],
	[[cafus]],
	[[armwin]],
	[[geo]],
	[[armmstor]],
	[[armestor]],
	[[armnanotc]],
	[[armasp]],
	[[factoryshield]],
	[[factorycloak]],
	[[factoryveh]],
	[[factoryplane]],
	[[factorygunship]],
	[[factoryhover]],
	[[factoryamph]],
	[[factoryspider]],
	[[factoryjump]],
	[[factorytank]],
    [[striderhub]],
	[[factoryship]],
	[[corrad]],
	[[armarad]],
	[[armsonar]],
	[[corjamt]],
	[[armjamt]],
	[[corrl]],
	[[corllt]],
	[[corgrav]],
	[[armartic]],
	[[armdeva]],
	[[corhlt]],
	[[armpb]],
	[[armanni]],
	[[cordoom]],
	[[turrettorp]],
	[[corrazor]],
	[[missiletower]],
	[[armcir]],
	[[corflak]],
	[[screamer]],
	[[armamd]],
	[[corbhmth]],
	[[armbrtha]],
	[[missilesilo]],
	[[corsilo]],
	[[mahlazer]],
	[[raveparty]],
	[[zenith]],
	[[armcsa]],
}

if (Spring.GetModOptions) then
	local modOptions = Spring.GetModOptions()
	if (modOptions and modOptions.commtest and modOptions.commtest ~= 0) then
		buildOpts[#buildOpts + 1] = [[dynhub_support_base]]
		buildOpts[#buildOpts + 1] = [[dynhub_recon_base]]
		buildOpts[#buildOpts + 1] = [[dynhub_assault_base]]
	end
end

return buildOpts