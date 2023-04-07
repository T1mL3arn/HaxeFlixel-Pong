package;

import flixel.FlxState;
import menu.PauseMenu;

class BaseState extends FlxState {

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.anyJustPressed([ESCAPE, P])) {
			openSubState(new PauseMenu());
		}
	}
}
