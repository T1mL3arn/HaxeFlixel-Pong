package network_wrtc;

import flixel.FlxObject;
import flixel.util.FlxTimer;
import menu.BaseMenu.MenuCommand;
import menu.CongratScreen.CongratScreenType;
import menu.CongratScreen;
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

typedef CongratScreenDataPayload = {
	winnerName:String,
	winnerUid:String,
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
		// NOTE: never add() handlers during FlxSignal.dispatch()
		// this.network.onMessage.add(onMessage);
		// TODO show "user disconnected" info if user disconnects during the game
	}

	override function create() {
		super.create();
		network.onMessage.add(onMessage);
	}

	override function destroy() {
		super.destroy();
		network?.onMessage?.remove(onMessage);
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
			case CongratScreenData:
				messageCongratScreenData(msg.data);
			case ResetRoom:
				messageResetRoom();
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
				player.racket.velocity.set(0, -Pong.params.racketSpeed);
			if (actionDown)
				player.racket.velocity.set(0, Pong.params.racketSpeed);
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

	function messageCongratScreenData(data:CongratScreenDataPayload) {
		// since a server(initiator) already switched to CongratScreen
		// I don't need it to react on this message.
		if (network.initiator)
			return;
		var player = players.find(p -> p.uid == data.winnerUid);
		showCongratScreen(player, data.winnerUid == currentPlayerUid ? FOR_WINNER : FOR_LOOSER);
	}

	function messageResetRoom() {
		Flixel.switchState(new TwoPlayersRoom(leftOptions, rightOptions, network, currentPlayerUid));
	}

	var ballPayload:BallDataPayload = {
		x: 0,
		y: 0,
		vx: 0,
		vy: 0,
		hitBy: 'unknown',
	};

	function getBallPayload():BallDataPayload {
		ballPayload.x = ball.x;
		ballPayload.y = ball.y;
		ballPayload.vx = ball.velocity.x;
		ballPayload.vy = ball.velocity.y;
		ballPayload.hitBy = 'unknown';
		return ballPayload;
	}

	override function serveBall(byPlayer:Player, ball:Ball, ?delay:Float) {
		if (network.initiator) {
			super.serveBall(byPlayer, ball, delay);
			// ball serve has delay, so for correct sync
			// I have to sync 2 times: right now and after delay
			network.send(BallData, getBallPayload());

			// TODO probably better use haxe Timer here in netplay
			new FlxTimer().start(delay, _ -> network.send(BallData, getBallPayload()));
		}
	}

	override function fisrtBallServe() {
		if (network.initiator)
			super.fisrtBallServe();
	}

	override function ballOutWorldBounds() {
		if (network.initiator)
			super.ballOutWorldBounds();
	}

	override function goal(hitArea, ball) {
		if (network.initiator) {
			super.goal(hitArea, ball);
		}
	}

	override function updateScore(player:Player, score:Int) {
		super.updateScore(player, score);
		network.send(ScoreData, {
			leftScore: players[0].score,
			rightScore: players[1].score,
		});
	}

	override function showCongratScreen(player:Player, screenType:CongratScreenType) {
		var congrats = new NetplayCongratScreen(_ -> {
			network.send(ResetRoom);
		});
		congrats.network = Network.network;
		congrats.isServer = network.initiator;
		congrats.openMainMenuAction = () -> {
			network.destroy();
			Network.network = null;
		}

		canOpenPauseMenu = false;
		openSubState(congrats.setWinner(player.name, player.uid == currentPlayerUid ? FOR_WINNER : FOR_LOOSER));

		if (network.initiator)
			network.send(CongratScreenData, {winnerName: player.name, winnerUid: player.uid});
	}

	override function ballCollision(wall:FlxObject, ball:Ball) {
		super.ballCollision(wall, ball);

		if (network.initiator)
			network.send(BallData, getBallPayload());
	}
}

/**
	This congrat screen disables "play again" menu item
	for non-server player, so the only server can choose 
	to "play again".
**/
class NetplayCongratScreen extends CongratScreen {

	public var isServer:Bool = false;
	public var network:Network;

	override function create() {
		super.create();

		// disable "play again" for non-server
		if (!isServer) {
			var itemData = menu.pages['main'].get('again');
			itemData.disabled = true;
			itemData.selectable = false;
			menu.mpActive.item_update(itemData);
			menu.mpActive.item_focus(MenuCommand.SWITCH_TO_MAIN_MENU);
		}

		network.peer.on('close', onDisconnect);
		network.peer.on('error', onDisconnect);
	}

	function onDisconnect() {
		network.destroy();

		// disable "play again" if second user disconnected during CongratScreen
		// show "user disconnected" info if user disconnects during CongratScreen
		var itemData = menu.pages['main'].get('again');
		itemData.disabled = true;
		itemData.selectable = false;
		itemData.label = 'disconnected';
		menu.mpActive.item_update(itemData);
		menu.mpActive.item_focus(MenuCommand.SWITCH_TO_MAIN_MENU);
		// re-align menu items
		menu.mpActive.setDataSource(menu.mpActive.page.items);
	}
}
