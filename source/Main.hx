package;

import djFlixel.D;
import menu.MainMenu;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		D.init();

		addChild(new Pong());

		Flixel.switchState(new MainMenu());
	}
}
