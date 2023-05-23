package ai;

import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
	Simple AI does not mean dumb AI. 
	Simple means:
		- Get ball center Y.
		- Try to match racket center Y coord with it.
	NOTE: This AI is not good when a ball comes at sharp adges.
**/
class SimpleAI extends RacketController {

	var timeToThink:Float = 0.1;
	var timer:Float;

	var tmprect1:FlxRect = FlxRect.get();
	var tmprect2:FlxRect = FlxRect.get();
	var tween:FlxTween;

	public function new(racket:Racket) {
		super(racket);
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

		var ball = Pong.inst.state.ball;
		if (ball == null)
			return;

		// check if it is time to rethink racket position
		if (timer >= timeToThink) {
			timer = 0;
		}

		if (timer == 0) {
			var ballBounds = ball.getHitbox(tmprect1);
			var racketBounds = racket.getHitbox(tmprect2);

			switch (racket.position) {
				case LEFT, RIGHT:
					var targetCenterY = (ballBounds.y + ballBounds.bottom) / 2;
					var targetRacketY = targetCenterY - racketBounds.height / 2;

					if (tween != null) {
						tween.cancel();
						tween.destroy();
					}

					var path = Math.abs(targetRacketY - racketBounds.y);
					var duration = path / Pong.params.racketSpeed;
					tween = FlxTween.tween(racket, {y: targetRacketY}, duration, {ease: FlxEase.linear});
				case UP, DOWN:
					// TODO
					0;
			}
		}

		timer += dt;
	}
}
