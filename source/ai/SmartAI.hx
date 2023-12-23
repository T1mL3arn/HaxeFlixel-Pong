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
import openfl.display.Graphics;

class WallModel extends FlxRect {

	public var source:FlxObject;
}

class SmartAI extends SimpleAI {

	/**
		Room objects to model ball trajectory 
	**/
	var roomModel:Array<FlxRect>;

	/**
		Link between real flixel objects and their models.
	**/
	var objToModel:Map<FlxObject, FlxRect>;

	final maxTrajectorySegments:Int = 10;

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
	}

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

		objToModel = new ObjectMap();
		roomModel = [];

		// ~adjust~ box
		final bhw = GAME.room.ball.width * 0.5;

		// - use ball's center of mass to calc its trajectory and collisions
		// - this means I have to ~adjust~ wall sizes for room model,
		// 		wall must be bigger on half_ball from every side

		for (w in GAME.room.walls.members) {
			var box = w.getHitbox();
			if (w is Racket) {
				// wall model from racket inflates to fill
				// entire screen height
				box.top = 0;
				box.bottom = Flixel.height;
			}

			box.left -= bhw;
			box.top -= bhw;
			box.right += bhw;
			box.bottom += bhw;

			roomModel.push(box);
			objToModel.set(w, box);
		}
	}

	var path:Array<FlxPoint>;

	var segToDraw:LineSegment;

	function calcTrajectory(object:FlxObject, ball:Ball) {
		// if (object is Racket && object != this.racket) {
		// if (object is Racket) {

		for (point in path) {
			point.put();
		}
		path = [];
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
		var velocity = ball.velocity.clone();
		var seg = new LineSegment(x, y, velocity.x, velocity.y);
		// translating and scaling ball velocity
		// to setup initial segment
		seg.end.scale(100).truncate(1000).add(x, y);

		segToDraw = seg;

		// first point oftrajectory - segment start
		path.push(seg.start.clone());

		var exclude:FlxRect = object == null ? null : objToModel.get(object);
		var edgeNormal = FlxPoint.get(0, 0);

		for (i in 0...maxTrajectorySegments) {
			var pathPoint:FlxPoint = null;

			for (rect in roomModel) {
				// intersection point lies on a target segment
				// means when we do next intersection check
				// previous segment must be excluded,
				// or the point slighlty adjusted
				if (rect == exclude)
					continue;

				pathPoint = seg.intersectionPointWithRect(rect, edgeNormal);
				if (pathPoint != null) {

					// round point
					pathPoint.set(FlxMath.roundDecimal(pathPoint.x, 1), FlxMath.roundDecimal(pathPoint.y, 1));

					// path.push(seg.start.clone());
					path.push(pathPoint);

					// getting the normal of intersection
					// to immitate ball velocity change after
					// "collision" with the wall
					edgeNormal.normalize().round();
					if (Math.abs(edgeNormal.x) == 1)
						velocity.x *= -1;
					if (Math.abs(edgeNormal.y) == 1)
						velocity.y *= -1;

					// updating segment
					seg.start.copyFrom(pathPoint);
					seg.end.copyFrom(velocity.scale(100).truncate(1000)).add(pathPoint.x, pathPoint.y);
					exclude = rect;
					break;
				}
			}

			// if (pathPoint != null)
			// 	path.push(pathPoint);
		}
		// if (path.length == 1)
		// path.push(seg.end.clone());

		seg.destroy();
		velocity.put();
		edgeNormal.put();
	}

	override function update(dt:Float) {
		super.update(dt);

		// if (path.length > (maxTrajectorySegments + 1))
		// 	path = path.slice(path.length - (maxTrajectorySegments + 1));

		drawPath(path, 0xFF0000);
		drawModel();

		// draw
		var gfx = Flixel.camera.debugLayer.graphics;
		// draw ball velocity
		var ball = GAME.room.ball;
		gfx.lineStyle(1.5, 0x00FF55, 0.5);
		gfx.moveTo(ball.x, ball.y - 15);
		gfx.lineTo(ball.velocity.x + ball.x, ball.velocity.y + ball.y - 15);
		gfx.endFill();
	}

	function drawPath(path:Array<FlxPoint>, color:Int) {
		if (path.length == 0)
			return;

		var ab = 0.33;
		var astep = (1 - ab) / path.length;
		var start = path[0];
		var gfx = Flixel.camera.debugLayer.graphics;

		// draw lines
		gfx.moveTo(start.x, start.y);
		gfx.lineStyle(3, color, 0.5);
		for (i in 1...path.length) {
			var p = path[i];
			gfx.lineTo(p.x, p.y);
			gfx.lineStyle(3, color, 0.5 + astep * (i - 1));
		}
		gfx.endFill();

		// rect size
		var rs = 5;
		// draw rects
		for (point in path) {
			drawRect(point, rs, color, gfx);
		}
	}

	function drawRect(p:FlxPoint, size, color, gfx:Graphics) {
		final hs = size * 0.5;
		gfx.beginFill(color, 0.8);
		gfx.drawRect(p.x - hs, p.y - hs, size, size);
		gfx.endFill();
	}

	function drawModel() {
		var gfx = Flixel.camera.debugLayer.graphics;

		gfx.lineStyle(1, 0x44A2FF);
		for (rect in roomModel) {
			gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
		}
		gfx.endFill();
	}
}
