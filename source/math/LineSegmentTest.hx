package math;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;

/**
	To test `LineSegment` class.
	Two purposes:
	- visualizations
	- some unit tests
**/
class LineSegmentTest {

	var seg:LineSegment;
	var angle:Float = 30;
	var rect:FlxRect;

	public function new() {
		seg = new LineSegment(-150, 0, 150, 0);
		rect = new FlxRect(0, 0, 200, 200);
		rect.x = Flixel.width * 0.5 - rect.width * 0.5;
		rect.y = Flixel.height * 0.5 - rect.height * 0.5;
	}

	public function update(dt:Float) {
		var deltaDegrees = 0.5;
		angle += deltaDegrees;

		seg.set(-180, 0, 180, 0);
		seg.rotateByDegrees(angle);
		// seg.translate(Flixel.mouse.screenX, Flixel.mouse.screenY);
		seg.translate(Flixel.width * 0.5, Flixel.height * 0.5);

		// rect to test intersections
		var gfx = Flixel.camera.debugLayer.graphics;
		gfx.lineStyle(2, 0xFFFFFFF);
		gfx.drawRect(rect.x, rect.y, rect.width, rect.height);

		// line segment
		gfx.moveTo(seg.start.x, seg.start.y);
		gfx.lineTo(seg.end.x, seg.end.y);

		// line segment start
		gfx.lineStyle(3, 0x0000FF);
		gfx.beginFill(FlxColor.WHITE);
		gfx.drawCircle(seg.start.x, seg.start.y, 7);

		// intersection point
		var ip = seg.intersectionPointWithRect(rect);

		// Well, Flixel actually has methods to find intersection
		// but the API is confusing I didn't understand it at first
		// so I implemented my own version.
		// seg.start.findIntersectionInBounds()
		// var right = new LineSegment(rect.right, rect.top, rect.right, rect.bottom);
		// var ip = seg.start.intersectionWithSegment(seg.end - seg.start, right.start, right.end - right.start);

		if (ip != null && ip.isValid()) {
			if (ip.x < 0 || ip.x > Flixel.width || ip.y < 0 || ip.y > Flixel.height) {
				ip.put();
				return;
			}
			gfx.endFill();
			gfx.lineStyle(null);
			gfx.beginFill(0x00FF6A);
			gfx.drawCircle(ip.x, ip.y, 5);
			gfx.endFill();
			ip.put();
		}
		gfx.endFill();
	}

	@:noCompletion
	function test_intersectionPoint() {
		var zero = FlxPoint.get(0, 0);

		// two parallel segments
		var a = new LineSegment(1, 1, 3, 3);
		var b = a.clone().translate(0, 3);
		assert(null, a.intersectionPoint(b), '1');

		// perpendiculars out of the same point
		a.set(0, 0, 5, 0);
		b.set(0, 0, 0, 5);
		assert(true, a.intersectionPoint(b)?.equals(zero), '2. Not equals (0,0)');

		// not perps out of the same point
		a.set(0, 0, 5, 0);
		b.set(0, 0, -1, -5);
		assert(true, a.intersectionPoint(b)?.equals(zero), '3. Not equals (0,0)');

		// ends in the same point
		a.set(1, 3, 5, -7);
		b.set(-2, -10, 5, -7);
		assert(true, a.intersectionPoint(b)?.equals(FlxPoint.weak(5, -7)), '4. Not equals (5,-7)');

		// lies in the same line, outs of the same point
		a.set(0, 0, 0, 10);
		b.set(0, 0, -10, 0);
		assert(true, a.intersectionPoint(b)?.equals(zero), '5. Not equals (0,0)');

		var ctr = 5;

		// lies in the same line, outs of diff points
		a.set(0, 0, 0, 10);
		b.set(-2, 0, -10, 0);
		assert(null, a.intersectionPoint(b), '${ctr += 1}');

		// two perps
		a.set(1, 1, 5, 1);
		b.set(2, 2, 2, -5);
		assert(true, a.intersectionPoint(b)?.equals(FlxPoint.weak(2, 1)), '${ctr += 1}. Not qquals (2,1)');

		// one segment lies completely inside another one
		a.set(2, 2, 5, 5);
		b.set(3, 3, 4, 4);
		var p = a.intersectionPoint(b);
		trace(p);
		assert(null, p, '${ctr += 1}. Intersection is not null');
	}

	@:noCompletion
	function assert(expected:Any, actual:Any, ?msg) {
		if (expected != actual)
			trace('$msg: actual must be ${expected}, but it is ${actual}');
	}

	@:noCompletion
	public function test_intersectionPointWithRect() {
		var rect = new FlxRect(10, 10, 50, 50);
		var seg = new LineSegment(0, 0, 0, 0);

		var n = 0;

		seg.set(0, 0, 80, 80);
		assert(true, seg.intersectionPointWithRect(rect)?.equals(FlxPoint.weak(10, 10)), '1');

		seg.set(0, 10, 80, 10);
		assert(true, seg.intersectionPointWithRect(rect)?.equals(FlxPoint.weak(10, 10)), '2');

		seg.set(0, 20, 80, 20);
		assert(true, seg.intersectionPointWithRect(rect)?.equals(FlxPoint.weak(10, 20)), '3');

		seg.set(0, 10, 80, 90);
		var ip = seg.intersectionPointWithRect(rect);
		assert(true, ip?.equals(FlxPoint.weak(10, 20)), '4. ${ip}');
	}
}
