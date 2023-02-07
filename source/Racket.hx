package;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

class Racket extends FlxSprite {

	public var direction:FlxDirection;

	public function new(width:Int, height:Int, direction:FlxDirection = FlxDirection.UP) {
		super();

		this.direction = direction;
		makeGraphic(width, height, FlxColor.WHITE);

		switch (direction) {
			case UP:
				angle = 0;
			case RIGHT:
				angle = 90;
			case DOWN:
				angle = 180;
			case LEFT:
				angle = 270;
		}

		updateHitboxRotation();
	}

	function updateHitboxRotation() {
		switch (direction) {
			case LEFT, RIGHT:
				setSize(height, width);
				centerOffsets(false);
			case UP, DOWN:
				0;
		}
	}
}
