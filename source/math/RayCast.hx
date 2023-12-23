package math;

import haxe.Log;
import haxe.PosInfos;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import openfl.display.Graphics;
import utils.FlxDragManager;

class RayCast {

	public var objToModel:Map<FlxObject, FlxRect>;
	public var model:Array<FlxRect>;
	public var path(default, null):Array<FlxPoint>;

	var seg:LineSegment;

	public var rays:Array<LineSegment> = [];

	public function new() {
		seg = new LineSegment();
		path = [];
	}

	public function castRay(start:FlxPoint, dir:FlxPoint, refractions:Int = 7, maxLength:Float = 0):Array<FlxPoint> {

		for (point in path) {
			point.put();
		}
		path = [];

		for (ray in rays) {
			ray.destroy();
		}
		rays = [];

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

		rays.push(seg.clone());

		trace('RAY CAST started');

		// first point of trajectory - segment start
		path.push(seg.start.clone());

		// excluding the rect if a ray was cast outside the rect
		// this prevents fals positive collision check
		var exclude:FlxRect = Lambda.find(model, r -> r.containsPoint(seg.start));
		var edgeNormal = FlxPoint.get(0, 0);

		for (i in 0...refractions) {
			trace('cast $i');
			trace('Ray: $seg');

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

					trace('intersection with ${rect}: $pathPoint');

					// round point
					// pathPoint.set(FlxMath.roundDecimal(pathPoint.x, 1), FlxMath.roundDecimal(pathPoint.y, 1));

					results.push({point: pathPoint, rect: rect, normal: edgeNormal.clone().normalize().round()});
				}
				else {
					trace('intersection with ${rect}: NO');
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
					trace('exclude $exclude');
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

				trace('closest intersection: $closestIntersection');

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
				rays.push(seg.clone());
				closestIntersectionNormal.put();
			}
			else {
				// abort when no intersection was found
				trace('NO INTERSECTIONS!');
				break;
			}
		}

		if (path.length == 1)
			path.push(seg.end.clone());

		trace('RAY CAST completed, points found: ${path.length}\n.\n..\n.');

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

		// draw segment;
		gfx.lineStyle(1.5, 0xFFFFFF, 0.5);
		gfx.moveTo(seg.start.x, seg.start.y + 15);
		gfx.lineTo(seg.end.x, seg.end.y + 15);
		gfx.endFill();
	}

	public function drawPath(gfx:Graphics, color:Int = 0xFF0000) {
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

class RayCastTest extends FlxState {

	var start:FlxSprite;
	var end:FlxSprite;
	var rayCast = new RayCast();
	var drag:FlxDragManager;
	var model:Array<FlxRect> = [];
	var startPoint = new FlxPoint();
	var endPoint = new FlxPoint();

	public function new() {
		super();
	}

	override function create() {
		super.create();

		bgColor = 0xFF222222;

		start = new FlxSprite(0, 0);
		start.makeGraphic(8, 8, FlxColor.WHITE);
		start.updateHitbox();
		start.centerOffsets();
		start.setPosition(100, 100);
		add(start);

		end = new FlxSprite(0, 0);
		end.makeGraphic(10, 10, 0xFFFFBF0E);
		end.updateHitbox();
		end.centerOffsets();
		end.setPosition(400, 300);
		add(end);

		updatePositions();

		drag = Flixel.plugins.get(FlxDragManager) ?? new FlxDragManager();
		Flixel.plugins.add(drag);
		drag.onDragStop = cast doCast;

		drag.add(start);
		drag.add(end);

		rayCast.model = buildModel();
		doCast();
	}

	function buildModel() {
		var model = [];
		var box = new FlxObject(0, 0, 150, 150);
		box.screenCenter();

		model.push(box.getHitbox());
		model.push(new FlxObject(10, 20, 20, 400).getHitbox());
		model.push(new FlxObject(450, 0, 20, 400).getHitbox());
		model.push(new FlxObject(50, 440, 400, 15).getHitbox());

		return model;
	}

	function doCast(?_) {
		updatePositions();
		var dir = endPoint.subtractNew(startPoint).scale(3);
		rayCast.castRay(startPoint, dir, 7, 500);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	function updatePositions() {
		var s = start.width * 0.5;
		startPoint.set(start.x + s, start.y + s);
		s = end.width * 0.5;
		endPoint.set(end.x + s, end.y + s);
	}

	override function draw() {
		super.draw();

		// lst.update(Flixel.elapsed);

		updatePositions();

		if (Flixel.mouse.justMoved && Flixel.mouse.pressed) {
			// updatePositions();
			// doCast();
		}

		var gfx = Flixel.camera.debugLayer.graphics;
		rayCast.draw(gfx);

		// draw ours start-end segment
		gfx.lineStyle(2, 0xFFFFFF);
		gfx.moveTo(startPoint.x, startPoint.y);
		gfx.lineTo(endPoint.x, endPoint.y);
		gfx.endFill();

		rayCast.drawRays(gfx);
	}
}
