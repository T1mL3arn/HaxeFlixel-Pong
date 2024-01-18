package racket;

import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;

@:build(utils.BuildMacro.addField_GAME())
class RacketController extends FlxBasic {

	public var racket:Racket;

	public function new(racket:Racket) {
		super();
		this.racket = racket;
	}
}
