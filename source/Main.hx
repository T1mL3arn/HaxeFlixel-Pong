package;

import ai.SimpleAI;
import flixel.util.FlxDirection;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		addChild(new Pong());

		// Flixel.switchState(new TwoPlayersRoom(null, {
		// 	position: FlxDirection.RIGHT,
		// 	getController: racket -> new SimpleAI(racket)
		// }));

		Flixel.switchState(new TwoPlayersRoom({
			position: FlxDirection.LEFT,
			name: 'simple-ai',
			color: 0xFF0075EB,
			getController: racket -> new SimpleAI(racket),
		}, {
			position: FlxDirection.RIGHT,
			name: 'simple-ai',
			color: 0xFFF1003C,
			getController: racket -> new SimpleAI(racket)
		}));
	}
}
