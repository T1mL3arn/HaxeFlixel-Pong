package;

import flixel.FlxObject;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;

using Lambda;

class TrainingRoom extends FlxState {

	public var walls:FlxTypedGroup<FlxObject> = new FlxTypedGroup();
	public var ball:Ball;
	public var player:Player;

	var onGoal:Dynamic->Dynamic->Void;

	override function create() {

		var room = LevelBuilder.inst.buildTraningRoom();

		ball = room.ball;
		player = room.player;

		// add room walls to state and to walls group
		room.walls.iter(wall -> add(this.walls.add(wall)));
		// racket is also a wall - to handle collision
		walls.add(player.racket);
		add(player);
		add(ball);

		onGoal = (_, _) -> {
			resetBall();
			player.score += 1;
		}
	}

	override function update(dt:Float) {
		super.update(dt);

		if (ball.velocity.lengthSquared == 0 && Flixel.keys.justPressed.ANY) {
			ball.velocity.setPolarDegrees(300, 135 + Flixel.random.int(0, 105));
		}

		Flixel.collide(walls, ball, ballCollision);
		Flixel.overlap(player.hitArea, ball, onGoal);

		if (!ball.inWorldBounds()) {
			resetBall();
		}
	}

	function resetBall() {
		ball.velocity.set(0, 0);
		ball.screenCenter();
		ball.x += Flixel.width * 0.25;
	}

	function ballCollision(wall:FlxObject, ball:Ball) {
		ball.hitBy = wall;
	}
}
