package;

import Utils.invLerp;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;
import flixel.util.FlxSpriteUtil;

typedef MovementBounds = {
	left:Float,
	top:Float,
	right:Float,
	bottom:Float,
}

typedef RacketOptions = {
	direction:FlxDirection,
	size:Int,
	thickness:Int,
	color:FlxColor,
}

class Racket extends FlxSprite {

	@:deprecated("use `position` instead")
	public var direction(get, never):FlxDirection;

	inline function get_direction():FlxDirection
		return this.position;

	public var position:FlxDirection;
	public var movementBounds:MovementBounds = null;
	public var movementController:Racket->Void = null;

	var updatesCounter:Int;

	public function new(options:RacketOptions) {
		super();

		position = options.direction;

		immovable = true;
		elasticity = 1;

		switch (position) {
			case UP, DOWN:
				makeGraphic(options.size, options.thickness, options.color);
				allowCollisions = UP | DOWN;
			case RIGHT, LEFT:
				makeGraphic(options.thickness, options.size, options.color);
				allowCollisions = LEFT | RIGHT;
		}

		centerOrigin();
		centerOffsets(true);

		Flixel.signals.postUpdate.add(onPostUpdate);
	}

	function onPostUpdate() {
		updatesCounter = 0;
	}

	override function destroy() {
		Flixel.signals.postUpdate.remove(onPostUpdate);
		super.destroy();
	}

	@:deprecated
	function updateHitboxRotation() {
		// NOTE updates hitbox to match ortogonal rotation.
		// At this moment is not needed.
		switch (position) {
			case LEFT, RIGHT:
				setSize(height, width);
				centerOffsets(false);
			case UP, DOWN:
				0;
		}
	}

	override function update(time:Float) {

		// NOTE a crunch to disable double updating.
		// Double-updating happens when the same object
		// appears twice in update cycles. Like the object
		// was added to the state itself and also
		// the object is added to some group which in turn
		// is also added to state.
		if (updatesCounter > 0) {
			trace('double update of Racket!');
			return;
		}

		updatesCounter += 1;

		// isTouching() and justTouched() must be called BEFORE
		// calling `super.update()`

		super.update(time);

		if (movementBounds != null) {
			var b = movementBounds;
			FlxSpriteUtil.bound(this, b.left, b.right, b.top, b.bottom);
		}
	}

	var r1 = FlxRect.get();

	public function ballCollision(ball:FlxSprite) {
		bouncingClassic(ball);
	}

	function bouncingClassic(ball:FlxSprite) {
		// the classic pong ball bouncing
		var paddleBounds = this.getHitbox(r1);

		switch (position) {
			case LEFT, RIGHT:
				// 1. what part of a racket the ball hit (normalized value)
				var hitFactor = invLerp(paddleBounds.y - ball.height, paddleBounds.bottom, ball.y);
				hitFactor = FlxMath.bound(hitFactor, 0.1, 1.0);
				// 2. use this factor to get speed scale:
				// lerp gives value in range [-4, 3]
				// Factor will never be 0,
				// thus ceiling gives step value in range [-3, 3],
				// in total 7 integers are available.
				var speedScale = Math.ceil(FlxMath.lerp(-4, 3, hitFactor));

				// [-3,3] range gives 7 values in total,
				// so to limit bounce angle in 120 degrees
				// I calc it like 120/7 ~ 17.
				var angleStep = 17;
				// Since there are 7 regions to alter ball's speed,
				// let's use 1/7 of the current ball's speed as addition.
				// This gives the maximum available added speed (at the paddle corner)
				// to be 3/7 of the current ball's speed (almost a half).
				final speedModPerStep = Pong.params.ballSpeed / 7;
				final magnitude = Pong.params.ballSpeed + Math.abs(speedScale * speedModPerStep);
				final angle = angleStep * speedScale;
				ball.velocity.setPolarDegrees(magnitude, angle);
				if (position == RIGHT)
					ball.velocity.x *= -1;
			case UP, DOWN:
				throw "Implement it later";
		}
	}
}
