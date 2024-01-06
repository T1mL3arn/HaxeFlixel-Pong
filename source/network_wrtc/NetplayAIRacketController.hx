package network_wrtc;

import ai.BaseAI;
import math.MathUtils.xor;
import openfl.utils.Function;
import network_wrtc.NetplayRacketController.PaddleActionPayload;

/**
	Wrapper that allows AI to play as a network player.
**/
class NetplayAIRacketController extends RacketController {

	var ai:BaseAI;
	var data:PaddleActionPayload;

	public function new(ai:BaseAI) {
		var oldTrace = haxe.Log.trace;
		haxe.Log.trace = function(v, ?infos) {
			// handle trace
			if (infos != null) {
				infos.fileName = '';
				infos.lineNumber = 1;
			}
			oldTrace(v, infos);
		}

		super(ai.racket);

		this.ai = ai;

		data = {
			paddleName: ai.name,
			actionMoveDown: false,
			actionMoveUp: false,
		}

		trace('same racket: ${this.racket == ai.racket}');
	}

	override function destroy() {
		super.destroy();
		ai.destroy();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		ai.update(elapsed);

		switch racket.position {
			case LEFT, RIGHT:
				var moveDown = racket.velocity.y > 0;
				var moveUp = racket.velocity.y < 0;
				var sendData = xor(moveDown, data.actionMoveDown) || xor(moveUp, data.actionMoveUp);

				trace('D: $moveDown, U: $moveUp, send: $sendData');
				if (sendData) {
					data.actionMoveUp = moveUp;
					data.actionMoveDown = moveDown;
					Network.network.send(PaddleAction, data);
					trace('ai data, UP: ${data.actionMoveUp} DOWN: ${data.actionMoveDown}');
				}
			case _:
				0;
		}
	}
}
