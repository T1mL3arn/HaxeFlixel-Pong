package;

import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import menu.PauseMenu;

class BaseState extends FlxState {

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.anyJustPressed([ESCAPE, P])) {
			@:privateAccess Flixel.keys._keyListMap.get(FlxKey.ESCAPE).reset();
			@:privateAccess Flixel.keys._keyListMap.get(FlxKey.P).reset();
			openSubState(new PauseMenu());
		}
	}
}
