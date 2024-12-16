#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// MIT License

// This shader is (c) Beherith (mysterme@gmail.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

#line 30000
in DataGS {
	vec4 g_color;
	vec4 g_uv;
};

uniform sampler2D healthbartexture;
out vec4 fragColor;

void main(void)
{
	vec4 texcolor = vec4(1.0);
	texcolor = texture(healthbartexture, g_uv.xy);
	texcolor.a *= g_color.a;
	fragColor.rgba = mix(g_color, texcolor, g_uv.z);
	//fragColor.rgba += vec4(0.25);
	//fragColor.a += 0.5;
	//fragColor.a = 1.0;
	if (fragColor.a < 0.05) discard;
}
