#version 330
// full screen triangle
uniform float viewPosX;
uniform float viewPosY;

const vec2 vertices[3] = vec2[3](
	vec2(-1.0, -1.0),
	vec2( 3.0, -1.0),
	vec2(-1.0,  3.0)
);

out vec2 viewPos;

void main()
{
	gl_Position = vec4(vertices[gl_VertexID], 0.0, 1.0);
	viewPos = vec2(viewPosX, viewPosY);
}
