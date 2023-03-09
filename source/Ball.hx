package;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.util.FlxColor;

using Utils;

class Ball extends FlxSprite {

	public var hitBy:FlxObject;

	var sounds:Array<FlxSound>;

	public function new() {
		super();

		makeGraphic(Pong.defaults.ballSize, Pong.defaults.ballSize, FlxColor.WHITE);
		color = FlxColor.RED;
		color = FlxColor.WHITE;
		centerOrigin();
		screenCenter();
		elasticity = 1;

		// TODO the faster ball moves, the higher the pitch should be
		sounds = [
			new FlxSound().loadEmbedded(AssetPaths.sfx_4360_4948_lq__freesound__ogg),
			new FlxSound().loadEmbedded(AssetPaths.sfx_4370_4948_lq__freesound__ogg),
			new FlxSound().loadEmbedded(AssetPaths.sfx_4382_4948_lq__freesound__ogg),
			new FlxSound().loadEmbedded(AssetPaths.sfx_4391_4948_lq__freesound__ogg),
		];
		for (sound in sounds)
			sound.volume = 0.75;
	}

	override function destroy() {
		super.destroy();

		for (sound in sounds)
			sound.destroy();
	}

	public function collision(target:FlxObject) {
		if (target is Racket)
			hitBy = target;

		playRandomCollisionSound();
	}

	public function playRandomCollisionSound() {
		var ind = Flixel.random.int(1, sounds.length - 1) - 1;
		var sound = sounds[ind];
		sound.play();
		sounds.swap(ind, sounds.length - 1);
	}
}
