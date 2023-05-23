package;

import flixel.FlxSubState;
import menu.PauseMenu;

class BaseState extends FlxSubState {

	/** 
		Wether an openned substate (like PauseMenu) actually pauses the game, `true` by default.
		If you want to update your game while pause menu is open set it to `false`.
	**/
	public var canPause(default, set):Bool;

	function set_canPause(v:Bool):Bool {
		persistentUpdate = !v;
		return canPause = v;
	}

	var canOpenPauseMenu:Bool = true;
	var pauseMenu:PauseMenu;

	public function new() {
		super();
		canPause = true;
	}

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
