package room;

import Player.PlayerOptions;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import haxe.Timer;

using Lambda;
using StringTools;
using Utils;

class TwoPlayersRoom extends BaseState {

	var walls:FlxTypedGroup<FlxObject>;
	var players:Array<Player>;
	var playerGoals:FlxTypedGroup<FlxObject>;
	var ball:Ball;

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

		bgColor = 0xFF111111;

		var room = LevelBuilder.inst.buildTwoPlayersRoom(leftOptions, rightOptions);

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
	}

	override function destroy() {
		super.destroy();

		walls.destroy();
		players.iter(p -> p.destroy());
		playerGoals.destroy();
		ball.destroy();
	}

	override function update(dt:Float) {
		super.update(dt);

		// NOTE vscode cannot find "firstServe" id to do rename-rafactoring
		if (players[0].active && players[1].active) {
			if (ball.velocity.lengthSquared == 0 && firstServe) {
				var player = Flixel.random.getObject(players);
				serveBall(player, ball);
				firstServe = false;
			}
		}

		Flixel.collide(walls, ball, ballCollision);
		Flixel.overlap(playerGoals, ball, goal);

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
			(cast wall : Racket).ballCollision(ball);
			colorizeBall(cast wall, ball);
		}
		ball.collision(wall);
		Pong.inst.ballCollision.dispatch(wall, ball);
	}

	function goal(hitArea:FlxBasic, ball:Ball) {
		var looser = players.find(p -> p.hitArea == hitArea);
		var winner = players.find(p -> p.racket == ball.hitBy);

		if (winner != null) {
			winner.score += 1;
			resetBall();

			// winner serves the ball
			serveBall(winner, ball);
		}
		else if (looser != null) {
			// having a looser without a winner means
			// it was a ball serve, in this case goal doesnt count
			// and ball re-served the same way
			resetBall();
			serveBall(looser, ball);
		}
	}

	function serveBall(byPlayer:Player, ball:Ball) {

		var p = byPlayer;
		ball.y = p.racket.y + p.racket.height * 0.5 - ball.height * 0.5;

		var velX = switch byPlayer.options.position {
			case LEFT:
				-Pong.defaults.ballSpeed;
			case RIGHT:
				Pong.defaults.ballSpeed;
			default:
				0;
		}

		Timer.delay(() -> ball.velocity.set(velX, 0), 1000);
	}
}