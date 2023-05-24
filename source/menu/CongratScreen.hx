package menu;

import flixel.FlxSubState;
import menu.BaseMenu.MenuCommand;

using menu.MenuUtils;

class CongratScreen extends FlxSubState {

	override function create() {
		super.create();

		var bottomPadding = -Flixel.height * #if !html5 0.05 #else 0.1 #end;
		var menu = new BaseMenu(0, 0, 0, 4);
		menu.createPage('main')
			.add('
			-| play again | link | again
			-| main menu | link | $SWITCH_TO_MAIN_MENU
		')
			.addExitGameItem()
			.par({
				pos: 'screen,c,b',
				y: bottomPadding,
			});

		menu.goto('main');
		add(menu);

		this.openCallback = () -> trace('congrat screen is open');

		// TODO congratulations text (show player name)
		// TODO congrutulations cup image
		// TODO cognrats shoudl be above menu
		// TODO state has params controlling how "play again" works
	}
}
