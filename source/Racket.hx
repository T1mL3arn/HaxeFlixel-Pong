package;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;
import flixel.util.FlxSpriteUtil;

typedef MovementsBounds = {
	x:Float,
	y:Float,
	right:Float,
	bottom:Float,
}

class Racket extends FlxSprite {

	public var direction:FlxDirection;

	public var movementBounds:MovementsBounds = null;
	public var movementController:Racket->Void = null;

	public function new(width:Int, height:Int, direction:FlxDirection = FlxDirection.UP) {
		super();

		this.direction = direction;

		switch (direction) {
			case UP, DOWN:
				makeGraphic(width, height, FlxColor.WHITE);
			case RIGHT, LEFT:
				makeGraphic(height, width, FlxColor.WHITE);
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

		// if (movementController != null)
		// 	movementController(this);

		if (movementBounds != null) {
			var b = movementBounds;
			FlxSpriteUtil.bound(this, b.x, b.right, b.y, b.bottom);
		}
	}
}
