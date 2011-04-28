-- Spring metadata for uar_solartower.obj
pw_mine = {
	pieces = {
		base = {
			offset = {0.00, 0.00, 0.00},

			turret = {
				offset = {0.00, 0.00, 0.00},

			},
		},
	},

	radius = 40.00,
	height = 80.00,
	midpos = {0.00, 40.00, 0.00},

	tex1 = "pw_mine_1.dds",
	tex2 = "pw_mine_2.dds",

	numpieces = 2, -- includes the root and empty pieces

	globalvertexoffsets = false, -- vertices in global space?
	localpieceoffsets = true, -- offsets in local space?
}

return pw_mine
