package room;

import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import racket.Racket;
import state.BaseGameState;

using Lambda;

class TrainingRoom extends BaseGameState {

	public var walls:FlxTypedGroup<FlxObject>;
	public var ball:Ball;
	public var player:Player;

	var onGoal:Dynamic->Dynamic->Void;

	override function create() {
		super.create();

		Pong.resetParams();

		walls = new FlxTypedGroup();

		var room = LevelBuilder.inst.buildTraningRoom();

		ball = room.ball;
		player = room.player;

		// add room walls to state and to walls group
		room.walls.iter(wall -> add(this.walls.add(wall)));
		// racket is also a wall - to handle collision
		walls.add(player.racket);
		gameObjects.add(player);
		gameObjects.add(ball);

		onGoal = (_, _) -> {
			resetBall();
			player.score += 1;
		}

		GAME.gameSoundGroup.volume = 1;
	}

	override function destroy() {
		super.destroy();

		walls.destroy();
		ball.destroy();
		player.destroy();
	}

	override function update(dt:Float) {
		super.update(dt);

		if (ball.velocity.lengthSquared == 0 && Flixel.keys.justPressed.ANY) {
			ball.velocity.setPolarDegrees(Pong.params.ballSpeed, Flixel.random.int(135, 225));
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
		if (wall is Racket)
			(cast wall : Racket).ballCollision(ball);

		ball.collision(wall);
		GAME.signals.ballCollision.dispatch(wall, ball);
	}
}
