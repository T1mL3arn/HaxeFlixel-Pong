package netplay;

import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import menu.BaseMenu.MenuCommand;
import menu.CongratScreen.CongratScreenType;
import menu.CongratScreen;
import menu.PauseMenu;
import racket.Racket;
import netplay.Netplay.NetplayMessage;
import netplay.Netplay.NetplayMessageKind;
import netplay.NetplayPeer.INetplayPeer;
import netplay.NetplayRacketController.PaddleActionPayload;

using Lambda;

typedef TwoPlayersGameState = {
	ball:{x:Float, y:Float, vx:Float, vy:Float},
	players:Array<{
		uid:String,
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
};

typedef BallDataPayload = {
	x:Float,
	y:Float,
	vx:Float,
	vy:Float,
	?hitBy:String,
	?color:FlxColor,
}

typedef ScoreDataPayload = {
	leftScore:Int,
	rightScore:Int,
}

typedef CongratScreenDataPayload = {
	winnerName:String,
	winnerUid:String,
}

@:deprecated('Use `TwoPlayerNew` instead')
class TwoPlayersRoomOld extends room.TwoPlayersRoom {

	var network:INetplayPeer<Any>;
	var currentPlayerUid:String;

	public function new(left, right) {
		super(left, right);

		// NOTE at this moment `server` is LEFT player.
		this.currentPlayerUid = GAME.peer.isServer ? left.uid : right.uid;

		canPause = false;

		subStateOpened.add(state -> {
			if (state is PauseMenu)
				players.find(p -> p.uid == this.currentPlayerUid).active = false;
		});

		subStateClosed.add(state -> {
			if (state is PauseMenu)
				players.find(p -> p.uid == this.currentPlayerUid).active = true;
		});

		network = GAME.peer;

		// NOTE: never add() handlers during FlxSignal.dispatch()
		// this.network.onMessage.add(onMessage);
	}

	override function create() {
		super.create();

		network.onMessage.add(onMessage);
		Flixel.vcr.pauseChanged.add(onPauseChange);
		#if debug
		// Pong.params.ballSpeed = 500;
		Pong.params.scoreToWin = 3;
		#end
	}

	function onPauseChange(paused:Bool) {
		network.send(DebugPause, {paused: paused});
	}

	override function destroy() {
		super.destroy();
		network?.onMessage?.remove(onMessage);
		Flixel.vcr.pauseChanged.remove(onPauseChange);
	}

	function onMessage(msg:NetplayMessage) {
		// trace('(${untyped network.isServer ? 'server' : 'player'}): on message');

		switch (msg.type) {
			case PaddleAction:
				messagePaddleAction(msg.data);
			case BallData:
				// trace('${network.peerType}: GOT ${msg.type}');
				messageBallData(msg.data);
			case ScoreData:
				messageScoreData(msg.data);
			case CongratScreenData:
				messageCongratScreenData(msg.data);
			case ResetRoom:
				messageResetRoom();
			case BallPreServe:
				// trace('${network.peerType}: GOT ${msg.type}');
				messageBallPreServe(msg.data);
			case DebugPause:
				messageDebugPause(msg.data);
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
		// trace('reset VELOCITY for $paddleName');

		// do not update paddle when both movement actions are active
		if (!(actionUp && actionDown)) {
			if (actionUp)
				player.racket.velocity.set(0, -Pong.params.racketSpeed);
			if (actionDown)
				player.racket.velocity.set(0, Pong.params.racketSpeed);
		}
	}

	var tmpObject = new FlxObject();

	function messageBallData(data:BallDataPayload) {
		ball.setPosition(data.x, data.y);
		ball.velocity.set(data.vx, data.vy);

		if (!network.isServer) {

			switch (data.hitBy) {
				case null:
					// trace('before BALL SERVED dispatch');
					GAME.signals.ballServed.dispatch();
				case 'wall':
					// just fake the object
					GAME.signals.ballCollision.dispatch(tmpObject, GAME.room.ball);
				case 'racket_ours':
					// fon non server "ours" turns to "theirs"
					var racket = players.find(p -> p.uid != currentPlayerUid)?.racket;
					GAME.signals.ballCollision.dispatch(racket, GAME.room.ball);
				// trace('theirs racket: ${racket == null ? 'null' : 'yes'}');
				case 'racket_theirs':
					// fon non server "theirs" turns to "ours"
					var racket = findPlayerById(currentPlayerUid)?.racket;
					GAME.signals.ballCollision.dispatch(racket, GAME.room.ball);
					// trace('ours racket: ${racket == null ? 'null' : 'yes'}');
			}
		}
	}

	function messageScoreData(data:ScoreDataPayload) {
		players[0].score = data.leftScore;
		players[1].score = data.rightScore;
	}

	function messageCongratScreenData(data:CongratScreenDataPayload) {
		// since a server(initiator) already switched to CongratScreen
		// I don't need it to react on this message.
		if (network.isServer)
			return;
		var player = players.find(p -> p.uid == data.winnerUid);
		showCongratScreen(player, data.winnerUid == currentPlayerUid ? FOR_WINNER : FOR_LOOSER);
	}

	function messageResetRoom() {
		Flixel.switchState(new TwoPlayerRoom(leftOptions, rightOptions));
	}

	function messageBallPreServe(data:{delay:Float}) {
		if (!network.isServer) {
			ballPreServe(GAME.room.ball, data.delay);
			trace('${network.peerType} ball preserve executed');
		}
	}

	function messageDebugPause(data:{paused:Bool}) {
		#if debug
		if (!network.isServer) {
			if (data.paused)
				Flixel.vcr.pause();
			else
				Flixel.vcr.resume();
		}
		#end
	}

	var ballPayload:BallDataPayload = {
		x: 0,
		y: 0,
		vx: 0,
		vy: 0,
		hitBy: 'unknown',
	};

	function getBallPayload(hitby:String = null):BallDataPayload {
		ballPayload.x = ball.x;
		ballPayload.y = ball.y;
		ballPayload.vx = ball.velocity.x;
		ballPayload.vy = ball.velocity.y;
		ballPayload.hitBy = hitby;
		return ballPayload;
	}

	override function serveBall(byPlayer:Player, ball:Ball, delay:Float) {
		if (network.isServer) {
			super.serveBall(byPlayer, ball, delay);
			// ball serve has delay, so for correct sync
			// I have to sync 2 times: right now and after delay
			network.send(BallData, getBallPayload(''));
			network.send(BallPreServe, {delay: delay});

			new FlxTimer(timerManager).start(delay, _ -> network.send(BallData, getBallPayload(null)));
		}
	}

	override function firstBallServe() {
		if (network.isServer)
			super.firstBallServe();
	}

	override function ballOutWorldBounds() {
		if (network.isServer)
			super.ballOutWorldBounds();
	}

	override function goal(hitArea, ball) {
		if (network.isServer) {
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
		congrats.network = GAME.peer;
		congrats.isServer = network.isServer;
		congrats.openMainMenuAction = ()->{
			// network.destroy();
		}

		canOpenPauseMenu = false;
		canPause = true;
		persistentDraw = true;

		openSubState(congrats.setWinner(player.name, player.uid == currentPlayerUid ? FOR_WINNER : FOR_LOOSER));

		if (network.isServer)
			network.send(CongratScreenData, {winnerName: player.name, winnerUid: player.uid});
	}

	override function ballCollision(wall:FlxObject, ball:Ball) {
		super.ballCollision(wall, ball);

		if (network.isServer) {
			// trace('send BallData');

			// hitBy data is for SmartAI
			// it uses "type" of wall for decision, it does not read info like
			// dimension, pos, etc.
			var hitBy = wall is Racket ? 'racket' : 'wall';
			// trace('current player uid: $currentPlayerUid');
			hitBy = hitBy != 'racket' ? hitBy : (findPlayerById(currentPlayerUid)?.racket == wall ? 'racket_ours' : 'racket_theirs');

			network.send(BallData, getBallPayload(hitBy));
		}
	}
}

/**
	This congrat screen disables "play again" menu item
	for non-server player, so the only server can choose 
	to "play again".
**/
class NetplayCongratScreen extends CongratScreen {

	public var isServer:Bool = false;
	public var network:INetplayPeer<Any>;

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

		// TODO review how simple-peer CLOSE event relates to anette lib

		errorHandler = _ -> onDisconnect('error');
		disconnectHandler = () -> onDisconnect('disconnected');
		network.onError.addOnce(errorHandler);
		network.onDisconnect.addOnce(disconnectHandler);
	}

	var disconnectHandler:()->Void;
	var errorHandler:Any->Void;

	function onDisconnect(?reason = 'disconnected') {

		network.onError.remove(errorHandler);
		network.onDisconnect.remove(disconnectHandler);

		// disable "play again" if second user disconnected during CongratScreen
		// show "user disconnected" info if user disconnects during CongratScreen
		var itemData = menu.pages['main'].get('again');
		itemData.disabled = true;
		itemData.selectable = false;
		itemData.label = reason;
		menu.mpActive.item_update(itemData);
		menu.mpActive.item_focus(MenuCommand.SWITCH_TO_MAIN_MENU);
		// re-align menu items
		menu.mpActive.setDataSource(menu.mpActive.page.items);
	}

	override function destroy() {
		super.destroy();

		network.onError.remove(errorHandler);
		network.onDisconnect.remove(disconnectHandler);
		network = null;
	}
}
