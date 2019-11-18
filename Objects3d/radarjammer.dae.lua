return {
	pieces = {
		base = {
			cylinder = {},
			turret = {},
			jammersturret = {
				jam1 = {offset = { 6.327, 56.639, 0.0}, },
				jam2 = {offset = {-6.327, 56.639, 0.0}, },
			},
			deploy = {},
		},
	},

	radius = 20,
	height = 40,
	midpos = {0, 20, 0},
	tex1 = "radarjammer1.dds",
	tex2 = "radarjammer2.dds",
	numpieces = 7,

	globalvertexoffsets = false, -- vertices in global space?
	localpieceoffsets = true, -- offsets in local space?

}
