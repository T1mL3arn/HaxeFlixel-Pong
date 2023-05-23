package menu;

import djFlixel.ui.FlxMenu;
import flixel.FlxSubState;
import lime.app.Application;
import menu.MenuUtils.setDefaultMenuStyle;

class PauseMenu extends FlxSubState {

	var stateJustOpenned:Bool = false;

	public function new() {
		super();
	}

	override function create() {

		var menu = new BaseMenu(0, 0, 0);

		menu.createPage('main').add('
			-| resume | link | resume
			-| main menu | link | to_main
			-| exit game | link | exit_game
		').par({
				pos: 'screen,c,c'
			});

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

		openCallback = () -> stateJustOpenned = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!stateJustOpenned && Flixel.keys.anyJustPressed([ESCAPE, P]))
			this.close();

		stateJustOpenned = false;
	}
}
