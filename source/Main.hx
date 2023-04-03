package;

import ai.SimpleAI;
import djFlixel.D;
import djFlixel.ui.FlxMenu;
import flixel.util.FlxDirection;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		D.init();

		addChild(new Pong());

		var menu = new FlxMenu(0, 0, -1);

		menu.PAR.start_button_fire = true;

		menu.createPage('main').add('
		-| 1 player | link | @1_player
		-| multiplayer	| link | opts
		-| exit			| link | exit
		');

		menu.createPage('1_player').add('
		-| training room | link | training_room
		-| vs AI | link | ai
		-| go back | link | @back
		');

		// disabling menu items tweening
		menu.STP.focus_anim = null;
		menu.STP.vt_IN = menu.STP.vt_OUT = '0:0|0:0';
		menu.STP.vt_in_ease = null;
		// setting up menu items text
		menu.STP.align = 'center';
		menu.STP.item.text = {
			s: 30,
			a: 'center'
		};

		menu.goto('main');

		Flixel.state.add(menu);

		return;

		// Flixel.switchState(new TwoPlayersRoom(null, {
		// 	position: FlxDirection.RIGHT,
		// 	getController: racket -> new SimpleAI(racket)
		// }));

		Flixel.switchState(new TwoPlayersRoom({
			position: FlxDirection.LEFT,
			name: 'simple-ai',
			color: 0xFF0075EB,
			getController: racket -> new SimpleAI(racket),
		}, {
			position: FlxDirection.RIGHT,
			name: 'simple-ai',
			color: 0xFFF1003C,
			getController: racket -> new SimpleAI(racket)
		}));
	}
}
