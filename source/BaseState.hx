package;

import flixel.FlxSubState;
import menu.PauseMenu;

class BaseState extends FlxSubState {

	var canOpenPauseMenu:Bool = true;
	var pauseMenu:PauseMenu;

	override function create() {
		super.create();

		pauseMenu = new PauseMenu();
		destroySubStates = false;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (canOpenPauseMenu && Flixel.keys.anyJustPressed([ESCAPE, P])) {
			openSubState(pauseMenu);
		}
	}
}
