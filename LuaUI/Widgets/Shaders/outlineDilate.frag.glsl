#version 150 compatibility

uniform sampler2D depthTex;
uniform sampler2D colorTex;

uniform mat4 projMatrix;

#define DILATE_SINGLE_PASS ###DILATE_SINGLE_PASS###

uniform vec2 viewPortSize;
uniform int dilateHalfKernelSize;

//layout(pixel_center_integer) in vec4 gl_FragCoord;
//layout(origin_upper_left) in vec4 gl_FragCoord;


#if (DILATE_SINGLE_PASS == 1)
	void main(void)
	{
		ivec4 vpsMinMax = ivec4(0, 0, ivec2(viewPortSize));

		float minDepth = 1.0;
		vec4 maxColor = vec4(0.0);

		ivec2 thisCoord = ivec2(gl_FragCoord.xy);

		for (int x = -dilateHalfKernelSize; x <= dilateHalfKernelSize; ++x) {
			for (int y = -dilateHalfKernelSize; y <= dilateHalfKernelSize; ++y) {

				ivec2 offset = ivec2(x, y);
				/*
				ivec2 samplingCoord = thisCoord + offset;
				bool okCoords = ( all(bvec4(
					greaterThanEqual(samplingCoord, vpsMinMax.xy),
					lessThanEqual(samplingCoord, vpsMinMax.zw) ))
				);

				if (okCoords)*/ {
					minDepth = min(minDepth, texelFetchOffset( depthTex, thisCoord, 0, offset).r);
					vec4 thisColor = texelFetchOffset( colorTex, thisCoord, 0, offset);
					maxColor = max(maxColor, thisColor);
				}
			}
		}
		gl_FragDepth = minDepth;
		gl_FragColor = maxColor;
	}
#else //separable vert/horiz passes
	uniform vec2 dir;
	void main(void)
	{
		ivec4 vpsMinMax = ivec4(0, 0, ivec2(viewPortSize));

		float minDepth = 1.0;
		vec4 maxColor = vec4(0.0);

		ivec2 thisCoord = ivec2(gl_FragCoord.xy);

		for (int i = -dilateHalfKernelSize; i <= dilateHalfKernelSize; ++i) {

			ivec2 offset = ivec2(i) * ivec2(dir);
			/*
			ivec2 samplingCoord = thisCoord + offset;
			bool okCoords = ( all(bvec4(
				greaterThanEqual(samplingCoord, vpsMinMax.xy),
				lessThanEqual(samplingCoord, vpsMinMax.zw) ))
			);

			if (okCoords)*/ {
				minDepth = min(minDepth, texelFetchOffset( depthTex, thisCoord, 0, offset).r);
				vec4 thisColor = texelFetchOffset( colorTex, thisCoord, 0, offset);
				maxColor = max(maxColor, thisColor);
			}
		}

		gl_FragDepth = minDepth;
		gl_FragColor = maxColor;
	}
#endif