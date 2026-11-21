#version 420 compatibility
// The minimap: the tint and borders as lines of a width in pixels, half on each side.
uniform vec2 mapSize;
out vec2 pos;
void main() {
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	pos = gl_MultiTexCoord0.st * mapSize;
}
