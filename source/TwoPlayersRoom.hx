package;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;

using Lambda;

class TwoPlayersRoom extends FlxState {

	var walls:FlxTypedGroup<FlxObject>;
	var players:Array<Player>;
	var playerGoals:FlxTypedGroup<FlxObject>;
	var ball:Ball;

	override function create() {
		super.create();

		bgColor = 0xFF111111;

		var room = LevelBuilder.inst.buildTwoPlayersRoom();

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

		// TODO
	}

	override function update(dt:Float) {
		super.update(dt);

		if (ball.velocity.lengthSquared == 0 && Flixel.keys.justPressed.ANY && !Flixel.keys.pressed.F2) {
			ball.velocity.setPolarDegrees(300, 135 + Flixel.random.int(0, 105));
			ball.velocity.x *= Math.random() < 0.5 ? -1 : 1;
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

	function ballCollision(wall:FlxObject, ball:Ball) {
		if (wall is Racket) {
			ball.hitBy = wall;
		}
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
