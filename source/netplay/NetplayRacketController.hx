package netplay;

import flixel.input.keyboard.FlxKey;
import racket.Racket;
import racket.RacketController;
import netplay.Netplay.NetplayMessage;
import netplay.Netplay.NetplayMessageKind;

typedef PaddleActionPayload = {
	paddleName:String,
	actionMoveUp:Bool,
	actionMoveDown:Bool,
}

class NetplayRacketController extends RacketController {

	public var keyUp:FlxKey;
	public var keyDown:FlxKey;
	public var name:String;

	var data:PaddleActionPayload;

	public function new(racket:Racket, ?name:String, ?up:FlxKey = FlxKey.UP, ?down:FlxKey = FlxKey.DOWN) {
		super(racket);

		keyUp = up;
		keyDown = down;
		this.name = name;

		data = {
			paddleName: name,
			actionMoveDown: false,
			actionMoveUp: false,
		};
	}

	override function update(dt:Float) {

		var actionMoveUp = Flixel.keys.checkStatus(keyUp, PRESSED);
		var actionMoveDown = Flixel.keys.checkStatus(keyDown, PRESSED);

		// do not send network message if both UP and DOWN are pressed
		if (actionMoveDown && actionMoveUp)
			return;

		var upJustReleased = Flixel.keys.checkStatus(keyUp, JUST_RELEASED);
		var downJustReleased = Flixel.keys.checkStatus(keyDown, JUST_RELEASED);

		// do not send network message if nothing is pressed and nothing is just released
		if (!(actionMoveDown || actionMoveUp || upJustReleased || downJustReleased))
			return;
		// trace('send data${upJustReleased || downJustReleased ? ' ONCE' : ''}');

		data.paddleName = name;
		data.actionMoveUp = actionMoveUp;
		data.actionMoveDown = actionMoveDown;

		GAME.peer.send(PaddleAction, data);
	}
}
