package netplay;

import Player.PlayerOptions;
import ai.BaseAI;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import menu.CongratScreen;
import menu.NetplayDisconnectedScreen;
import menu.PauseMenu;
import mod.CornerGoalWatch;
import mod.Updater;
import racket.Racket;
import netplay.Netplay.BallDataPayload;
import netplay.Netplay.NetplayMessage;
import netplay.Netplay.NetplayMessageKind;
import netplay.Netplay.ObjectMotionData;
import netplay.Netplay.getBallCollisionData;
import netplay.NetplayCongratScreen;
import netplay.NetplayRacketController.PaddleActionPayload;

using Lambda;

class TwoPlayerRoom extends room.TwoPlayersRoom {

	var currentPlayerUid:String;

	/**
		true if there is a winner
	**/
	var gameFinished:Bool = false;

	var interpolationTweens:Map<Int, FlxTween> = [];

	public function new(?left:PlayerOptions, ?right:PlayerOptions) {
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

		haxe.Log.trace = utils.TraceUtils.trace;
	}

	override function create() {
		// reset uid to be sure it is the same
		// for client and server objects
		netplay.Netplay.netplayUid = 11;

		super.create();

		GAME.peer.onMessage.add(onMessage);
		GAME.peer.onDisconnect.addOnce(() -> {
			openSubState(new NetplayDisconnectedScreen('DISCONNECTED'));
			haxe.Timer.delay(() -> {
				GAME.peer?.destroy();
				GAME.peer = null;
			}, 1);
		});
		GAME.peer.onError.addOnce(e -> {
			openSubState(new NetplayDisconnectedScreen('NETWORK ERROR', Std.string(e)));
			haxe.Timer.delay(() -> {
				GAME.peer?.destroy();
				GAME.peer = null;
			}, 1);
		});

		Flixel.vcr.pauseChanged.add(onPauseChange);

		FLixel.signals.postUpdate.add(flushPeerData);

		#if debug
		// Pong.params.ballSpeed = 500;
		Pong.params.scoreToWin = 4;
		#end

		if (GAME.peer.isServer) {
			onBallServedCB = () -> {
				#if hl
				// see this.destroy()
				if (!exists)
					trace('hello hashlink');
				#end
				GAME.peer.send(BallData, getBallPayload());
			};
			onBallCollisionCB = (w, b) -> {
				#if hl
				// see this.destroy()
				if (!exists)
					trace('hello hashlink');
				#end
				GAME.peer.send(BallCollision, getBallCollisionData(w, b));
			};

			GAME.signals.ballServed.add(onBallServedCB);
			GAME.signals.ballCollision.add(onBallCollisionCB);
		}

		#if debug
		// label with (client/server) text at the bottom of the screen
		var peerType = GAME.peer.peerType.toLowerCase();
		var text = new FlxText(0, 0, 0, peerType, 12);
		text.color = FlxColor.WHITE;
		text.x = Flixel.width * 0.5 - text.width * 0.5;
		text.y = Flixel.height - text.height;
		uiObjects.add(text);

		// disable/mute sound for client for debug tests
		// so no same sounds are played when testing on local machine
		if (!GAME.peer.isServer)
			Flixel.sound.muted = true;
		#end
	}

	function flushPeerData() {
		#if hl
		if (!exists)
			trace('hello hashlink!');
		#end
		GAME.peer?.loop();
	}

	var onBallServedCB(default, null):()->Void;
	var onBallCollisionCB:(Any, Any)->Void;

	function onPauseChange(paused:Bool) {
		// restore paused state on a client
		Flixel.vcr.paused = !paused;
		GAME.peer.send(DebugPauseRequest, {paused: paused});
	}

	function logmsg(msg:NetplayMessage) {
		trace('(${GAME.peer.isServer ? 'server' : 'client'}): msg ${msg.type}');
	}

	function onMessage(msg:NetplayMessage) {

		#if hl
		// see this.destroy()
		if (!exists)
			trace('hello hashlink');
		#end

		if (GAME.peer.isServer) {

			switch (msg.type) {
				case DebugPause:
					messageDebugPause(msg.data);
				case DebugPauseRequest:
					messageDebugPause(msg.data, true);
				case PaddleAction:
					messagePaddleAction(msg.data);
				case ResetRoom:
					messageResetRoom();
				case BallPreServe:
					messageBallPreserve(msg.data);
				case ShowCongratScreen:
					messageShowCongratScreen(msg.data);
				case _:
			}
		}
		else {

			// logmsg(msg);

			switch (msg.type) {
				case PaddleData:
					messagePaddleData(msg.data);
				case BallData:
					messageBallData(msg.data);
				case BallCollision:
					messageBallCollision(msg.data);
				case BallSpeedup:
					ballSpeedup.playSpeedupSound();
				case Goal:
					messageGoal(msg.data);
				case ShowCongratScreen:
					messageShowCongratScreen(msg.data);
				case BallPreServe:
					messageBallPreserve(msg.data);
				case DebugPause:
					messageDebugPause(msg.data);
				case ResetRoom:
					messageResetRoom();
				default:
					0;
			}
		}
	}

	function messageResetRoom() {
		//
		Flixel.switchState(new TwoPlayerRoom(leftOptions, rightOptions));
	}

	function messageDebugPause(data:{paused:Bool}, isRequest:Bool = false) {
		#if debug
		if (isRequest) {
			// request for pause/unpause
			GAME.peer.send(DebugPause, data);
		}
		else {
			// else it is command
			Flixel.vcr.paused = data.paused;
			if (data.paused)
				Flixel.game.debugger.vcr.onPause();
			else
				Flixel.game.debugger.vcr.onResume();
		}
		#end
	}

	function messageBallPreserve(data:{delay:Float}) {
		ballPreServe(GAME.room.ball, data.delay);
	}

	function messageShowCongratScreen(data:{winnerUid:String, screenType:CongratScreenType}) {
		var player = findPlayerById(data.winnerUid);
		showCongratScreen(player, data.screenType);
	}

	function messageGoal(data:{playerUid:String, newScore:Int, ?cornerGoal:Bool}) {
		var player = findPlayerById(data.playerUid);

		// but if it is not - force it if needed
		if (data.cornerGoal) {
			// check corner goal
			var cgw:CornerGoalWatch = cast gameObjects.members.find(x -> x is CornerGoalWatch);
			cgw?.showLabel(player);
		}

		updateScore(player, data.newScore);
	}

	var tmpObject = new FlxObject();

	function messageBallData(data:BallDataPayload) {
		ball.setPosition(data.x, data.y);
		ball.velocity.set(data.vx, data.vy);
		ball.color = data.color ?? ball.color;
	}

	function messageBallCollision(data) {
		var bdata = data.ball;

		ball.setPosition(bdata.x, bdata.y);
		ball.velocity.set(bdata.vx, bdata.vy);
		// ball.color = data.color ?? ball.color;

		if (data.wallUid == -1) {
			// ball serve
			GAME.signals.ballServed.dispatch();
			return;
		}

		var wall = findObjectById(data.wallUid);
		if (wall == null) {
			// trace('walls uids: ${walls.members.map(x -> x.netplayUid).join(', ')}');
			throw 'Wall with uid:${data.wallUid} is not found, UID corrupted';
		}
		ballCollision(wall, ball);
	}

	var paddleData:ObjectMotionData = {
		uid: '',
		x: 0,
		y: 0,
		vx: 0,
		vy: 0
	};

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

		paddleData.uid = player.uid;
		paddleData.x = player.racket.x;
		paddleData.y = player.racket.y;
		paddleData.vx = player.racket.velocity.x;
		paddleData.vy = player.racket.velocity.y;

		GAME.peer.send(PaddleData, paddleData);
	}

	function messagePaddleData(data:ObjectMotionData) {
		var player = findPlayerById(data.uid);
		var racket = player.racket;

		racket.velocity.set(data.vx, data.vy);

		if (racket.velocity.isZero()) {
			// racket.x = data.x;
			// racket.y = data.y;
			interpolatePos(racket, data.x, data.y);
		}
	}

	var interpTweenOpts = {ease: FlxEase.cubeOut};

	function interpolatePos(obj:FlxObject, x, y, frames:Int = 6) {
		var uid = obj.netplayUid;
		interpolationTweens[uid]?.cancel();
		interpolationTweens[uid] = tweenManager.tween(obj, {x: x, y: y}, frames / 60, interpTweenOpts);
	}

	override function roomUpdate(dt:Float) {
		if (GAME.peer.isServer) {
			super.roomUpdate(dt);
		}
		else {
			// stop the ball when it overlaps colliders,
			// to prevent the ball passing through them
			FLixel.overlap(walls, ball, stopBall);
		}
	}

	function stopBall(_, ball:FlxObject) {
		ball.velocity.set(0, 0);
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

		if (!GAME.peer.isServer)
			return;

		var p = byPlayer;
		ball.y = p.racket.y + p.racket.height * 0.5 - ball.height * 0.5;

		var velX = switch byPlayer.options.position {
			case LEFT:
				-Pong.params.ballSpeed;
			case RIGHT:
				Pong.params.ballSpeed;
			default:
				0;
		}

		// ball starts moving after some delay
		new FlxTimer(timerManager).start(delay, _ -> {
			ball.velocity.set(velX, 0);
			GAME.signals.ballServed.dispatch();
		});

		// ball serve has delay, so for correct sync
		// I have to sync 2 times: right now and after delay
		GAME.peer.send(BallData, getBallPayload());
		GAME.peer.send(BallPreServe, {delay: delay});
	}

	override function ballCollision(wall:FlxObject, ball:Ball) {
		if (GAME.peer.isServer) {
			var speedup = false;
			if (wall is Racket) {
				speedup = ballSpeedup.onRacketHit();
				(cast wall : Racket).ballCollision(ball);
				colorizeBall(cast wall, ball);
			}
			ball.collision(wall);
			GAME.signals.ballCollision.dispatch(wall, ball);
			if (speedup)
				GAME.peer.send(BallSpeedup);
		}
		else {
			// client reacts after all computations are happened
			// so I need here mostly just sound
			if (wall is Racket) {
				// 1. no need in speedup, the ball is already got it
				// ballSpeedup.onRacketHit();

				// 2. no need racket bouncing, it is done on server
				// (cast wall : Racket).ballCollision(ball);
				// 3. probably need color (though it'is not used ATM)
				colorizeBall(cast wall, ball);
			}

			// need ball collision sound
			ball.collision(wall);
			// 5. shouldn't dispatch probably (will be problem with netplay client AI)
			GAME.signals.ballCollision.dispatch(wall, ball);
		}
	}

	override function goal(hitArea:FlxBasic, ball:Ball) {
		if (!GAME.peer.isServer)
			return;

		var looser = players.find(p -> p.hitArea == hitArea);
		var winner = players.find(p -> p.racket == ball.hitBy);
		// NOTE: having a looser without a winner means
		// it was a ball serve, in this case goal doesnt count
		// and ball re-served the same way
		var ballServer = winner ?? looser;

		if (winner != null) {
			updateScore(winner, winner.score + 1);
			GAME.signals.goal.dispatch(winner);

			// server corner goal watcher has updated score at this moment
			var cgw:CornerGoalWatch = cast gameObjects.members.find(x -> x is CornerGoalWatch);
			var cornerGoal = cgw?.isCornerGoal ?? false;
			GAME.peer.send(Goal, {playerUid: winner.uid, newScore: winner.score, cornerGoal: cornerGoal});
		}

		// checking the winner of the game
		winner = players.find(p -> p.score >= Pong.params.scoreToWin);
		if (winner != null) {
			trace('Winner: ${winner.name} !');

			// place ball out of goals to fix rare bug
			// with two immediate win events
			ball.x -= Flixel.width * 2;

			var screenType = if (winner.racketController is BaseAI && !(looser.racketController is BaseAI)) {
				// show LOOSER if human lost  to AI
				CongratScreenType.FOR_LOOSER;
			}
			else {
				CongratScreenType.FOR_WINNER;
			}

			gameFinished = true;
			GAME.peer.send(ShowCongratScreen, {winnerUid: winner.uid, screenType: screenType});
		}
		else if (ballServer != null) {
			resetBall();
			serveBall(ballServer, ball, Pong.params.ballServeDelay);
		}
	}

	override function showCongratScreen(player:Player, screenType:CongratScreenType) {

		var congrats = new NetplayCongratScreen(_ -> {
			GAME.peer.send(ResetRoom);
		});

		// state and substate both listens error and disconnect,
		// so remove listeners here first.
		GAME.peer.onError.removeAll();
		GAME.peer.onDisconnect.removeAll();

		congrats.network = GAME.peer;
		congrats.isServer = GAME.peer.isServer;

		canOpenPauseMenu = false;
		canPause = true;
		persistentDraw = true;

		for (player in players) {
			player.active = false;
		}

		openSubState(congrats.setWinner(player.name, player.uid == currentPlayerUid ? FOR_WINNER : FOR_LOOSER));
	}

	override function ballOutWorldBounds() {
		if (!GAME.peer.isServer) {
			if (!ball.inWorldBounds()) {
				ball.velocity.set(0, 0);
			}
		}
		if (GAME.peer.isServer && !gameFinished)
			super.ballOutWorldBounds();
	}

	override function firstBallServe() {
		if (GAME.peer.isServer)
			super.firstBallServe();
	}

	override function destroy() {
		super.destroy();
		#if hl
		// HL target: you cannot just remove a single listener
		// see https://github.com/HaxeFoundation/hashlink/issues/578
		// so let's remove ALL !!!
		GAME.peer?.onMessage.removeAll();
		Flixel.vcr.pauseChanged.removeAll();
		GAME.signals.ballServed.removeAll();
		GAME.signals.ballCollision.removeAll();
		GAME.signals.goal.removeAll();
		#end
		GAME.peer?.onMessage.remove(onMessage);
		GAME.peer?.onError.removeAll();
		GAME.peer?.onDisconnect.removeAll();
		Flixel.vcr.pauseChanged.remove(onPauseChange);
		Flixel.signals.postUpdate.remove(flushPeerData);
		GAME.signals.ballServed.remove(onBallServedCB);
		GAME.signals.ballCollision.remove(onBallCollisionCB);
	}
}
