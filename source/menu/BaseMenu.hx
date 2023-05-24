package menu;

import djFlixel.ui.FlxMenu;
import menu.MenuUtils.setDefaultMenuStyle;

enum abstract MenuCommand(String) to String {
	var EXIT_GAME;
	var SWITCH_TO_MAIN_MENU;
}

@:forward
abstract BaseMenu(FlxMenu) to FlxMenu {

	public inline function new(x = 0, y = 0, width = 0, slots = 6) {
		this = new FlxMenu(x, y, width, slots);
		this.PAR.start_button_fire = true;
		setDefaultMenuStyle(this);
	}
}
