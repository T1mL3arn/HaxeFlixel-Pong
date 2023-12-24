package math;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.display.Graphics;

class RayCast {

	public var objToModel:Map<FlxObject, FlxRect>;
	public var model:Array<FlxRect>;
	public var path(default, null):Array<FlxPoint>;

	public var drawCastedRays:Bool = false;

	var seg:LineSegment;

	/**
		Rays for debug draw
	**/
	var rays:Array<LineSegment> = [];

	public function new() {
		seg = new LineSegment();
		path = [];
	}

	/**
		Performs a ray cast and returns a trajectory.
		@param start Ray origin
		@param dir Ray direction vector (its lenght is taken into account)
		@param reflections Maximum number of reflections. 
												With 2 reflections there will be max 3 segments of trajectory
		@param maxLength	Ray length limit. If it zero than `dir` parameter will be used
											as it is. Otherwise `dir` will be truncated.
		@return List of points representing ray path.
						In case where were no obstacles the list will contain
						ray's `start` and `end` points.
	**/
	public function castRay(start:FlxPoint, dir:FlxPoint, reflections:Int = 5, maxLength:Float = 0):Array<FlxPoint> {

		for (point in path) {
			point.put();
		}
		path = [];

		if (drawCastedRays) {
			for (ray in rays) {
				ray.destroy();
			}
			rays = [];
		}

		// test intersection with room model, starting with START point
		// if intersection (A) is found with our goal
		// 		calc position to bounce
		// otherwise
		// 		add data to the trajectory path (?)
		// 		start new intersection test starting at (A)

		var velocity = dir.clone();
		if (maxLength != 0)
			velocity.truncate(maxLength);
		var end = velocity.clone();
		end.add(start.x, start.y);
		var seg = new LineSegment(start.x, start.y, end.x, end.y);

		if (drawCastedRays)
			rays.push(seg.clone());

		// trace('RAY CAST started');

		// first point of trajectory - segment start
		path.push(seg.start.clone());

		// excluding the rect if a ray was cast outside the rect
		// this prevents fals positive collision check
		var exclude:FlxRect = Lambda.find(model, r -> r.containsPoint(seg.start));
		var edgeNormal = FlxPoint.get(0, 0);

		for (i in 0...reflections + 1) {
			// trace('cast $i');
			// trace('Ray: $seg');

			var pathPoint:FlxPoint = null;

			var results:Array<{
				point:FlxPoint,
				rect:FlxRect,
				normal:FlxPoint,
			}> = [];

			for (rect in model) {
				// intersection point lies on a target segment
				// means when we do next intersection check
				// previous segment must be excluded,
				// or the point slighlty adjusted
				if (rect == exclude)
					continue;

				pathPoint = seg.intersectionPointWithRect(rect, edgeNormal);
				if (pathPoint != null) {

					// trace('intersection with ${rect}: $pathPoint');

					// round point
					// pathPoint.set(FlxMath.roundDecimal(pathPoint.x, 1), FlxMath.roundDecimal(pathPoint.y, 1));

					results.push({point: pathPoint, rect: rect, normal: edgeNormal.clone().normalize().round()});
				}
				else {
					// trace('intersection with ${rect}: NO');
				}
			}

			// finding a point closest to segment's END
			var closestPoint:FlxPoint = null;
			var closestNormal:FlxPoint = null;
			exclude = null;
			var br = 1.0;
			for (res in results) {
				var ratio = seg.ratioOf(res.point);
				if (ratio < br) {
					closestPoint = res.point;
					closestNormal = res.normal;
					exclude = res.rect;
					// trace('exclude $exclude');
					br = ratio;
				}
			}

			if (closestPoint != null) {
				var closestIntersection = closestPoint.clone();
				var closestIntersectionNormal = closestNormal.clone();
				for (res in results) {
					res.point.put();
					res.normal.put();
				}

				// trace('closest intersection: $closestIntersection');

				// use normal of intersection
				// to immitate ball velocity change after
				// "collision" with the wall
				if (Math.abs(closestIntersectionNormal.x) == 1)
					velocity.x *= -1;
				if (Math.abs(closestIntersectionNormal.y) == 1)
					velocity.y *= -1;

				// updating segment
				var endp = closestIntersection.clone(FlxPoint.weak()).addPoint(velocity);
				seg.setPoints(closestIntersection, endp);

				path.push(closestIntersection);

				if (drawCastedRays)
					rays.push(seg.clone());

				closestIntersectionNormal.put();
			}
			else {
				// abort when no intersection was found
				// trace('NO INTERSECTIONS!');
				break;
			}
		}

		if (path.length == 1)
			path.push(seg.end.clone());

		// trace('RAY CAST completed, points found: ${path.length}\n.\n..\n.');

		seg.destroy();
		velocity.put();
		edgeNormal.put();
		end.put();
		start.putWeak();
		dir.putWeak();

		return path;
	}

	public function draw(gfx:Graphics) {
		drawPath(gfx);
		drawModel(gfx);
		if (drawCastedRays)
			drawRays(gfx);
	}

	public function drawPath(gfx:Graphics, color:Int = 0xFF0000) {
		if (path.length == 0)
			return;

		var ab = 0.2;
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

		// draw rects
		var size = 5;
		gfx.beginFill(color, 0.8);
		for (point in path) {
			gfx.drawRect(point.x - size * 0.5, point.y - size * 0.5, size, size);
		}
		gfx.endFill();
	}

	public function drawModel(gfx:Graphics, color:Int = 0x44A2FF) {
		gfx.lineStyle(1, color);
		for (rect in model) {
			gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
		}
		gfx.endFill();
	}

	public function drawRays(gfx:Graphics, color:Int = 0x7EFFA5) {
		gfx.lineStyle(1, color, 0.33);
		for (ray in rays) {
			gfx.moveTo(ray.start.x, ray.start.y);
			gfx.lineTo(ray.end.x, ray.end.y);
		}
		gfx.endFill();
	}
}
