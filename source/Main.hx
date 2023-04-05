package;

import ai.NotSoSimpleAI;
import ai.SimpleAI;
import djFlixel.D;
import flixel.util.FlxDirection;
import menu.MainMenu;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		D.init();

		addChild(new Pong());

		Flixel.switchState(new MainMenu());

		return;

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
