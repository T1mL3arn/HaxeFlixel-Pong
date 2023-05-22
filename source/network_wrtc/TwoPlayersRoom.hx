package network_wrtc;

import network_wrtc.NetplayRacketController.PaddleActionPayload;

using Lambda;

typedef TwoPlayersGameState = {
	rackets:Array<{
		?id:String,
		x:Float,
		y:Float,
		vx:Float,
		vy:Float,
	}>,
	names:Array<String>,
	score:Array<Int>,
	// OR
	ball:{x:Float, y:Float, vx:Float, vy:Float},
	players:Array<{
		name:String,
		racket:{
			x:Float,
			y:Float,
			vx:Float,
			vy:Float,
			?id:String,
		},
		score:Int,
	}>,
	?winner:Any,
};

typedef BallDataPayload = {
	x:Float,
	y:Float,
	vx:Float,
	vy:Float,
	?hitBy:String,
}

class TwoPlayersRoom extends room.TwoPlayersRoom {

	var network:Network;

	public function new(left, right, network:Network) {
		super(left, right);

		this.network = network;

		network.onMessage.add(msg -> {
			// trace('(${untyped network.peer.initiator ? 'server' : 'player'}): on message');

			switch (msg.type) {
				case PaddleAction:
					var data:PaddleActionPayload = msg.data;

					var actionUp = data.actionMoveUp ?? false;
					var actionDown = data.actionMoveDown ?? false;
					var paddleName = data.paddleName;

					var player = players.find(p -> p.uid == paddleName);
					player.racket.velocity.set(0, 0);

					// do not update paddle when both movement actions are active
					if (!(actionUp && actionDown)) {
						if (actionUp)
							player.racket.velocity.set(0, -Pong.defaults.racketSpeed);
						if (actionDown)
							player.racket.velocity.set(0, Pong.defaults.racketSpeed);
					}

				case BallData: messageBallData(msg.data);
				default: 0;
			}
		});
	}


	function messageBallData(data:BallDataPayload) {
		ball.setPosition(data.x, data.y);
		ball.velocity.set(data.vx, data.vy);
	}

	override function update(dt:Float) {
		super.update(dt);
	}

	override function fisrtBallServe() {
		if (network.initiator) {
			super.fisrtBallServe();
			network.sendMessage(BallData, {
				x: ball.x,
				y: ball.y,
				vx: ball.velocity.x,
				vy: ball.velocity.y,
				hitBy: 'unknown',
			});
		}
	}

	override function ballOutWorldBounds() {
		if (network.initiator)
			super.ballOutWorldBounds();
	}
}
