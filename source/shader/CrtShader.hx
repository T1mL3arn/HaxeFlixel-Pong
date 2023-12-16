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

		this.iTime.value = [0.0];
	}

	public function update(time:Float) {

		this.iTime.value[0] += time;
	}
}
