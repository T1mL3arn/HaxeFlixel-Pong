package;

import flixel.FlxState;
import flixel.util.FlxDirection;

class PlayState extends FlxState {

	var player:Racket;

	override public function create() {
		super.create();

		player = new Racket(100, 15, FlxDirection.RIGHT);
		player.screenCenter();

		add(player);
	}

	override public function update(elapsed:Float) {
		moveRacketByKeyboard(player);
		super.update(elapsed);
	}

	function moveRacketByKeyboard(racket:Racket) {
		racket.velocity.set(0, 0);

		var pressed = Flixel.keys.pressed;
		if (pressed.UP) {
			racket.velocity.setPolarDegrees(200, -90);
		}
		else if (pressed.DOWN) {
			racket.velocity.setPolarDegrees(200, 90);
		}
	}
}
