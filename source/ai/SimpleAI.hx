package ai;

import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class SimpleAI extends RacketController {

	var tmprect1 = new FlxRect();
	var tmprect2 = new FlxRect();

	var targetX:Float;
	var targetY:Float;

	/** This gets randomized! */
	var timeToRethink:Float = 0.1;

	var currentTimer:Float = 0;
	var tween:FlxTween;

	public function new(racket:Racket) {
		super(racket);

		targetX = Flixel.width * 0.5;
		targetY = Flixel.height * 0.5;
	}

	function getBall():Ball {
		return Reflect.getProperty(Flixel.state, 'ball');
	}

	override function update(dt) {

		var ball = getBall();
		if (ball == null)
			return;

		// throw the ball
		if (ball.velocity.lengthSquared == 0) {
			var angle = 60;

			ball.velocity.setPolarDegrees(Pong.defaults.ballSpeed, Flixel.random.float(-angle, angle));
			if (racket.position == RIGHT)
				ball.velocity.x *= -1;
		}

		// there is 10% percent change AI get distracted...
		if (Math.random() < 0.1)
			timeToRethink = 0.2 + Math.random() * 0.2;

		// check if it is time to rethink racket position
		if (currentTimer >= timeToRethink) {
			currentTimer = 0;
			// restore initial time in case AI was distracted
			timeToRethink = 0.1;
		}

		// get ball center Y
		// try to match racket center Y with it

		if (currentTimer == 0) {
			var ballBounds = ball.getHitbox(tmprect1);
			var racketBounds = racket.getHitbox(tmprect2);

			switch (racket.position) {
				case LEFT, RIGHT:
					var targetCenterY = (ballBounds.y + ballBounds.bottom) / 2;
					var targetRacketY = targetCenterY - racketBounds.height / 2;

					if (tween != null)
						tween.cancel();

					// 15% chance AI calculates position with small error
					final chance = 0.15;
					final error = Math.random() < chance ? 0.125 : 0.33;
					final variance = racket.height * 0.5 * error;
					targetRacketY = Flixel.random.float(targetRacketY - variance, targetRacketY + variance);

					var path = Math.abs(targetRacketY - racketBounds.y);
					var duration = path / Pong.defaults.racketSpeed;
					tween = FlxTween.tween(racket, {y: targetRacketY}, duration, {ease: FlxEase.linear});
				case UP, DOWN:
					// TODO
					0;
			}
		}

		currentTimer += dt;
	}
}
