package menu;

import Player.PlayerOptions;
import Utils.swap;
import ai.AIFactory.ais;
import ai.AIFactory.setAIPlayer;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import netplay.Lobby1v1;
import racket.KeyboardMovementController;
import room.AIRoom;
import room.SplitscreenRoom;
import room.TrainingRoom;
import room.TwoPlayersRoom;
import ui.GithubRepoLink;
import menu.BaseMenu.MenuCommand;
import menu.MenuUtils.wrapMenuPage;

using menu.MenuUtils;

class MainMenu extends state.BaseState {

	static final TRAINING_ROOM_MENU_ID = 'load_training_room';
	static final SELF_ROOM_MENU_ID = 'load_self_room';
	static final VS_AI_SETTINGS_MENU_ID = 'player-vs-ai-settings';
	static final NETPLAY_MENU_ID = 'netplay';
	static final NETPLAY_MENU_LABEL = #if html5 'internet' #elseif desktop 'local net' #else '' #end;

	var backGame:AIRoom;

	public function new() {
		super();

		canPause = false;
	}

	override function create() {

		GAME.peer?.destroy();
		GAME.peer = null;

		super.create();

		var mainMenu = new BaseMenu(0, 0, 0, 10);

		mainMenu.createPage('main')
			.add(wrapMenuPage('PONG', '
				-| 1 player | link | @1_player
				-| 2 players | link | @multiplayer_menu_page
		', ''))
			.addExitGameItem()
			.par({
				pos: 'screen,c,c'
			});

		mainMenu.createPage('1_player')
			.add(wrapMenuPage('Single Player', '
				-| vs AI | link | @${VS_AI_SETTINGS_MENU_ID}
				-| vs self | link | ${SELF_ROOM_MENU_ID}
				-| training room | link | ${TRAINING_ROOM_MENU_ID}
		'))
			.par({
				pos: 'screen,c,c'
			});

		mainMenu.createPage(VS_AI_SETTINGS_MENU_ID)
			.add(wrapMenuPage('Settings', '
				-| your position | list | player_pos | left,right
				-| AI difficulty | list | ai_smarteness | ${ais.join(',')}
				-| * START * | link | load_ai_room
		'))
			.par({
				pos: 'screen,c,c'
			});

		mainMenu.createPage('multiplayer_menu_page')
			.add(wrapMenuPage('2 players', '
				-| split screen | link | split_screen
				-| ${NETPLAY_MENU_LABEL} | link | ${NETPLAY_MENU_ID}
		'))
			.par({
				pos: 'screen,c,c'
			});

		mainMenu.goto('main');


		mainMenu.menuEvent.add((e, id) -> {
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
					var players = [Reflect.copy(Player.defaultOptions), Reflect.copy(Player.defaultOptions)];
					players[0].name = 'YOU';
					players[0].position = LEFT;
					players[1].position = RIGHT;

					var settings = mainMenu.pages[VS_AI_SETTINGS_MENU_ID];
					var playerPos:String = settings.get('player_pos').get();
					var aiType:String = settings.get('ai_smarteness').get();

					// update player options
					// swap if player chose RIGHT pos
					if (playerPos.toLowerCase() == 'left') {
						players[0].position = LEFT;
						players[1].position = RIGHT;
						setAIPlayer(players[1], aiType);
					}
					else {
						players[0].position = RIGHT;
						players[1].position = LEFT;
						setAIPlayer(players[1], aiType);
						swap(players, 0, 1);
					}

					Flixel.switchState(new TwoPlayersRoom(players[0], players[1]));

				case [it_fire, NETPLAY_MENU_ID]:
					#if (html5 || desktop)
					Flixel.switchState(new Lobby1v1());
					#else
					trace('not implemented');
					#end

				case [it_fire, 'split_screen']:
					Flixel.switchState(new SplitscreenRoom({
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

		uiObjects.add(mainMenu);

		// actually center main page on the screen
		mainMenu.mpActive?.forEach(s -> s.screenCenter(X));
		// TODO update menu class for better alignment?

		// menu.menuEvent.dispatch(it_fire, SELF_ROOM_MENU_ID);
		// menu.menuEvent.dispatch(it_fire, 'split_screen');
		// menu.menuEvent.dispatch(it_fire, 'internet');

		// github button
		var repoLink = new GithubRepoLink();
		repoLink.x = Flixel.width - 16 - repoLink.width;
		repoLink.y = Flixel.height - 16 - repoLink.height;
		uiObjects.add(repoLink);

		gameObjects.add(backGame = new AIRoom('medium', 'easy', true));
		backGame.create();
		backGame.canOpenPauseMenu = false;
		iterSpriteDeep(backGame.members, s -> s.alpha = 0.5);
		GAME.signals.substateOpened.dispatch(backGame, this);
		GAME.gameSoundGroup.volume = 0.2;
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
