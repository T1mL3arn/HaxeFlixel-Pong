package shader;

import flixel.system.FlxAssets.FlxShader;

class PixelateShader extends FlxShader {

	@:glFragmentSourceFile('./pixelate.shader')
	//
	public function new() {
		super();

		iScreenSize.value = [Flixel.width, Flixel.height];
		iTime.value = [0.0];
		// iRand.value = [Flixel.random.float(0, 1)];
	}

	public function update(time:Float) {

		this.iTime.value[0] += time;
		// this.iRand.value[0] = Flixel.random.float(0, 1);
	}
}
