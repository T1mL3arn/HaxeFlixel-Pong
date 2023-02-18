package;

import flixel.FlxGame;

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
}
