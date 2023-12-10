package shader;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.Shader;

/**
	CRT screen emulation
**/
class CrtShader extends FlxShader {

	@:glFragmentSource('
#pragma header

uniform float iTime;

vec2 curve(vec2 uv)
{
	uv = (uv - 0.5) * 2.0;
	uv *= 1.1;	
	uv.x *= 1. + pow((abs(uv.y) / 5.0), 2.);
	uv.y *= 1. + pow((abs(uv.x) / 5.0), 2.);
	uv  = (uv / 2.0) + 0.5;
	uv =  uv*0.92 + 0.04;
	return uv;
}

void main( /*out vec4 fragColor, in vec2 fragCoord */)
{
	// initial shader uv
	// vec2 uv = fragCoord.xy / iResolution.xy;

	// openfl way for fragCoord and uv
	vec2 fragCoord = openfl_TextureCoordv;
	vec2 uv = openfl_TextureCoordv;
	//Curve
	uv = curve( uv );
	
	vec3 col;
	
	// Chromatic
	col.r = flixel_texture2D(bitmap, vec2(uv.x+0.003,uv.y)).x;
	col.g = flixel_texture2D(bitmap, vec2(uv.x-0.001,uv.y)).y;
	col.b = flixel_texture2D(bitmap, vec2(uv.x+0.003,uv.y)).z;

	// hide parts out of the original texture
	col *= step(0.0, uv.x) * step(0.0, uv.y);
	col *= 1.0 - step(1.0, uv.x) * 1.0 - step(1.0, uv.y);

	// make it darker on edges
	//col *= 0.75 + 0.25*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
	// slighly change colors
	//col *= vec3(1.05,0.95,1.05);
	
	// make it brighter
	col *= 1.1;

	// stripes
	float stripesSpeed = 15.0;
	float stripesSize = 250.0;
	col *= 0.9+0.25*sin(stripesSpeed * iTime + uv.y * stripesSize);

	// add screen flickering
	col *= 0.99+0.075*sin(75.0*iTime);

	// fragColor = vec4(col,1.0);
	gl_FragColor = vec4(col, 1.0);
}
    ')
	public function new() {
		super();

		// NOTE it is parsed by Haxe Macro from shader code
		this.iTime.value = [0.0];
	}

	public function update(time:Float) {
		this.iTime.value[0] += time;
	}
}
