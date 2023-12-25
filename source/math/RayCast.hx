package math;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.display.Graphics;
import math.MathUtils.point;
import math.MathUtils.wp;

class RayCast {

	public var model:Array<FlxRect>;
	public var path(default, null):Array<FlxPoint>;

	public var drawCastedRays:Bool = false;

	public var trajectoryColor:Int = 0xFF0000;

	var ray:LineSegment;

	/**
		Rays for debug draw
	**/
	var rays:Array<LineSegment> = [];

	public function new() {
		ray = new LineSegment();
		path = [];
	}

	var castResult:{
		ratio:Float,
		exclude:FlxRect,
		point:FlxPoint,
		normal:FlxPoint,
	} = {
		ratio: 1.0,
		exclude: null,
		point: null,
		normal: point(0, 0),
	};

	/**
		Performs a ray cast and returns a trajectory.
		@param start Ray origin
		@param dir Ray direction vector (its length is taken into account)
		@param reflections Maximum number of reflections. 
												With 2 reflections there will be max 3 segments of trajectory
		@param maxLength	Ray length limit. If it zero than `dir` parameter will be used
											as it is. Otherwise `dir` will be truncated.
		@return List of points representing ray path.
						In case of no obstacles the list will contain
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

		var velocity = dir.clone();
		if (maxLength != 0)
			velocity.truncate(maxLength);
		var end = velocity.clone();
		end.add(start.x, start.y);
		ray.set(start.x, start.y, end.x, end.y);

		if (drawCastedRays)
			rays.push(ray.clone());

		// trace('RAY CAST started');

		// first point of trajectory - segment start
		path.push(ray.start.clone());

		// excluding the rect if a ray was cast outside the rect
		// this prevents fals positive collision check
		castResult.exclude = Lambda.find(model, r -> r.containsPoint(ray.start));
		var normal = point();

		for (i in 0...reflections + 1) {
			// trace('cast ${i+1}');
			// trace('Ray: $ray');

			castResult.ratio = 1.0;
			castResult.point = null;
			castResult.normal.set(0, 0);

			for (rect in model) {

				// intersection point lies on a target segment
				// means when we do next intersection check
				// previous segment must be excluded,
				// or the point slighlty adjusted
				if (rect == castResult.exclude)
					continue;

				processRayCast(ray, rect, normal, untyped castResult);
			}

			if (castResult.point != null) {
				// trace('closest intersection: ${castResult.point}');

				// reflect velocity vector for next reflected segment
				velocity.bounce(castResult.normal, 1);

				// make the segment to be reflected one
				// var endp = castResult.point.clone(FlxPoint.weak()).addPoint(velocity);
				var endp = wp(castResult.point + velocity);
				ray.setPoints(castResult.point, endp);

				path.push(castResult.point);

				if (drawCastedRays)
					rays.push(ray.clone());
			}
			else {
				// abort when no intersection was found
				// trace('NO INTERSECTIONS!');
				break;
			}
		}

		if (path.length == 1)
			path.push(ray.end.clone());

		// trace('RAY CAST completed, points found: ${path.length}\n.\n..\n.');

		ray.set(0, 0, 0, 0);
		velocity.put();
		end.put();
		normal.put();
		start.putWeak();
		dir.putWeak();

		return path;
	}

	function processRayCast(ray:LineSegment, rect:FlxRect, normal:FlxPoint, result) {

		var ip = ray.intersectionPointWithRect(rect, normal);
		if (ip != null) {
			// trace('intersection with ${rect}: $ip');

			// round point
			// pathPoint.set(FlxMath.roundDecimal(pathPoint.x, 1), FlxMath.roundDecimal(pathPoint.y, 1));

			var r = ray.ratioOf(ip);
			if (r < result.ratio && !FlxMath.equal(0, r, 0.001)) {
				result.ratio = r;
				result.point = ip;
				result.exclude = rect;
				// `result` is not typed and haxe struggles to type it
				// so it doesnt know that `result.normal.copyFrom()` is valid
				// so I have to help with `cast`
				(cast result.normal : FlxPoint).copyFrom(normal);

				// trace('exclude ${result.exclude}');
			}
			else {
				ip.put();
			}
		}
		else {
			// trace('intersection with ${rect}: NO');
		}
	}

	public function draw(gfx:Graphics) {
		drawPath(gfx, trajectoryColor);
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

		// draw lines
		var w = 1.5;
		gfx.moveTo(start.x, start.y);
		gfx.lineStyle(w, color, 0.5);
		for (i in 1...path.length) {
			var p = path[i];
			gfx.lineTo(p.x, p.y);
			gfx.lineStyle(w, color, 0.5 + astep * (i - 1));
		}
		gfx.endFill();

		// draw rects
		var size = 5;
		gfx.beginFill(color, 0.6);
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
