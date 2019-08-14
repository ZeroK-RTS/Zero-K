uniform sampler2D screenTex;

#if defined(METHOD1)
	// credit goes here:
	// https://github.com/joergdietrich/daltonize/blob/master/daltonize.py (mostly)
	// https://reshade.me/forum/shader-suggestions/1331-daltonize-shader
	// https://www.dropbox.com/s/ayg0fgdr1s5hsu8/DaltonizeFX.zip?dl=0

	const mat3 rgb2lms = mat3(17.8824, 43.5161, 4.11935, 3.45565, 27.1554, 3.86714, 0.0299566, 0.184309, 1.46709);
	const mat3 lms2rgb = mat3(8.09444479e-02, -1.30504409e-01, 1.16721066e-01, -1.02485335e-02, 5.40193266e-02, -1.13614708e-01, -3.65296938e-04, -4.12161469e-03, 6.93511405e-01);

	void Simulate(out vec3 myoutput, in vec3 myinput){
		//define color blindness defect matrixes
		#if defined(PROTANOPIA)
			const mat3 lmsd = mat3(0.0, 2.02344, -2.52581, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
		#elif defined(DEUTERANOPIA)
			const mat3 lmsd = mat3(1.0, 0.0, 0.0, 0.494207, 0.0, 1.24827, 0.0, 0.0, 1.0);
		#elif defined(TRITANOPIA)
			const mat3 lmsd = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, -0.395913, 0.801109, 0.0);
		#endif
		
		// Simulate color blindness
		#if defined(PROTANOPIA) || defined(DEUTERANOPIA) || defined(TRITANOPIA)
			vec3 lms = myinput * rgb2lms;
			vec3 sim_lms = lms * lmsd;
			myoutput = sim_lms * lms2rgb;
		#else
			myoutput = myinput;
		#endif
	}

	const mat3 err2mod = mat3(0.0, 0.0, 0.0, 0.7, 1.0, 0.0, 0.7, 0.0, 1.0);
	void Correct(out vec3 myoutput, in vec3 myinput, in vec3 simulated){
		// myinput - simulated contains the color information that dichromats
		// cannot see. err2mod rotates this to a part of the spectrum that
		// they can see.
		vec3 error = (myinput - simulated) * err2mod;
		myoutput = error + myinput;
	}


#elif defined(METHOD2)
	void Simulate(out vec3 myoutput, in vec3 myinput){
		#if defined(PROTANOPIA)
			const mat3 blindVision = mat3(0.20, 0.99, -0.19, 0.16, 0.79, 0.04, 0.01, -0.01, 1.00);
		#elif defined(DEUTERANOPIA)
			const mat3 blindVision = mat3(0.43, 0.72, -0.15, 0.34, 0.57, 0.09, -0.02, 0.03, 1.00);
		#elif defined(TRITANOPIA)
			const mat3 blindVision = mat3(0.97, 0.11, -0.08, 0.02, 0.82, 0.16, -0.06, 0.88, 0.18);
		#else
			myoutput = myinput;
			return;
		#endif
		myoutput = myinput * blindVision;
	}

	const mat3 RGBtoSmth = mat3(0.2814, -0.0971, -0.0930, 0.6938, 0.1458,-0.2529, 0.0638, -0.0250, 0.4665);
	const mat3 SmthToRGB = mat3(1.1677, 0.9014, 0.7214, -6.4315, 2.5970, 0.1257, -0.5044, 0.0159, 2.0517);
	void Correct(out vec3 myoutput, in vec3 myinput, in vec3 simulated){
		vec3 tmpColor = RGBtoSmth * vec3(simulated.r, simulated.g, simulated.b);
		#if defined(PROTANOPIA)
			tmpColor.x -= tmpColor.y * 1.5; // reds (y <= 0) become lighter, greens (y >= 0) become darker
		#elif defined(DEUTERANOPIA)
			tmpColor.x -= tmpColor.y * 1.5; // reds (y <= 0) become lighter, greens (y >= 0) become darker
		#elif defined(TRITANOPIA)
			tmpColor.x -= ((3.0 * tmpColor.z) - tmpColor.y) * 0.25;
		#else
			myoutput = simulated;
			return;
		#endif
		myoutput = SmthToRGB * tmpColor;
	}
#endif


void main(void) {
	vec2 C0 = gl_TexCoord[0].st;
	vec4 screen4 = texture2D(screenTex, C0);
	
	vec3 screen3 = vec3(screen4.r, screen4.g, screen4.b);
	vec3 simulated3;
	vec3 result3;
	
	Simulate(simulated3, screen3);
	#if defined(CORRECT)
		Correct(result3, screen3, simulated3);
	#else
		result3 = simulated3;
	#endif
	gl_FragColor = vec4(result3, screen4.a);
}
