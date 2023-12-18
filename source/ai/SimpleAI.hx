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

	public var name:String;

	var timeToThink:Float = 0.1;
	var timer:Float;

	var tmprect1:FlxRect = FlxRect.get();
	var tmprect2:FlxRect = FlxRect.get();
	var tween:FlxTween;

	public function new(racket:Racket, ?name:String) {
		super(racket);

		this.name = name ?? 'simple AI';
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

		var ball = Pong.inst.room.ball;
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
					Flixel.watch.addQuick('${racket.position}: med ai t_Y', targetRacketY);

					if (tween != null)
						tween.cancel();

					var path = Math.abs(targetRacketY - racketBounds.y);
					var duration = path / Pong.params.racketSpeed;
					tween = Pong.inst.gameTweens.tween(racket, {y: targetRacketY}, duration, {ease: FlxEase.linear});
				case UP, DOWN:
					throw "Implement it later";
			}
		}

		timer += dt;
	}
}
