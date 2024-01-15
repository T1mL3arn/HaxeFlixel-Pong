// load custom texture example:
// https://www.shadertoy.com/view/lsGGDd

// other examples of "Barrel Distortion"
// https://www.shadertoy.com/view/4tVSRw
// https://www.shadertoy.com/view/lslGRN
// https://www.shadertoy.com/view/4sXcDN


// see other crt shaders
// https://www.shadertoy.com/view/DlfSz8

// found the original source of this shader https://www.shadertoy.com/view/WdjfDy

#pragma header

#define PI 3.1415926535

uniform float iTime;

vec2 curve(vec2 uv)
{
	uv = (uv - 0.5) * 2.0;
	uv *= 1.00;	
	uv.x *= 1. + pow((abs(uv.y) / 5.0), 2.);
	uv.y *= 1. + pow((abs(uv.x) / 4.5), 2.);
	uv  = (uv / 2.0) + 0.5;
	// uv =  uv *0.92 + 0.04;
	return uv;
}

vec3 chroma(sampler2D source, vec2 uv, float chx, float chy){
    vec3 col = vec3(0.0);
    col.r = texture2D(source, vec2(uv.x+chx, uv.y+0.0)).x;
		col.g = texture2D(source, vec2(uv.x+0.0, uv.y+chy)).y;
		col.b = texture2D(source, vec2(uv.x-chx, uv.y+chy)).z;
    return col;
}

void main()
{
	vec2 uv = openfl_TextureCoordv.xy;
	uv = curve( uv );
	
	// Chromatic
	float chx = 0.003;
	float chy = 0.00125;
	vec3 col = chroma(bitmap, uv, chx, chy);
    
	// drop things beyond curved image
	col *= step(0.0, uv.x) * step(0.0, uv.y);
	col *= 1.0 - step(1.0, uv.x) * 1.0 - step(1.0, uv.y);

	// vignete 1
	//col *= 0.75 + 0.25*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);

	// vignete 2
	// float vig = (0.0 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
	//col *= vec3(pow(vig,0.3));

	// vignete 3
	float vig = (0.5 + 32.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
	col *= vec3(pow(vig,0.2));

	// slighly change colors
	//col *= vec3(1.05,0.95,1.05);
	
	// make it brighter
	col *= 1.1;

	// horizontal scanlines:
	// gues what is it
	float scanSpeed = 10.0;
	// bigger number - more scanlines
	float scanlinesNumber = 20.0;
	// scanline darkness
	float s_am = 0.0350;
	float s_b = 1.0 - s_am;
	col *= s_b + s_am*(sin(scanSpeed * iTime + 
										(uv.y*scanlinesNumber*3.14)));

	// // another way to do stripes
	// float dash = 10.0 / 640.0;
	// float space = dash;
	// step(0.0, dash - mod(uv.y + iTime, dash+space));

	// screen flickering
	float freq = 35.0*PI;			// PI is used to make it "per second"
	float f_am = 0.020;				// amplitude modulation
	float f_m = 1.0 - f_am;	
	col *= f_m + f_am*sin(freq*iTime);

	gl_FragColor = vec4(col, 1.0);
}