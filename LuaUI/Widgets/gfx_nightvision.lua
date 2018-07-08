function widget:GetInfo() return {
	name    = "Nightvision Shader",
	desc    = "My vision is augmented",
	author  = "Evil4Zerggin; NV tweak by KingRaptor",
	date    = "3 November 2009",
	license = "MIT",
	layer   = 1,
	enabled = false
} end

if not gl.CreateShader then
	Spring.Echo(GetInfo().name .. ": GLSL not supported.")
	return
end

local shaderProgram = gl.CreateShader({
	uniformInt = uniformInt,
	fragment = [[ // intensity formula based on http://alienryderflex.com/hsp.html
		uniform sampler2D screencopy;

		float getIntensity(vec4 color) {
			vec3 intensityVector = color.rgb * vec3(0.491, 0.831, 0.261);
			return length(intensityVector);
		}

		void main() {
			vec2 texCoord = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
			vec4 origColor = texture2D(screencopy, texCoord);
			float intensity = getIntensity(origColor);

			intensity = intensity * 1.5;
			if (intensity > 1) intensity = 1;

			     if (intensity < 0.2)
				gl_FragColor = vec4(intensity*0.15, intensity*0.15, intensity*0.15, 0.9);
			else if (intensity < 0.35)
				gl_FragColor = vec4(intensity*0.15, intensity*0.4,  intensity*0.15, 0.9);
			else if (intensity < 0.5)
				gl_FragColor = vec4(intensity*0.2,  intensity*0.8,  intensity*0.2,  0.9);
			else if (intensity > 0.75)
				gl_FragColor = vec4(intensity*0.5,  intensity,      intensity*0.7,  0.9);
			else if (mod(gl_FragCoord.y, 4.0) < 2.0)
				gl_FragColor = vec4(intensity*0.5,  intensity*0.8,  intensity*0.3,  0.9);
			else
				gl_FragColor = vec4(intensity*0.2,  intensity,      intensity*0.4,  1.0);
		}
	]],
})
if not shaderProgram then
	Spring.Log(widget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
	return
end

local vsx, vsy
local screencopy

function widget:Initialize()
	vsx, vsy = widgetHandler:GetViewSizes()
	widget:ViewResize(vsx, vsy)
end

function widget:Shutdown()
	gl.DeleteShader(shaderProgram)
	if screencopy then
		gl.DeleteTexture(screencopy)
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx, vsy = viewSizeX, viewSizeY

	if screencopy then
		gl.DeleteTexture(screencopy)
	end

	screencopy = gl.CreateTexture(vsx, vsy, {
		border = false,
		min_filter = GL.NEAREST,
		mag_filter = GL.NEAREST,
	})
	if screencopy then
		widgetHandler:UpdateCallIn("DrawScreenEffects")
	else
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "CreateTexture failed!")
		widgetHandler:RemoveCallIn("DrawScreenEffects")
	end
end

local glUseShader = gl.UseShader
local glCopyToTexture = gl.CopyToTexture
local glTexture = gl.Texture
local glTexRect = gl.TexRect
function widget:DrawScreenEffects()
	glCopyToTexture(screencopy, 0, 0, 0, 0, vsx, vsy)
	glTexture(0, screencopy)
	glUseShader(shaderProgram)
	glTexRect(0,vsy,vsx,0)
	glTexture(0, false)
	glUseShader(0)
end
