package shader;

import flixel.system.FlxAssets.FlxShader;

/**
	CRT screen emulation.
	NOTE: Another crt shader https://github.com/Geokureli/Advent2020/blob/master/source/vfx/CrtShader.hx
**/
class CrtShader extends FlxShader {

	@:glFragmentSourceFile('./crt-effect.shader')
	//
	public function new() {
		super();

		/* 
			Current way of reading shader content didn't work for me, I tried to fix it. 

			(trying to use Codespaces to push suggestions)
		 */

		// NOTE it is parsed by Haxe Macro from shader code
		this.iTime.value = [0.0];

		// shader distortion shit
		// https://discord.com/channels/162395145352904705/165234904815239168/1044303305108639834
		// https://dixonary.co.uk/blog/shadertoy#a-couple-of-gotchas

		/*
			let smoothstep = (a,b,v) => {
			let t = (v-a)/(b-a);
			t = Math.max(0.0, t);
			t = Math.min(t, 1.0);
			return t*t*(3.0 - 2.0*t);
			}
		 */
	}

	public function update(time:Float) {
		this.iTime.value[0] += time;
	}
}
