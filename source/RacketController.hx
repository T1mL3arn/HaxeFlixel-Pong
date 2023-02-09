package;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;

class RacketController extends FlxBasic {

	public var racket:FlxObject;

	public function new(racket:FlxObject) {
		super();
		this.racket = racket;
	}

	// public function update(?racket:FlxObject) {}
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

		if (Flixel.keys.checkStatus(keyUp, FlxInputState.PRESSED))
			this.racket.velocity.setPolarDegrees(this.speed, -90);
		else if (Flixel.keys.checkStatus(keyDown, FlxInputState.PRESSED))
			this.racket.velocity.setPolarDegrees(this.speed, 90);
	}
}
