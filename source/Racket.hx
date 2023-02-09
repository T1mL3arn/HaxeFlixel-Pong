package;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

class Racket extends FlxSprite {

	public var direction:FlxDirection;

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
}
