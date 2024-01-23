package state;

import menu.PauseMenu;

/**
	Basic gameplay state. Such states can open pause menu.
**/
class BaseGameState extends BaseState {

	//
	public var canOpenPauseMenu:Bool = true;

	var pauseMenu:PauseMenu;

	override function create() {
		super.create();

		pauseMenu = new PauseMenu();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (canOpenPauseMenu && Flixel.keys.anyJustPressed([ESCAPE, P])) {
			openSubState(pauseMenu);
		}

		/**
			NOTE: consider using separate update method (gameUpdate() or something)
			which is called after super.update(). This will allow to override
			gameUpdate() completely but preserve state.update().
		**/
	}
}
