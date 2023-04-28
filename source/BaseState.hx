package;

import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;
import menu.PauseMenu;

class BaseState extends FlxSubState {

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.anyJustPressed([ESCAPE, P])) {
			// TODO instead of messing with input states
			// better ignore the input on first frame inside PauseMenu state
			@:privateAccess Flixel.keys._keyListMap.get(FlxKey.ESCAPE).reset();
			@:privateAccess Flixel.keys._keyListMap.get(FlxKey.P).reset();
			openSubState(new PauseMenu());
		}
	}
}
