-- Spring metadata for uar_nuclearfission.obj
pw_mine2 = {
	pieces = {
		base = {
			offset = {0.00, 0.00, 0.00},

			cylinder2 = {
				offset = {0.00, 0.00, 0.00},

			},
			cylinder1 = {
				offset = {0.00, 0.00, 0.00},

			},
			wheel1 = {
				offset = {-41.38, 14.05, 0.00},

			},
			wheel3 = {
				offset = {41.38, 14.05, -0.00},

			},
			wheel2 = {
				offset = {0.00, 14.05, 41.38},

			},
			wheel4 = {
				offset = {-0.00, 14.05, -41.38},

			},
		},
	},

	radius = 60,
	height = 100,
	midpos = {0.00, 50, 0.00},

	tex1 = "pw_mine2_1.dds",
	tex2 = "pw_mine2_2.dds",

	numpieces = 7, -- includes the root and empty pieces

	globalvertexoffsets = false, -- vertices in global space?
	localpieceoffsets = true, -- offsets in local space?
}

return pw_mine2
