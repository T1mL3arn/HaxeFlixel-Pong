package;

import djFlixel.D;
import lime.system.System;
import openfl.display.Sprite;

class Main extends Sprite {

	public function new() {
		super();

		D.init();
		D.ui.initIcons([8]);

		addChild(new Pong());

		Flixel.autoPause = false;

		#if debug
		// Flixel.switchState(new room.AIRoom('medium'));
		// Flixel.switchState(new menu.CongratScreen().setWinner('not You', false));
		Flixel.switchState(new network_wrtc.Lobby1v1());
		#else
		Flixel.switchState(new menu.MainMenu());
		#end
	}
}
