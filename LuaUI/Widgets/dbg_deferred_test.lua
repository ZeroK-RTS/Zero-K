function widget:GetInfo()
   return {
      name      = "Deferred shading test",
      layer     = 0,
      enabled   = false,
   }
end

function widget:Initialize()
	vsx, vsy = widgetHandler:GetViewSizes()
end

function widget:Shutdown()
end

function widget:DrawGenesis()
end

local texName = "$model_gbuffer_difftex"

function widget:DrawScreenEffects()
	gl.Blending(false)
	gl.Texture(0, texName)
	gl.TexRect(0, 0, vsx, vsy, false, true)
	gl.Texture(0, false)
	gl.Blending(true)
end
