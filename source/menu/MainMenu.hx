package menu;

import Player.PlayerOptions;
import Utils.swap;
import ai.AIFactory.setAIPlayer;
import ai.SimpleAI;
import djFlixel.ui.FlxMenu;
import flixel.FlxState;
import flixel.util.FlxColor;
import lime.app.Application;
import menu.MenuUtils.setDefaultMenuStyle;
import menu.MenuUtils.wrapMenuPage;
import network_wrtc.Lobby1v1;
import room.TrainingRoom;
import room.TwoPlayersRoom;

class MainMenu extends FlxState {

	static final TRAINING_ROOM_MENU_ID = 'load_training_room';
	static final SELF_ROOM_MENU_ID = 'load_self_room';

	var players:Array<PlayerOptions>;

	public function new() {
		super();

		players = [Reflect.copy(Player.defaultOptions), Reflect.copy(Player.defaultOptions)];
		players[1].getController = racket -> new SimpleAI(racket);
		players[1].name = 'simple AI';
		players[1].position = RIGHT;
	}

	override function create() {

		var menu = new FlxMenu(0, 0, 0, 10);

		menu.PAR.start_button_fire = true;

		menu.createPage('main')
			.add(wrapMenuPage('PONG', '
				-| 1 player | link | @1_player
				-| multiplayer | link | @multiplayer_menu_page
				-| exit game | link | exit_game
		', ''))
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage('1_player')
			.add(wrapMenuPage('Single Player', '
				-| training room | link | ${TRAINING_ROOM_MENU_ID}
				-| vs self | link | ${SELF_ROOM_MENU_ID}
				-| vs AI | link | @ai_settings
		'))
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage('ai_settings')
			.add(wrapMenuPage('Settngs', '
				-| your position | list | player_pos | left,right
				-| AI difficulty | list | ai_smarteness | easy,medium,hard
				-| * START * | link | load_ai_room
		'))
			.par({
				pos: 'screen,c,c'
			});

		setDefaultMenuStyle(menu);

		menu.createPage('multiplayer_menu_page')
			.add(wrapMenuPage('multiplayer', '
				-| split screen | link | split_screen
				-| internet | link | internet
		'))
			.par({
				pos: 'screen,c,c'
			});

		menu.goto('main');
		menu.onMenuEvent = (e, id) -> {
			switch ([e, id]) {
				case [it_fire, TRAINING_ROOM_MENU_ID]:
					Flixel.switchState(new TrainingRoom());

				case [it_fire, SELF_ROOM_MENU_ID]:
					Flixel.switchState(new TwoPlayersRoom({
						name: 'you',
						color: FlxColor.WHITE,
					}, {
						name: 'also you',
						color: FlxColor.WHITE,
					}));

				case [it_fire, 'exit_game']:
					// TODO remove this functionality for html5 target
					Application.current.window.close();

				case [it_fire, 'load_ai_room']:
					if (players[0].position == RIGHT)
						swap(players, 0, 1);
					Flixel.switchState(new TwoPlayersRoom(players[0], players[1]));

				case [it_fire, 'internet']:
					Flixel.switchState(new Lobby1v1());

				default:
					0;
			}
		}

		menu.onItemEvent = (event, item) -> {
			switch ([event, item.ID]) {
				case [change, 'player_pos']:
					var pos = item.P.list[item.P.c];
					if (pos == 'left') {
						players[0].position = LEFT;
						players[1].position = RIGHT;
					}
					else if (pos == 'right') {
						players[0].position = RIGHT;
						players[1].position = LEFT;
					}

				case [change, 'ai_smarteness']:
					var aiSmarteness = item.P.list[item.P.c];
					setAIPlayer(players[1], aiSmarteness);

				default:
					0;
			}
		}

		add(menu);
	}
}
