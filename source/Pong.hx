package;

import flixel.FlxGame;
import flixel.FlxObject;
import flixel.util.FlxSignal;

class Pong extends FlxGame {

	public static var inst(get, never):Pong;

	static inline function get_inst():Pong
		return cast Flixel.game;

	public static final defaults = {
		ballSize: 12,
		ballSpeed: 300,
		racketLength: 80,
		racketThickness: 12,
		racketSpeed: 225.0,
		racketPadding: 12.0,
	}

	public var ballCollision:FlxTypedSignal<(FlxObject, Ball) -> Void> = new FlxTypedSignal();
	public var state(get, never):{ball:Null<Ball>};

	inline function get_state()
		return cast Flixel.state;

	public function new() {
		super(0, 0);
	}
}
