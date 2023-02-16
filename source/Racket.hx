package;

import flixel.FlxSprite;
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
		switch (direction) {
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

	public function ballCollision(ball:FlxSprite) {
		// TODO
	}
}
