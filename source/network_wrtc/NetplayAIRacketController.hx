package network_wrtc;

import ai.BaseAI;
import math.MathUtils.xor;
import netplay.TwoPlayersNetplayData.NetworkMessage;
import netplay.TwoPlayersNetplayData.NetworkMessageType;
import racket.RacketController;
import network_wrtc.NetplayRacketController.PaddleActionPayload;

/**
	Wrapper that allows AI to play as a network player.
**/
class NetplayAIRacketController extends RacketController {

	var ai:BaseAI;
	var data:PaddleActionPayload;

	public function new(ai:BaseAI) {

		super(ai.racket);

		this.ai = ai;

		data = {
			paddleName: ai.name,
			actionMoveDown: false,
			actionMoveUp: false,
		}
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

				if (sendData) {
					data.actionMoveUp = moveUp;
					data.actionMoveDown = moveDown;
					GAME.peer.send(PaddleAction, data);
				}
			case _:
				0;
		}
	}

	override function draw() {
		super.draw();
		ai.draw();
	}
}
