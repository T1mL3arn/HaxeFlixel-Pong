#pragma header

#define PI 3.1415926535

// original game size
uniform vec2 iScreenSize;
uniform float iTime;
// uniform float iRand;

vec2 fakePixel(vec2 uv, vec2 base)
{
	//vec2 shift = base*0.5;
	//vec2 normalizer = 2.0*base/(base*base);
	vec2 res = vec2(0.0);
	res.x = abs(sin(PI*(uv.x/base.x)));
	res.y = abs(sin(PI*(uv.y/base.y)));
	
	//float m = abs(0.4*sin(iTime*PI*0.25));
	//res = smoothstep(vec2(0.1 + m), vec2(0.75), res);
	return res;
}

float random (vec2 st) {
	return fract(sin(0.00175*iTime*3.14 + dot(st.xy,
												vec2(12.9898,78.233)))*
			43758.5453);
}

void main()
{
	// another way to implement vertical scanlines
	// https://www.shadertoy.com/view/Ms23DR

	vec2 uv = openfl_TextureCoordv.xy;
	
	vec3 col = flixel_texture2D(bitmap, uv).rgb;
	
	// width and height in fake pixels
	// vec2 fakeSize = vec2(640.0, 480.0)*0.1875;
	vec2 fakeSize = iScreenSize*0.1875;
	fakeSize = 1.0/fakeSize;
	vec2 fp = vec2(0.0);
	fp = fakePixel(uv, fakeSize);

	// how dark edges of fake pixels should be
	// the more it is, the darker it will be
	float dark = 0.35;
	vec3 darkColor = col*(1.0-dark);
	// how bright the fake pixel should be
	float luma = 1.25;
	col = mix(darkColor, col*luma, fp.x*fp.y);

	// scale coordinate system (it will match "pixelation" from above)
	uv /= fakeSize;
	// random value [0,1]
	vec2 ipos = floor(uv);
	float rnd =  random( ipos );
	if (rnd >= 0.6) {
		//float f = step(0.7,rnd);
		// noize factor
		float nf = 0.08;
		col *= (1.1-nf) + nf*(rnd*2.0-1.0);
	}
	
	gl_FragColor = vec4(col, 1.0);
}