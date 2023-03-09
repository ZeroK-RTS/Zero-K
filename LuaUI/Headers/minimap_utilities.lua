local function getMiniMapFlipped()
	if ((not Spring.GetMiniMapRotation) or
	    (Spring.GetConfigInt("MiniMapCanFlip", 0) == 0)) then
		return false
	end

	local rot = Spring.GetMiniMapRotation()

	return rot > math.pi/2 and rot <= 3 * math.pi/2;
end

return { getMiniMapFlipped = getMiniMapFlipped }
