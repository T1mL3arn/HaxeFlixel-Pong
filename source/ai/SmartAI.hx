package ai;

import haxe.ds.ObjectMap;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.path.FlxPath;
import flixel.util.FlxSpriteUtil;
import math.LineSegment;
import math.MathUtils.wp;
import math.RayCast;
import openfl.display.Graphics;

class SmartAI extends SimpleAI {

	/**
		Room objects to model ball trajectory 
	**/
	var roomModel:Array<FlxRect>;

	public function new(racket, name) {
		super(racket, name);

		// how does this AI work?

		/**
			- listens ball_serve and ball_collision
			- on these signals calcs possible ball trajectory
			- if trajectory is towards this AI - find the best spot to hit the ball
		**/

		GAME.ballCollision.add(calcTrajectory);
		GAME.signals.ballServed.add(onBallServed);
		Flixel.signals.postStateSwitch.add(buildRoomModel);

		path = [];

		rayCast = new RayCast();
		rayCast2 = new RayCast();
		rayCast2.trajectoryColor = 0xFFBB00;
	}

	var rayCast:RayCast;
	var rayCast2:RayCast;

	override function destroy() {
		super.destroy();

		GAME.ballCollision.remove(calcTrajectory);
		GAME.signals.ballServed.remove(onBallServed);

		Flixel.signals.postStateSwitch.remove(buildRoomModel);

		for (rect in roomModel) {
			rect.put();
		}
	}

	function onBallServed() {
		for (point in path) {
			point.put();
		}
		path = [];
		calcTrajectory(null, GAME.room.ball);
	}

	function buildRoomModel() {

		roomModel = [];

		final bhw = GAME.room.ball.width * 0.5;

		// - use ball's center of mass to calc its trajectory and collisions
		// - this means I have to ~adjust~ wall sizes for room model,
		// 		wall must be bigger on half_ball from every side

		for (w in GAME.room.walls.members) {
			var box = w.getHitbox();
			if (w is Racket) {
				// wall model from racket get scaled to fill
				// the entire screen height
				box.top = 0;
				box.bottom = Flixel.height;
			}

			box.left -= bhw;
			box.top -= bhw;
			box.right += bhw;
			box.bottom += bhw;

			roomModel.push(box);
		}

		rayCast.model = rayCast2.model = roomModel;
	}

	var path:Array<FlxPoint>;

	function calcTrajectory(object:FlxObject, ball:Ball) {

		// trajectory is calculated only when
		// - ball is served
		// - when ball is hit by other racket
		if (!(object == null || object is Racket))
			return;

		// test intersection with room model, starting with START point
		// if intersection (A) is found with our goal
		// 		calc position to bounce
		// otherwise
		// 		add data to the trajectory path (?)
		// 		start new intersection test starting at (A)

		// assuming the ball has equal height and width
		var bhs = ball.width * 0.5;
		var x = ball.x + bhs;
		var y = ball.y + bhs;
		var ray1 = wp().copyFrom(ball.velocity);
		// max trajectory length is a diagonal of screen
		ray1.length = Math.sqrt(Math.pow(Flixel.width, 2) + Math.pow(Flixel.height, 2));
		var ray2 = ray1.clone(wp());

		var error = 0.5;
		ray1.rotateByDegrees(-error);
		ray2.rotateByDegrees(error);

		rayCast.castRay(wp(x, y), ray1, 3);
		rayCast2.castRay(wp(x, y), ray2, 3);
	}

	override function update(dt:Float) {
		super.update(dt);

		rayCast.draw(Flixel.camera.debugLayer.graphics);
		rayCast2.draw(Flixel.camera.debugLayer.graphics);

		return;
		// draw
		var gfx = Flixel.camera.debugLayer.graphics;
		// draw ball velocity
		var ball = GAME.room.ball;
		gfx.lineStyle(1.5, 0x00FF55, 0.5);
		gfx.moveTo(ball.x, ball.y - 15);
		gfx.lineTo(ball.velocity.x + ball.x, ball.velocity.y + ball.y - 15);
		gfx.endFill();
	}
}
