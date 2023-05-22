package;

import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;

class RacketController extends FlxBasic {

	public var racket:Racket;

	public function new(racket:Racket) {
		super();
		this.racket = racket;
	}
}

class KeyboardMovementController extends RacketController {

	// public var actionUp:FlxActionDigital;
	// public var actionDown:FlxActionDigital;
	public var keyUp:FlxKey;
	public var keyDown:FlxKey;

	public var speed:Float;

	public function new(racket, ?up:FlxKey = FlxKey.UP, ?down:FlxKey = FlxKey.DOWN, ?speed = 200.0) {
		super(racket);

		this.speed = speed;
		keyUp = up;
		keyDown = down;
	}

	override public function update(dt) {

		super.update(dt);

		racket.velocity.set(0, 0);

		var actionMoveUp = Flixel.keys.checkStatus(keyUp, PRESSED);
		var actionMoveDown = Flixel.keys.checkStatus(keyDown, PRESSED);

		// do nothing when both UP and DOWN are pressed
		if (actionMoveDown && actionMoveUp)
			return;

		if (actionMoveUp)
			racket.velocity.set(0, -speed);
		if (actionMoveDown)
			racket.velocity.set(0, speed);
	}
}
