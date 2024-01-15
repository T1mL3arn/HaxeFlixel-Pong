package mouse;

import flixel.FlxBasic;

/**
	Hides(and showes) mouse cursor when keyboard is used.
**/
class MouseHider extends FlxBasic {

	public function new() {
		super();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.justPressed.ANY) {
			var mouse:SpriteAsMouse = Flixel.plugins.get(SpriteAsMouse);
			mouse.cursor.visible = false;
		}

		#if FLX_GAMEPAD
		if (Flixel.gamepads.anyButton(JUST_PRESSED)) {
			var mouse:SpriteAsMouse = Flixel.plugins.get(SpriteAsMouse);
			mouse.cursor.visible = false;
		}
		#end

		if (Flixel.mouse.justMoved) {
			var mouse:SpriteAsMouse = Flixel.plugins.get(SpriteAsMouse);
			mouse.cursor.visible = true;
		}
	}
}
