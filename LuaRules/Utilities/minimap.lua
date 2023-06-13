function Spring.Utilities.IsMinimapFlipped()
	local rot = Spring.GetMiniMapRotation()
	local halfpi = math.pi / 2
	return rot > halfpi and rot <= 3 * halfpi
end
