package;

import djFlixel.D;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		D.init();
		D.ui.initIcons([8]);

		addChild(new Pong());

		Flixel.autoPause = false;
		// Flixel.switchState(new room.AIRoom());
		Flixel.switchState(new menu.CongratScreen());
		// Flixel.switchState(new network_wrtc.Lobby1v1());
		// Flixel.switchState(new menu.MainMenu());

	}
}
