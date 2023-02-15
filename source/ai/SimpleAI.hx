package ai;

import Main.Pong;
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
		if (ball == null || ball.velocity.lengthSquared == 0)
			return;

		// there is 10% percent change AI get distracted...
		if (Math.random() < 0.1)
			timeToRethink = 0.15 + Math.random() * 0.2;

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

			switch (racket.direction) {
				case LEFT, RIGHT:
					var targetCenterY = (ballBounds.y + ballBounds.bottom) / 2;
					var targetRacketY = targetCenterY - racketBounds.height / 2;

					if (tween != null)
						tween.cancel();

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
