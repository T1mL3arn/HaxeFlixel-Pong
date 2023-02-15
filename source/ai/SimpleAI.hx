package ai;

import Main.Pong;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

abstract Bounds(Array<Float>) from Array<Float> {
	public var min(get, set):Float;
	public var max(get, set):Float;

	inline function get_min()
		return this[0];

	inline function set_min(v)
		return this[0] = v;

	inline function get_max()
		return this[1];

	inline function set_max(v)
		return this[1] = v;
}

class SimpleAI extends RacketController {

	var tmprect1 = new FlxRect();
	var tmprect2 = new FlxRect();

	var boundsX:Bounds;
	var boundsY:Bounds;

	var targetX:Float;
	var targetY:Float;

	/** This gets randomized! */
	var timeToRethink:Float = 0.1;

	var currentTimer:Float = 0;
	var tween:FlxTween;

	public function new(racket:Racket) {
		super(racket);

		boundsX = [0, Flixel.height];
		boundsY = [0, Flixel.width];

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

	// function updateOld(dt) {
	// 	var ball = getBall();
	// 	if (ball == null || FlxMath.equal(ball.velocity.lengthSquared, 0, 0.1))
	// 		return;
	// 	// check if it is time to rethink racket position
	// 	if (currentTimer >= timeToRethink) {
	// 		currentTimer = 0;
	// 		var factor = invLerp(Flixel.width, 0, ball.x);
	// 		var upperBound = FlxMath.lerp(0.1, 0.3, factor);
	// 		timeToRethink = Flixel.random.float(0.1, upperBound);
	// 		trace('upperBound: $upperBound');
	// 	}
	// 	// ten times in sec recalc new ball pos
	// 	// 2 times in sec
	// 	// get ball boundaries (screen or world) BB
	// 	// get racket boundaries (screen or world) RB
	// 	// calc target racket position RT:
	// 	//   RT must overlap BB
	// 	var ballBounds = ball.getHitbox(tmprect1);
	// 	var racketBounds = racket.getHitbox(tmprect2);
	// 	// calculate racket target position
	// 	switch (racket.direction) {
	// 		case LEFT, RIGHT:
	// 			// Getting bounds of available space to maneuver
	// 			// to hit the ball.
	// 			var top = ballBounds.top + 1 - racketBounds.height;
	// 			var bottom = ballBounds.bottom - 1 + racketBounds.height;
	// 			var topY = top;
	// 			var bottomY = bottom - racketBounds.height;
	// 			targetY = Flixel.random.float(topY, bottomY);
	// 		case UP, DOWN:
	// 			// TODO
	// 			0;
	// 	}
	// 	// Racket target pos updates constantly,
	// 	// but applies on `timeToRethink` interval!
	// 	if (currentTimer == 0) {
	// 		trace('rethink');
	// 		if (tween != null)
	// 			tween.cancel();
	// 		// trace(targetY, racket.y, racketBounds.y);
	// 		var path = Math.abs(targetY - racketBounds.y);
	// 		var duration = path / Pong.defaults.racketSpeed;
	// 		// trace('time to traverse $path px is $duration');
	// 		tween = FlxTween.tween(racket, {y: targetY}, duration, {ease: FlxEase.linear});
	// 	}
	// 	currentTimer += dt;
	// }
}
