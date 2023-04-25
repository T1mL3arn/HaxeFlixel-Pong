package;

import djFlixel.D;
import menu.MainMenu;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		D.init();
		D.ui.initIcons([8]);

		addChild(new Pong());

		Flixel.autoPause = false;
		Flixel.switchState(new MainMenu());
	}
}
