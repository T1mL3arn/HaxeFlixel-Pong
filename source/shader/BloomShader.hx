package shader;

import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;

class BloomShader extends FlxShader {

	@:glFragmentSourceFile('./bloom.shader')
	//
	public function new() {
		super();

		// this.intensity.value = [0.15];
		// this.intensity.value = [0.15];
		// this.blurSize.value = [1.0 / 512.0];
		// this.blurSize.value = [1.0 / 128.0];
	}
}
