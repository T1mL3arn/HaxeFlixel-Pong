package;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class Ball extends FlxSprite {

	public var hitBy:FlxObject;

	public function new() {
		super();

		makeGraphic(Pong.defaults.ballSize, Pong.defaults.ballSize, FlxColor.WHITE);
		centerOrigin();
		screenCenter();
		elasticity = 1;
	}
}
