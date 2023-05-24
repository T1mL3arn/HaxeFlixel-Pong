package menu;

import flixel.FlxBasic;
import flixel.FlxSubState;

using menu.MenuUtils;

class CongratScreen extends FlxSubState {

	override function create() {
		super.create();

		var menu = new BaseMenu(0, 0, 0, 4);
		menu.createPage('main')
			.add('
			-| play again | link | again
			-| main menu | link | to_main
		')
			.addExitGameItem()
			.par({
				pos: 'screen,c,b',
				y: Flixel.height * -0.05,
			});

		menu.goto('main');
		add(menu);

		this.openCallback = () -> trace('congrat screen is open');

		// TODO congratulations text (show player name)
		// TODO congrutulations cup image
		// TODO cognrats shoudl be above menu
		// TODO state has params controlling how "play again" works
	}

	function testType<T:FlxBasic>(obj:T):T {
		return obj;
	}
}
