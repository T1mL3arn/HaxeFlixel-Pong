package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();
		addChild(new FlxGame(0, 0, PlayState));
	}
}

class Pong {

	public static final defaults = {
		ballSize: 16,
		racketLength: 100,
		racketThickness: 16,
		racketSpeed: 200.0,
		racketPadding: 30.0,
	}
}
