package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();
		// addChild(new FlxGame(0, 0, TrainingRoom));
		addChild(new FlxGame(0, 0));
		Flixel.switchState(new TwoPlayersRoom());
	}
}

class Pong {

	public static final defaults = {
		ballSize: 16,
		racketLength: 100,
		racketThickness: 16,
		racketSpeed: 200.0,
		racketPadding: 16.0,
	}
}
