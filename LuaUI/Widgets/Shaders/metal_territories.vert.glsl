#version 420 compatibility
out vec4 data;
void main() {
	gl_Position = gl_Vertex;
	gl_PointSize = 1.0;
	data = gl_Color;
}
