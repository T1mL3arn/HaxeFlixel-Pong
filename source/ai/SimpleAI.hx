package ai;

import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxTimer;
import ai.BaseAI.BaseAI2;

/**
	Simple AI does not mean dumb AI. 
	Simple means:
		- Get ball center Y.
		- Try to match racket center Y coord with it.
	NOTE: This AI is not good when a ball comes at sharp adges.
**/
class SimpleAI345 extends BaseAI2 {

	var tmprect1:FlxRect = FlxRect.get();
	var tmprect2:FlxRect = FlxRect.get();

	var tweenProps = {y: 0.0};
	var tweenOptions = {
		ease: FlxEase.linear,
		onComplete: null,
		startDelay: 0.0,
	};

	public function new(racket:Racket, ?name:String) {
		super(racket, name ?? 'simple AI');

		timeToThink = 0.075;
		tweenOptions.onComplete = _ -> {
			tweenOptions.startDelay = 0;
			followBall(positionVariance);
		};

		var rnd = Flixel.random;
		// position variance timer
		new FlxTimer().start(rnd.float(1.5, 2.5), _ -> positionVariance = rnd.int(-95, 95) * 0.01, 0);
		// tween delay timer
		new FlxTimer().start(rnd.float(0.5, 1.5), _ -> {
			tweenOptions.startDelay = rnd.float() < 0.75 ? 0.0 : rnd.float(timeToThink * 0.3, timeToThink);
			followBall(positionVariance);
		}, 0);
	}

	override function destroy() {
		super.destroy();

		if (tween != null) {
			tween.cancel();
			tween.destroy();
		}
		tmprect1.put();
		tmprect2.put();
	}

	override function update(dt:Float) {

		var ball = GAME.room.ball;
		if (ball == null)
			return;

		// check if it is time to rethink racket position
		if (timer >= timeToThink) {
			timer = 0;
		}

		if (timer == 0) {
			followBall(positionVariance);
		}

		timer += dt;
	}

	/**
		@param variance value in range [-1.0, 1.0]
	**/
	function followBall(variance:Float = 0.0) {
		// instruct the racket to follow the ball
		var ball = GAME.room.ball;

		switch (racket.position) {
			case LEFT, RIGHT:
				// var min = ball.y + 1 - racket.height;
				// var max = ball.y + ball.height - 1;
				// HZ (hitzone) = max - min
				var HZ = racket.height + ball.height - 2;

				variance = (variance + 1.0) * 0.5;
				variance = FlxMath.bound(variance, 0.0, 1.0);
				var targetRacketY = FlxMath.lerp(ball.y + 1 - racket.height, ball.y + ball.height - 1, variance);

				var path = Math.abs(targetRacketY - racket.y);
				var duration = path / Pong.params.racketSpeed;
				tweenProps.y = targetRacketY;

				if (tween != null)
					tween.cancel();

				tween = GAME.aiTweens.tween(racket, tweenProps, duration, tweenOptions);

			case _:
				throw "Implement it later";
		}
	}
}
