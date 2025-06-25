#version 420
#line 10000

// Shader licensed under GNU GPL, v2 or later. Relicensed from MIT, preserving the notice "(c) Beherith (mysterme@gmail.com)".

//__DEFINES__

layout (location = 0) in vec2 xyworld_xyfract;
uniform vec4 radarcenter_range;  // x y z range
uniform float resolution;  // how many steps are done

uniform sampler2D heightmapTex;

out DataVS {
	vec4 worldPos; // pos and radius
	vec4 centerposrange;
	vec4 blendedcolor;
	float worldscale_circumference;
};

//__ENGINEUNIFORMBUFFERDEFS__

#line 11009

float heightAtWorldPos(float x, float y){
	x = clamp(floor(x / 32.0)*32.0, 0.0, mapSize.x - 32.0);
	y = clamp(floor(y / 32.0)*32.0, 0.0, mapSize.y - 32.0);
	
	float acc = 0.0;
	vec2 uvhm = vec2(x + 4.0, y + 4.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 12.0, y + 4.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 20.0, y + 4.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 28.0, y + 4.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	
	uvhm = vec2(x + 4.0, y + 12.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 12.0, y + 12.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 20.0, y + 12.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 28.0, y + 12.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	
	uvhm = vec2(x + 4.0, y + 20.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 12.0, y + 20.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 20.0, y + 20.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 28.0, y + 20.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	
	uvhm = vec2(x + 4.0, y + 28.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 12.0, y + 28.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 20.0, y + 28.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	uvhm = vec2(x + 28.0, y + 28.0)/ mapSize.xy;
	acc += max(0.0, textureLod(heightmapTex, uvhm, 0.0).x);
	
	return acc / 16.0;
}

void main() {
	// transform the point to the center of the radarcenter_range

	vec4 pointWorldPos = vec4(0.0);

	vec3 radarMidPos = radarcenter_range.xyz;
	
	radarMidPos.x = clamp(floor(radarMidPos.x / 32.0)*32.0, 0.0, mapSize.x - 32.0) + 16.0;
	radarMidPos.z = clamp(floor(radarMidPos.z / 32.0)*32.0, 0.0, mapSize.y - 32.0) + 16.0;
	
	pointWorldPos.xz = (radarMidPos.xz + (xyworld_xyfract.xy * radarcenter_range.w)); // transform it out in XZ
	pointWorldPos.y = heightAtWorldPos(pointWorldPos.x, pointWorldPos.z) + 5.0; // get the world height at that point
	// Add LOS_BONUS_HEIGHT from https://github.com/beyond-all-reason/spring/blob/BAR105/rts/Sim/Misc/LosMap.cpp#L16

	vec3 toWorldPos = vec3(pointWorldPos.xyz - radarMidPos.xyz);
	float dist_to_center = length(toWorldPos.xyz);

	// get closer to the center in N mip steps, and if that point is obscured at any time, remove it

	vec3 smallstep =  toWorldPos / dist_to_center;
	float obscured = 0.0;
	
	float xf = abs(toWorldPos.x);
	float zf = abs(toWorldPos.z);
	float xs = toWorldPos.x > 0.0 ? 1.0 : -1.0;
	float zs = toWorldPos.z > 0.0 ? 1.0 : -1.0;
	
	float step = 32.0;
	
	if (xf > zf) {
		// horizontal line
		float m = toWorldPos.z / toWorldPos.x;
		float hm = toWorldPos.y / toWorldPos.x;
		for (float x = 1.0; x <= xf; x += step) {
			float heightatsample = heightAtWorldPos(radarMidPos.x + x*xs, radarMidPos.z + m*x*xs);
			obscured = max(obscured, heightatsample - (radarMidPos.y + hm*x*xs));
			if (obscured > 0.001)
				break;
		}
	} else {
		// vertical line
		float m = toWorldPos.x / toWorldPos.z;
		float hm = toWorldPos.y / toWorldPos.z;
		for (float z = 1.0; z <= zf; z += step) {
			float heightatsample = heightAtWorldPos(radarMidPos.x + m*z*zs, radarMidPos.z + z*zs);
			obscured = max(obscured, heightatsample - (radarMidPos.y + hm*z*zs));
			if (obscured > 0.001)
				break;
		}
	}

	worldscale_circumference = 1.0; //startposrad.w * circlepointposition.z * 5.2345;
	worldPos = vec4(pointWorldPos);
	blendedcolor = vec4(0.0);
	blendedcolor.a = 0.5;
	//if (dist_to_center > radarcenter_range.w) blendedcolor.a = 0.0;  // do this in fs instead

	blendedcolor.g = 1.0-clamp(obscured*1000.0,0.0,1.0);

	blendedcolor.a = min(blendedcolor.g, blendedcolor.a);
	blendedcolor.g = 1.0;

	pointWorldPos.y += 0.1;
	worldPos = pointWorldPos;
	gl_Position = cameraViewProj * vec4(pointWorldPos.xyz, 1.0);
	centerposrange = radarcenter_range;
}