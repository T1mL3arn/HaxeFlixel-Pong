package network_wrtc;

import menu.PauseMenu;
import network_wrtc.NetplayRacketController.PaddleActionPayload;
import network_wrtc.Network.NetworkMessage;

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

typedef ScoreDataPayload = {
	leftScore:Int,
	rightScore:Int,
}

class TwoPlayersRoom extends room.TwoPlayersRoom {

	var network:Network;
	var currentPlayerUid:String;

	public function new(left, right, network:Network, currentPlayerUid:String) {
		super(left, right);

		this.currentPlayerUid = currentPlayerUid;

		canPause = false;

		subStateOpened.add(state -> {
			if (state is PauseMenu)
				players.find(p -> p.uid == this.currentPlayerUid).active = false;
		});

		subStateClosed.add(state -> {
			if (state is PauseMenu)
				players.find(p -> p.uid == this.currentPlayerUid).active = true;
		});

		this.network = network;
		this.network.onMessage.add(onMessage);
	}

	override function destroy() {
		super.destroy();
		network.onMessage.remove(onMessage);
	}

	function onMessage(msg:NetworkMessage) {
		// trace('(${untyped network.peer.initiator ? 'server' : 'player'}): on message');

		switch (msg.type) {
			case PaddleAction:
				messagePaddleAction(msg.data);
			case BallData:
				messageBallData(msg.data);
			case ScoreData:
				messageScoreData(msg.data);
			default:
				0;
		}
	}

	function messagePaddleAction(data:PaddleActionPayload) {
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
	}

	function messageBallData(data:BallDataPayload) {
		ball.setPosition(data.x, data.y);
		ball.velocity.set(data.vx, data.vy);
	}

	function messageScoreData(data:ScoreDataPayload) {
		players[0].score = data.leftScore;
		players[1].score = data.rightScore;
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

	override function goal(hitArea, ball) {
		if (network.initiator) {
			super.goal(hitArea, ball);
			network.sendMessage(ScoreData, {
				leftScore: players[0].score,
				rightScore: players[1].score,
			});
		}
	}
}
