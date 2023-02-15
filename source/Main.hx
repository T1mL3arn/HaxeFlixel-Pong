package;

import ai.SimpleAI;
import flixel.FlxGame;
import flixel.util.FlxDirection;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		addChild(new FlxGame(0, 0));

		// Flixel.switchState(new TwoPlayersRoom(null, {
		// 	position: FlxDirection.RIGHT,
		// 	getController: racket -> new SimpleAI(racket)
		// }));

		Flixel.switchState(new TwoPlayersRoom({
			position: FlxDirection.LEFT,
			getController: racket -> new SimpleAI(racket)
		}, {
			position: FlxDirection.RIGHT,
			getController: racket -> new SimpleAI(racket)
		}));
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
