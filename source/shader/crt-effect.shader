// load custom texture example:
// https://www.shadertoy.com/view/lsGGDd

// other examples of "Barrel Distortion"
// https://www.shadertoy.com/view/4tVSRw
// https://www.shadertoy.com/view/lslGRN
// https://www.shadertoy.com/view/4sXcDN


// see other crt shaders
// https://www.shadertoy.com/view/DlfSz8

#pragma header

#define PI 3.1415926535

uniform float iTime;

vec2 curve(vec2 uv)
{
	uv = (uv - 0.5) * 2.0;
	uv *= 1.089;	
	uv.x *= 1. + pow((abs(uv.y) / 5.0), 2.);
	uv.y *= 1. + pow((abs(uv.x) / 5.0), 2.);
	uv  = (uv / 2.0) + 0.5;
	uv =  uv *0.92 + 0.04;
	return uv;
}

void main()
{
	vec2 uv = openfl_TextureCoordv.xy;
	uv = curve( uv );
	
	vec3 col;

	// Chromatic
	col.r = flixel_texture2D(bitmap, vec2(uv.x+0.00225, uv.y)).x;
	col.g = flixel_texture2D(bitmap, vec2(uv.x+0.00000, uv.y+0.00125)).y;
	col.b = flixel_texture2D(bitmap, vec2(uv.x-0.00225, uv.y+0.00125)).z;

	// hide parts out of the original texture
	col *= step(0.0, uv.x) * step(0.0, uv.y);
	col *= 1.0 - step(1.0, uv.x) * 1.0 - step(1.0, uv.y);

	// make it darker on edges
	//col *= 0.75 + 0.25*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
	// slighly change colors
	//col *= vec3(1.05,0.95,1.05);
	
	// make it brighter
	col *= 1.1;

	// Stripes
	float stripesSpeed = 30.0;
	// bigger factor - more stripes
	float stripesCountFactor = 400.0;
	float s_am = 0.075;
	float s_m = 1.0 - s_am;
  col *= s_m + s_am*sin(stripesSpeed * iTime + uv.y * stripesCountFactor);

	// // another way to do stripes
	// float dash = 10.0 / 640.0;
	// float space = dash;
	// step(0.0, dash - mod(uv.y + iTime, dash+space));

	// add screen flickering
	float freq = 100.0*PI;			// PI is used to make it "per second"
	float f_am = 0.025;					// amplitude modulation
	float f_m = 1.0 - f_am;	
	col *= f_m + f_am*sin(freq*iTime);

	gl_FragColor = vec4(col, 1.0);
}