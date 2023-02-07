package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

class PlayState extends FlxState {

	var player:Racket;
	var ball:FlxSprite;

	override public function create() {
		super.create();

		player = new Racket(100, 15, FlxDirection.RIGHT);
		player.screenCenter();
		player.x -= Flixel.width * 0.33;
		player.immovable = true;
		player.elasticity = 1;
		add(player);

		ball = new FlxSprite();
		ball.makeGraphic(15, 15, FlxColor.WHITE);
		ball.screenCenter();
		ball.velocity.set(-300, 0);
		ball.elasticity = 1;
		add(ball);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		moveRacketByKeyboard(player);
		Flixel.collide(player, ball, racketBallCollisionon);

		if (ball.x > Flixel.width) {
			ball.x = Flixel.width;
			ball.velocity.x *= -1;
		}
		if (ball.x < 0) {
			ball.x = 0;
			ball.velocity.x *= -1;
		}
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

	function racketBallCollisionon(racket:Racket, ball:FlxSprite) {
		// TODO some sound
	}
}
