package menu;

import flixel.FlxSubState;
import lime.app.Application;
import menu.BaseMenu.MenuCommand;

using menu.MenuUtils;

class PauseMenu extends FlxSubState {

	var stateJustOpenned:Bool = false;

	public function new() {
		super();
	}

	override function create() {

		var menu = new BaseMenu(0, 0, 0);

		menu.createPage('main')
			.add('
			-| resume | link | resume
			-| main menu | link | $SWITCH_TO_MAIN_MENU
		')
			.addExitGameItem()
			.par({
				pos: 'screen,c,c'
			});

		menu.goto('main');

		menu.menuEvent.add((e, id) -> {
			switch ([e, id]) {
				case [it_fire, 'resume']:
					this.close();

				case [it_fire, SWITCH_TO_MAIN_MENU]:
					Flixel.switchState(new MainMenu());

				default:
					0;
			}
		});

		add(menu);

		openCallback = () -> stateJustOpenned = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!stateJustOpenned && Flixel.keys.anyJustPressed([ESCAPE, P]))
			this.close();

		stateJustOpenned = false;
	}
}
