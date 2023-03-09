package;

import Player.PlayerOptions;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;

using Lambda;
using StringTools;
using Utils;

class TwoPlayersRoom extends FlxState {

	var walls:FlxTypedGroup<FlxObject>;
	var players:Array<Player>;
	var playerGoals:FlxTypedGroup<FlxObject>;
	var ball:Ball;

	var leftOptions:PlayerOptions;
	var rightOptions:PlayerOptions;

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

		if (ball.velocity.lengthSquared == 0 && (Flixel.keys.justPressed.ANY && !Flixel.keys.pressed.F2)) {
			var sign = Math.random() < 0.5 ? -1 : 1;
			ball.velocity.setPolarDegrees(Pong.defaults.ballSpeed, Flixel.random.int(60, -60));
			ball.velocity.x *= sign;
		}

		Flixel.collide(walls, ball, ballCollision);
		Flixel.overlap(playerGoals, ball, goal);

		if (!ball.inWorldBounds()) {
			resetBall();
		}
	}

	function resetBall() {
		ball.velocity.set(0, 0);
		ball.screenCenter();
		ball.hitBy = null;
	}

	function throwBall(from, degrees:Float) {}

	function ballCollision(wall:FlxObject, ball:Ball) {
		if (wall is Racket) {
			(cast wall : Racket).ballCollision(ball);
		}
		ball.collision(wall);
		Pong.inst.ballCollision.dispatch(wall, ball);
	}

	function goal(hitArea:FlxBasic, ball:Ball) {
		var looser = players.find(p -> p.hitArea == hitArea);
		var winner = players.find(p -> p.racket == ball.hitBy);
		if (looser != null && winner != null) {
			trace('goal');
			winner.score += 1;
			resetBall();
		}
	}
}
