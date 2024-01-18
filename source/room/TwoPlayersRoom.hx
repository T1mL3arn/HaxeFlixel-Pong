package room;

import Player.PlayerOptions;
import Pong.PongParams;
import ai.BaseAI;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import menu.CongratScreen;
import mod.BallSpeedup;
import mod.CornerGoalWatch;
import racket.Racket;
import state.BaseGameState;
import utils.FlxSpriteDraw.twinkle;

using Lambda;
using StringTools;
using Utils;

class TwoPlayersRoom extends BaseGameState {

	var walls:FlxTypedGroup<FlxObject>;
	var players:Array<Player>;
	var playerGoals:FlxTypedGroup<FlxObject>;
	var ball:Ball;
	var ballSpeedup:BallSpeedup;

	var leftOptions:PlayerOptions;
	var rightOptions:PlayerOptions;

	var firstServe:Bool = true;

	public function new(?left:PlayerOptions, ?right:PlayerOptions) {
		super();
		leftOptions = left;
		rightOptions = right;
	}

	override function create() {
		super.create();

		Pong.resetParams();
		#if debug
		Pong.params.scoreToWin = 2;
		#end

		var room = LevelBuilder.inst.buildTwoPlayersRoom(leftOptions, rightOptions);

		gameObjects.add(room.middleLine);

		ball = room.ball;
		gameObjects.add(ball);

		walls = new FlxTypedGroup();
		room.walls.iter(wall -> walls.add(cast add(wall)));

		playerGoals = new FlxTypedGroup();
		players = room.players;
		players.iter(player -> {
			gameObjects.add(player);
			walls.add(player.racket);
			playerGoals.add(player.hitArea);
		});

		ballSpeedup = new BallSpeedup();

		gameObjects.add(new CornerGoalWatch(players.map(p -> p.racket)));

		GAME.room = cast this;
	}

	override function destroy() {
		super.destroy();

		walls.destroy();
		players.iter(p -> p.destroy());
		playerGoals.destroy();
		ball.destroy();
		GAME.room = null;
	}

	override function update(dt:Float) {
		super.update(dt);

		fisrtBallServe();

		Flixel.collide(walls, ball, ballCollision);
		Flixel.overlap(playerGoals, ball, goal);

		ballOutWorldBounds();
	}

	function fisrtBallServe() {
		// NOTE vscode cannot find "firstServe" id to do rename-rafactoring
		if (players[0].active && players[1].active) {
			if (ball.velocity.lengthSquared == 0 && firstServe) {
				var player = Flixel.random.getObject(players);
				serveBall(player, ball, Pong.params.ballServeDelay);
				firstServe = false;
			}
		}
	}

	function ballOutWorldBounds() {
		if (!ball.inWorldBounds()) {
			resetBall();
			serveBall(Flixel.random.getObject(players), ball, Pong.params.ballServeDelay);
		}
	}

	function resetBall() {
		ball.velocity.set(0, 0);
		ball.screenCenter();
		ball.hitBy = null;
		ball.color = FlxColor.WHITE;
	}

	function colorizeBall(racket:Racket, ball:Ball) {
		var player = players.find(p -> p.racket == racket);
		var color = player.options.color;
		color.saturation -= 0.1;
		color.lightness += 0.2;
		ball.color = color;
	}

	function ballCollision(wall:FlxObject, ball:Ball) {
		if (wall is Racket) {
			ballSpeedup.onRacketHit();
			(cast wall : Racket).ballCollision(ball);
			colorizeBall(cast wall, ball);
		}
		ball.collision(wall);
		GAME.signals.ballCollision.dispatch(wall, ball);
	}

	function goal(hitArea:FlxBasic, ball:Ball) {
		var looser = players.find(p -> p.hitArea == hitArea);
		var winner = players.find(p -> p.racket == ball.hitBy);
		// NOTE: having a looser without a winner means
		// it was a ball serve, in this case goal doesnt count
		// and ball re-served the same way
		var ballServer = winner ?? looser;

		if (winner != null) {
			GAME.signals.goal.dispatch(winner);
			updateScore(winner, winner.score + 1);
			ballSpeedup.onGoal();
		}

		// checking the winner of the game
		winner = players.find(p -> p.score >= Pong.params.scoreToWin);
		if (winner != null) {
			trace('Winner: ${winner.name} !');

			// place ball out of goals to fix rare bug
			// with two immediate win events
			ball.x -= Flixel.width * 2;

			canPause = true;
			canOpenPauseMenu = false;
			for (player in players) {
				player.active = false;
			}

			var screenType = if (winner.racketController is BaseAI && !(looser.racketController is BaseAI)) {
				// show LOOSER if human lost  to AI
				FOR_LOOSER;
			}
			else {
				FOR_WINNER;
			}

			showCongratScreen(winner, screenType);
		}
		else if (ballServer != null) {
			resetBall();
			serveBall(ballServer, ball, Pong.params.ballServeDelay);
		}
	}

	public function updateScore(player:Player, newScore) {
		player.score = newScore;
	}

	function showCongratScreen(player:Player, screenType:CongratScreenType) {
		var playAgainAction = _ -> Flixel.switchState(new TwoPlayersRoom(leftOptions, rightOptions));
		openSubState(new CongratScreen(playAgainAction).setWinner(player.name, screenType));
	}

	function serveBall(byPlayer:Player, ball:Ball, delay:Float) {

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

		ballPreServe(ball, delay);
	}

	function ballPreServe(ball:Ball, delay:Float) {
		twinkle(ball, FlxColor.ORANGE, delay, 0.1, timerManager);

		// scale-out effect for the ball
		final scale = 5.0;
		var tb = ball.clone();
		tb.setPosition(ball.x, ball.y);
		tweenManager.tween(tb.scale, {x: scale, y: scale}, delay * 0.5, {ease: FlxEase.linear});
		tweenManager.tween(tb, {alpha: 0.0}, delay * 0.5, {
			ease: FlxEase.linear,
			// remove and destroy temp ball after tween is complete
			onComplete: _ -> remove(tb).destroy()
		});
		add(tb);
	}
}
