package menu;

import djFlixel.ui.FlxMenu;
import flixel.FlxSubState;
import lime.app.Application;

class PauseMenu extends FlxSubState {

	public function new() {
		super();
	}

	override function create() {

		var menu = new FlxMenu(0, Flixel.game.height / 2 - 100, -1);

		menu.PAR.start_button_fire = true;

		menu.createPage('main').add('
		-| resume | link | resume
		-| main menu | link | to_main
		-| exit game | link | exit_game
		');

		MenuStyle.setDefaultStyle(menu);

		menu.goto('main');

		menu.onMenuEvent = (e, id) -> {
			switch ([e, id]) {
				case [it_fire, 'resume']:
					this.close();

				case [it_fire, 'to_main']:
					Flixel.switchState(new MainMenu());

				case [it_fire, 'exit_game']:
					Application.current.window.close();

				default:
					0;
			}
		}

		add(menu);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.anyJustPressed([ESCAPE, P]))
			this.close();
	}
}
