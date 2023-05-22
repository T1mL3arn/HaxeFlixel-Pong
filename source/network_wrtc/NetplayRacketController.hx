package network_wrtc;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;

typedef PaddleActionPayload = {
	paddleName:String,
	actionMoveUp:Bool,
	actionMoveDown:Bool,
}

class NetplayRacketController extends RacketController {

	public var keyUp:FlxKey;
	public var keyDown:FlxKey;
	public var name:String;

	public function new(racket:Racket, ?name:String, ?up:FlxKey = FlxKey.UP, ?down:FlxKey = FlxKey.DOWN) {
		super(racket);

		keyUp = up;
		keyDown = down;
		this.name = name;
	}

	override function update(dt:Float) {

		var actionMoveUp = Flixel.keys.checkStatus(keyUp, FlxInputState.PRESSED) ? true : false;
		var actionMoveDown = Flixel.keys.checkStatus(keyDown, FlxInputState.PRESSED) ? true : false;

		var data:PaddleActionPayload = {
			paddleName: name,
			actionMoveUp: actionMoveUp,
			actionMoveDown: actionMoveDown,
		}

		// TODO send the message only once when no keys are pressed
		var net = Network.network;

		net.sendMessage(PaddleAction, data);
	}
}
