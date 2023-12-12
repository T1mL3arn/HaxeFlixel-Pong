// load custom texture example:
// https://www.shadertoy.com/view/lsGGDd

// other examples of "Barrel Distortion"
// https://www.shadertoy.com/view/4tVSRw
// https://www.shadertoy.com/view/lslGRN
// https://www.shadertoy.com/view/4sXcDN

#pragma header

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
	vec2 uv = openfl_TextureCoordv;
	uv = curve( uv );
	
	vec3 col;
	
	// Chromatic
	col.r = flixel_texture2D(bitmap, vec2(uv.x+0.002,uv.y)).x;
	col.g = flixel_texture2D(bitmap, vec2(uv.x+0.000,uv.y)).y;
	col.b = flixel_texture2D(bitmap, vec2(uv.x-0.002,uv.y)).z;

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
	float stripesSpeed = 20.0;
	// bigger factor - more stripes
	float stripesCountFactor = 400.0;
	col *= 0.9+0.125*sin(stripesSpeed * iTime + uv.y * stripesCountFactor);

	// add screen flickering
	col *= 0.99+0.075*sin(75.0*iTime);

	gl_FragColor = vec4(col, 1.0);
}