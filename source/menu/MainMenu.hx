package menu;

import RacketController.KeyboardMovementController;
import djFlixel.ui.FlxMenu;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;
import lime.app.Application;

class MainMenu extends FlxState {

	static final TRAINING_ROOM_MENU_ID = 'training_room';
	static final SELF_ROOM_MENU_ID = 'self';

	public function new() {
		super();
	}

	override function create() {

		var menu = new FlxMenu(0, Flixel.game.height / 2 - 100, -1);

		menu.PAR.start_button_fire = true;

		menu.createPage('main').add('
		-| 1 player | link | @1_player
		-| multiplayer | link | opts
		-| exit game | link | exit_game
		');

		menu.createPage('1_player')
			.add('
		-| training room | link | ${TRAINING_ROOM_MENU_ID}
		-| vs self | link | ${SELF_ROOM_MENU_ID}
		-| vs AI | link | ai
		-| go back | link | @back
		');

		MenuStyle.setDefaultStyle(menu);

		menu.goto('main');
		menu.onMenuEvent = (e, id) -> {
			switch ([e, id]) {
				case [it_fire, TRAINING_ROOM_MENU_ID]:
					Flixel.switchState(new TrainingRoom());

				case [it_fire, SELF_ROOM_MENU_ID]:
					Flixel.switchState(new TwoPlayersRoom({
						position: FlxDirection.LEFT,
						name: 'you',
						color: FlxColor.WHITE,
						getController: racket -> new KeyboardMovementController(racket),
					}, {
						position: FlxDirection.RIGHT,
						name: 'also you',
						color: FlxColor.WHITE,
						getController: racket -> new KeyboardMovementController(racket),
					}));

				case [it_fire, 'exit_game']:
					Application.current.window.close();

				default:
					0;
			}
		}

		add(menu);
	}
}
