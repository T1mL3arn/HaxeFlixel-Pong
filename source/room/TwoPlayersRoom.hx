package room;

import haxe.Timer;
import Player.PlayerOptions;
import Pong.PongParams;
import Utils.merge;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import menu.CongratScreen;
import mod.BallSpeedup;
import utils.FlxSpriteDraw.twinkle;

using Lambda;
using StringTools;
using Utils;

class TwoPlayersRoom extends BaseState {

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

		var room = LevelBuilder.inst.buildTwoPlayersRoom(leftOptions, rightOptions);

		add(room.middleLine);

		ball = room.ball;
		add(ball);

		walls = new FlxTypedGroup();
		room.walls.iter(wall -> walls.add(cast add(wall)));

		playerGoals = new FlxTypedGroup();
		players = room.players;
		players.iter(player -> {
			add(player);
			walls.add(player.racket);
			playerGoals.add(player.hitArea);
		});

		ballSpeedup = new BallSpeedup();

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
				serveBall(player, ball);
				firstServe = false;
			}
		}
	}

	function ballOutWorldBounds() {
		if (!ball.inWorldBounds()) {
			resetBall();
			serveBall(Flixel.random.getObject(players), ball);
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
		GAME.ballCollision.dispatch(wall, ball);
	}

	function goal(hitArea:FlxBasic, ball:Ball) {
		var looser = players.find(p -> p.hitArea == hitArea);
		var winner = players.find(p -> p.racket == ball.hitBy);
		// NOTE: having a looser without a winner means
		// it was a ball serve, in this case goal doesnt count
		// and ball re-served the same way
		var ballServer = winner ?? looser;

		if (winner != null) {
			updateScore(winner, winner.score + 1);
			ballSpeedup.onGoal();
		}

		// checking the winner
		winner = players.find(p -> p.score >= Pong.params.scoreToWin);
		if (winner != null) {
			trace('Winner: ${winner.name} !');
			canPause = true;
			canOpenPauseMenu = false;
			for (player in players) {
				player.active = false;
				// AI moves its racket with FlxTween, so such tweens must be canceled.
				GAME.aiTweens.cancelTweensOf(player.racket);
			}
			showCongratScreen(winner, FOR_WINNER);
		}
		else if (ballServer != null) {
			resetBall();
			serveBall(ballServer, ball);
		}
	}

	function updateScore(player:Player, score) {
		player.score = score;
	}

	function showCongratScreen(player:Player, screenType:CongratScreenType) {
		var playAgainAction = _ -> Flixel.switchState(new TwoPlayersRoom(leftOptions, rightOptions));
		openSubState(new CongratScreen(playAgainAction).setWinner(player.name, screenType));
	}

	function serveBall(byPlayer:Player, ball:Ball, delay:Int = 1000) {

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

		Timer.delay(() -> ball.velocity.set(velX, 0), delay);

		twinkle(ball, FlxColor.ORANGE, delay * 0.001, 0.1);
	}
}
