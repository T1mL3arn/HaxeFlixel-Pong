package menu;

import Player.PlayerOptions;
import RacketController.KeyboardMovementController;
import Utils.swap;
import ai.AIFactory.ais;
import ai.AIFactory.setAIPlayer;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.sound.FlxSoundGroup;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import lime.system.System;
import math.MathUtils.p;
import network_wrtc.Lobby1v1;
import room.AIRoom;
import room.SplitscreenRoom;
import room.TrainingRoom;
import room.TwoPlayersRoom;
import menu.BaseMenu.MenuCommand;
import menu.MenuUtils.wrapMenuPage;

using menu.MenuUtils;

@:build(utils.BuildMacro.addField_GAME())
class MainMenu extends FlxState {

	static final TRAINING_ROOM_MENU_ID = 'load_training_room';
	static final SELF_ROOM_MENU_ID = 'load_self_room';
	static final VS_AI_SETTINGS_MENU_ID = 'player-vs-ai-settings';

	var players:Array<PlayerOptions>;
	var backGame:AIRoom;

	public function new() {
		super();

		players = [Reflect.copy(Player.defaultOptions), Reflect.copy(Player.defaultOptions)];
		players[0].name = 'YOU';
		players[0].position = LEFT;
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
				-| vs AI | link | @${VS_AI_SETTINGS_MENU_ID}
				-| vs self | link | ${SELF_ROOM_MENU_ID}
				-| training room | link | ${TRAINING_ROOM_MENU_ID}
		'))
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage(VS_AI_SETTINGS_MENU_ID)
			.add(wrapMenuPage('Settings', '
				-| your position | list | player_pos | left,right
				-| AI difficulty | list | ai_smarteness | ${ais.join(',')}
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
					var settings = menu.pages[VS_AI_SETTINGS_MENU_ID];
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

				case [it_fire, 'internet']:
					#if html5
					Flixel.switchState(new Lobby1v1());
					#end
					0;

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

		add(menu);

		// actually center main page on the screen
		menu.mpActive.forEach(s -> s.screenCenter(X));
		// TODO update menu class for better alignment?

		// menu.menuEvent.dispatch(it_fire, SELF_ROOM_MENU_ID);
		// menu.menuEvent.dispatch(it_fire, 'split_screen');
		// menu.menuEvent.dispatch(it_fire, 'internet');

		// github button
		var octocat = new FlxSprite();
		octocat.loadGraphic(AssetPaths.gh_icon_final__png, false, 128, 128);
		octocat.scale.set(0.25, 0.25);
		octocat.updateHitbox();
		var githubButton = new FlxSpriteButton(0, 0, octocat, () -> System.openURL('https://github.com/T1mL3arn/HaxeFlixel-Pong'));
		githubButton.labelOffsets = [p(), p(), p()];
		githubButton.makeGraphic(32, 32, FlxColor.TRANSPARENT);
		githubButton.updateHitbox();
		githubButton.x = Flixel.width - 20 - githubButton.width;
		githubButton.y = Flixel.height - 20 - githubButton.height;
		githubButton.status = FlxButton.NORMAL;
		githubButton.onOver.callback = ()->Flixel.mouse.load(AssetPaths.pointer_cursor__png, 1, -3, -1);
		githubButton.onOut.callback = () -> Flixel.mouse.unload();
		add(githubButton);
		// --------

		insert(0, backGame = new AIRoom('medium', 'easy', true));
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
