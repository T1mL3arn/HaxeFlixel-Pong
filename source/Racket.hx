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

	public var direction:FlxDirection;

	public var movementBounds:MovementBounds = null;
	public var movementController:Racket->Void = null;

	public function new(options:RacketOptions) {
		super();

		this.direction = options.direction;

		immovable = true;
		elasticity = 1;

		switch (direction) {
			case UP, DOWN:
				makeGraphic(options.size, options.thickness, options.color);
				allowCollisions = UP | DOWN;
			case RIGHT, LEFT:
				makeGraphic(options.thickness, options.size, options.color);
				allowCollisions = LEFT | RIGHT;
		}

		centerOrigin();
		centerOffsets(true);
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
