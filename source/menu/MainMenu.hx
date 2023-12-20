package menu;

import Player.PlayerOptions;
import RacketController.KeyboardMovementController;
import Utils.swap;
import ai.AIFactory.setAIPlayer;
import ai.SimpleAI;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.sound.FlxSoundGroup;
import flixel.util.FlxColor;
import network_wrtc.Lobby1v1;
import room.AIRoom;
import room.SplitscreenRoom;
import room.TrainingRoom;
import room.TwoPlayersRoom;
import menu.BaseMenu.MenuCommand;
import menu.MenuUtils.wrapMenuPage;

using menu.MenuUtils;

class MainMenu extends FlxState {

	static final TRAINING_ROOM_MENU_ID = 'load_training_room';
	static final SELF_ROOM_MENU_ID = 'load_self_room';

	var players:Array<PlayerOptions>;
	var backGame:AIRoom;

	public function new() {
		super();

		players = [Reflect.copy(Player.defaultOptions), Reflect.copy(Player.defaultOptions)];
		players[1].getController = racket -> new SimpleAI(racket);
		players[1].name = 'simple AI';
		players[1].position = RIGHT;
	}

	override function create() {

		bgColor = 0xFF222222;

		var menu = new BaseMenu(0, 0, 0, 10);

		menu.createPage('main')
			.add(wrapMenuPage('PONG', '
				-| 1 player | link | @1_player
				-| multiplayer | link | @multiplayer_menu_page
		', ''))
			.addExitGameItem()
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage('1_player')
			.add(wrapMenuPage('Single Player', '
				-| vs AI | link | @ai_settings
				-| vs self | link | ${SELF_ROOM_MENU_ID}
				-| training room | link | ${TRAINING_ROOM_MENU_ID}
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

		menu.createPage('multiplayer_menu_page')
			.add(wrapMenuPage('multiplayer', '
				-| split screen | link | split_screen
				-| internet | link | internet
		'))
			.par({
				pos: 'screen,c,c'
			});

		menu.goto('main');
		menu.menuEvent.add((e, id) -> {
			switch ([e, id]) {
				case [it_fire, TRAINING_ROOM_MENU_ID]:
					Flixel.switchState(new TrainingRoom());

				case [it_fire, SELF_ROOM_MENU_ID]:
					Flixel.switchState(new TwoPlayersRoom({
						name: 'you',
						color: FlxColor.WHITE,
						position: LEFT,
					}, {
						name: 'also you',
						color: FlxColor.WHITE,
						position: RIGHT,
					}));

				case [it_fire, 'load_ai_room']:
					if (players[0].position == RIGHT)
						swap(players, 0, 1);
					Flixel.switchState(new TwoPlayersRoom(players[0], players[1]));

				case [it_fire, 'internet']:
					#if html5
					Flixel.switchState(new Lobby1v1());
					#end
					0;

				case [it_fire, 'split_screen']:
					Flixel.switchState(new SplitscreenRoom({
						// Flixel.switchState(new TwoPlayersRoom({
						name: 'left',
						position: LEFT,
						getController: racket -> new KeyboardMovementController(racket, W, S)
					}, {
						name: 'right',
						position: RIGHT,
						getController: racket -> new KeyboardMovementController(racket, UP, DOWN)
					}));

				default:
					0;
			}
		});

		menu.itemEvent.add((event, item) -> {
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
		});

		add(menu);

		// actually center main page on the screen
		menu.mpActive.forEach(s -> s.screenCenter(X));
		// TODO update menu class for better alignment?

		insert(0, backGame = new AIRoom(null, null, true));
		backGame.create();
		backGame.canOpenPauseMenu = false;
		iterSpriteDeep(backGame.members, s -> s.alpha = 0.5);
	}

	function iterSpriteDeep(list:Array<FlxBasic>, f:FlxSprite->Void) {
		for (obj in list) {
			if (obj is FlxSprite)
				f(cast obj);
			if (obj is FlxGroup)
				iterSpriteDeep((cast obj : FlxGroup).members, f);
		}
	}
}
