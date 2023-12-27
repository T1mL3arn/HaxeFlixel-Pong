package ai;

import flixel.math.FlxMath;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxTimer;

class BaseAI extends RacketController {

	public var name:String;

	var tween:VarTween;
	var timer:Float;
	var moveTimer:FlxTimer;

	public function new(racket:Racket, ?name:String) {
		super(racket);

		this.name = name ?? 'base AI';

		moveTimer = new FlxTimer();
	}

	var once = true;

	override function update(dt:Float) {
		//
		var ball = GAME.room.ball;

		if (ball == null)
			return;

		// check if it is time to rethink racket position
		if (timer >= 0.1) {
			timer = 0;
		}

		// if (timer == 0) {
		// 	calcTargetPosition();
		// }
		if (once) {
			calcTargetPosition();
			once = false;
		}

		timer += dt;
	}

	function calcTargetPosition() {
		//
		var ball = GAME.room.ball;
		switch (racket.position) {
			case LEFT, RIGHT:
				var targetCenterY = ball.y + ball.height * 0.5;
				var targetRacketY = targetCenterY - racket.height / 2;

				targetRacketY = FlxMath.lerp(ball.y + 1 - racket.height, ball.y + ball.height - 1, 0.2);

				var path = Math.abs(targetRacketY - racket.y);
				var duration = path / Pong.params.racketSpeed;

				racket.velocity.set(0, 0);
				if (racket.y < targetRacketY) {
					racket.velocity.y = Pong.params.racketSpeed;
					moveTimer.cancel();
					moveTimer.start(duration, _ -> {
						racket.velocity.set(0, 0);
						racket.y = targetRacketY;
					});
				}
				else {
					racket.velocity.y = -Pong.params.racketSpeed;
					moveTimer.cancel();
					moveTimer.start(duration, _ -> {
						racket.velocity.set(0, 0);
						racket.y = targetRacketY;
					});
				}

			case _:
				0;
		}
	}

	function stopRacket() {
		racket.velocity.set(0, 0);
	}
}
