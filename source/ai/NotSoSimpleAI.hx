package ai;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
	This AI pretends to be not so smart:
		- its think timer is randomized sometiems (like it is distracted)
		- its racket positioning is randomized
**/
class NotSoSimpleAI extends RacketController {

	static final SETTINGS = {
		timeToThink: 0.09,
		timeToThinkMax: 0.18,
		distractedChance: 0.1,
		misscalcChance: 0.15,
		calcError: 0.15,
		calcErrorBig: 0.3,
	};

	var tmprect1 = FlxRect.get();
	var tmprect2 = FlxRect.get();

	var targetX:Float;
	var targetY:Float;

	/** This gets randomized! */
	var timeToThink:Float = 0.1;

	var currentTimer:Float = 0;
	var tween:FlxTween;

	public function new(racket:Racket) {
		super(racket);

		targetX = Flixel.width * 0.5;
		targetY = Flixel.height * 0.5;

		Pong.inst.ballCollision.add(ballCollision);
	}

	function ballCollision(obj:FlxObject, ball:Ball) {
		timeToThink = SETTINGS.timeToThink;
		currentTimer = 0;
	}

	override function destroy() {
		super.destroy();
		tmprect1.put();
		tmprect2.put();
		if (tween != null) {
			tween.cancel();
			tween.destroy();
		}
		Pong.inst.ballCollision.remove(ballCollision);
	}

	function getBall():Ball {
		return Reflect.getProperty(Flixel.state, 'ball');
	}

	override function update(dt) {

		// NOTE in its current form this AI is bad
		// at reflecting ball on sharp angles!
		var ball = getBall();
		if (ball == null)
			return;

		// check if it is time to rethink racket position
		if (currentTimer >= timeToThink) {
			currentTimer = 0;
			// there is a chance AI got distracted
			timeToThink = if (Math.random() < SETTINGS.distractedChance) {
				SETTINGS.timeToThink * 1.5 + Math.random() * SETTINGS.timeToThinkMax;
			}
			else {
				SETTINGS.timeToThink;
			}
		}

		if (currentTimer == 0) {
			var ballBounds = ball.getHitbox(tmprect1);
			var racketBounds = racket.getHitbox(tmprect2);

			switch (racket.position) {
				case LEFT, RIGHT:
					var targetCenterY = (ballBounds.y + ballBounds.bottom) / 2;
					var targetRacketY = targetCenterY - racketBounds.height / 2;

					if (tween != null)
						tween.cancel();

					final error = if (FlxMath.equal(ball.velocity.y, 0, 0.1)) {
						// if the ball moves horizontaly
						// 1. there is much time to think
						currentTimer = 0;
						timeToThink = Math.abs(Flixel.width * 0.8 / ball.velocity.x);
						// 2. AI has a lot of freedom in placing the racket
						Flixel.random.float(0.2, 0.99);
					}
					else {
						Math.random() < SETTINGS.misscalcChance ? SETTINGS.calcErrorBig : SETTINGS.calcError;
					}
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
