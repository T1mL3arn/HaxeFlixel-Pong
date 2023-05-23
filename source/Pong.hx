package;

import flixel.FlxGame;
import flixel.FlxObject;
import flixel.util.FlxSignal;

typedef PongParams = {
	ballSize:Int,
	ballSpeed:Float,
	racketLength:Int,
	racketThickness:Int,
	racketSpeed:Float,
	racketPadding:Float,
};

class Pong extends FlxGame {

	public static var inst(get, never):Pong;

	static inline function get_inst():Pong
		return cast Flixel.game;

	public static final defaultParams:PongParams = {
		ballSize: 12,
		ballSpeed: 280,
		racketLength: 80,
		racketThickness: 12,
		racketSpeed: 225.0,
		racketPadding: 12.0,
	};

	public static var params:PongParams = Reflect.copy(defaultParams);

	public var ballCollision:FlxTypedSignal<(FlxObject, Ball) -> Void> = new FlxTypedSignal();
	public var state(get, never):{ball:Null<Ball>};

	inline function get_state()
		return cast Flixel.state;

	public function new() {
		super(0, 0);
	}
}
