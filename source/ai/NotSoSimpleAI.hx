package ai;

import Utils.merge;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;

/**
	This AI pretends to be not so smart:
		- its think timer is randomized sometiems (like it is distracted)
		- its racket's target position get randomzied in some degree to immitate
			errors in movement

	NOTE in its current form this AI is bad
	at reflecting ball on sharp angles!
**/
class NotSoSimpleAI extends SimpleAI {

	public static final SETTINGS_DEFAULT = {
		timeToThink: 0.09,
		timeToThinkMax: 0.25,
		distractedChance: 0.2,
		misscalcChance: 0.2,
		calcError: 0.15,
		calcErrorBig: 0.3,
	};

	public static function buildEasyAI(racket, ?name:String) {
		var ai = new NotSoSimpleAI(racket, name ?? 'NotSoSimpleAI ez AI');
		ai.SETTINGS = merge({}, SETTINGS_DEFAULT);
		return ai;
	}

	public static function buildMediumAI(racket, ?name:String) {
		var ai = new NotSoSimpleAI(racket, name ?? 'NotSoSimpleAI med AI');
		ai.SETTINGS = {
			timeToThink: 0.08,
			timeToThinkMax: 0.20,
			distractedChance: 0.125,
			misscalcChance: 0.1,
			calcError: 0.1,
			calcErrorBig: 0.25,
		};
		return ai;
	}

	var targetX:Float;
	var targetY:Float;

	var currentTimer:Float = 0;

	var SETTINGS = SETTINGS_DEFAULT;

	public function new(racket:Racket, ?name:String) {
		super(racket, name ?? 'NOT simple AI');

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

	override function update(dt) {

		var ball = Pong.inst.room.ball;
		if (ball == null)
			return;

		// check if it is time to rethink racket position
		if (currentTimer >= timeToThink) {
			currentTimer = 0;
			// there is a chance AI got distracted
			timeToThink = if (Math.random() < SETTINGS.distractedChance) {
				SETTINGS.timeToThink * 1.25 + Math.random() * SETTINGS.timeToThinkMax;
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
					Flixel.watch.addQuick('${racket.position}:\n$name', targetRacketY);

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
					var duration = path / Pong.params.racketSpeed;
					tween = Pong.inst.gameTweens.tween(racket, {y: targetRacketY}, duration, {ease: FlxEase.linear});
				case UP, DOWN:
					throw "Implement it later";
			}
		}

		currentTimer += dt;
	}
}
