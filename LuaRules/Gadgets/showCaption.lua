    function gadget:GetInfo()
      return {
        name      = "Show Caption",
        desc      = "Show a caption an icon",
        author    = "exciter",
        date      = "2011",
        license   = "GPL",
        layer     = 0,
        enabled   = false,
      }
    end

    function gadget:Initialize()			
            Spring.SetWMCaption("Zero-K")
			Spring.SetWMIcon("bitmaps/ZK_logo_square.bmp")
    end