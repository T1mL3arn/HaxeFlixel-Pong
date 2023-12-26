package;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import math.MathUtils.point;

using Utils;

class Ball extends FlxSprite {

	public var hitBy:FlxObject;

	var sounds:Array<FlxSound>;

	public function new() {
		super();

		makeGraphic(Pong.params.ballSize, Pong.params.ballSize, FlxColor.WHITE);
		color = FlxColor.RED;
		color = FlxColor.WHITE;
		centerOrigin();
		screenCenter();
		elasticity = 1;

		// TODO the faster ball moves, the higher the pitch should be
		sounds = [
			new FlxSound().loadEmbedded(AssetPaths.sfx_ball_collision_1__ogg),
			new FlxSound().loadEmbedded(AssetPaths.sfx_ball_collision_2__ogg),
			new FlxSound().loadEmbedded(AssetPaths.sfx_ball_collision_3__ogg),
			new FlxSound().loadEmbedded(AssetPaths.sfx_ball_collision_4__ogg),
		];
		for (sound in sounds)
			sound.volume = 0.75;
	}

	/**
		Returns ball's center coord in world.
		@param p 
	**/
	public inline function getWorldPos(?p:FlxPoint):FlxPoint {
		return (p ?? point()).set(x + width * 0.5, y + height * 0.5);
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
