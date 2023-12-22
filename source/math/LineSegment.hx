package math;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

@:forward(set, put)
abstract Interval(FlxPoint) from FlxPoint to FlxPoint {

	public inline function min():Float
		return this.x;

	public inline function max():Float
		return this.y;

	//
}

/**
	Line segment
**/
class LineSegment {

	public static var EPSILON = 0.000001;

	public var start:FlxPoint;
	public var end:FlxPoint;

	var xInterval:Interval;
	var yInterval:Interval;

	public function new(sx, sy, ex, ey) {
		start = FlxPoint.get(sx, sy);
		end = FlxPoint.get(ex, ey);

		xInterval = FlxPoint.get();
		yInterval = FlxPoint.get();
		setInterval();
	}

	public function set(sx, sy, ex, ey) {
		start.set(sx, sy);
		end.set(ex, ey);
		setInterval();
		return this;
	}

	function setInterval() {
		// xInterval.set(Math.min(start.x, end.x), Math.min(start.y, end.y));
		// yInterval.set(Math.max(start.x, end.x), Math.max(start.y, end.y));
	}

	/**
		Returns intersection point of this and given line segments.
		IF no intersection is found `null` is returned.

		**NOTE**: If both segments are lie on the same line and overlaping
		it still means NO INTERSECTION
		@param seg 
		@return FlxPoint
	**/
	public function intersectionPoint(seg:LineSegment):Null<FlxPoint> {

		var x1 = start.x;
		var y1 = start.y;
		var x2 = end.x;
		var y2 = end.y;
		var x3 = seg.start.x;
		var y3 = seg.start.y;
		var x4 = seg.end.x;
		var y4 = seg.end.y;

		final l1_dx = x1 - x2;
		final l1_dy = y1 - y2;
		final l2_dx = x3 - x4;
		final l2_dy = y3 - y4;

		// Cross product denominator
		var denominator = l1_dx * l2_dy - l1_dy * l2_dx;

		// When abs of denominator is zero - vectors are parallel/collinear
		// so we dont have intersection
		if (Math.abs(denominator) < EPSILON) {
			return null;
			// TODO check if segments are overlaping
			// and find min point as an intersection
		}

		// here is some math things from gpt I didn't understand
		var px = ((x1 * y2 - y1 * x2) * l2_dx - l1_dx * (x3 * y4 - y3 * x4)) / denominator;
		var py = ((x1 * y2 - y1 * x2) * l2_dy - l1_dy * (x3 * y4 - y3 * x4)) / denominator;

		// 1. here is an intersection point like these are LINES and not SEGMENTS!
		var intersection = FlxPoint.get(px, py);

		// 2. the idea is to test is that intersection point lies
		// inside both rects constructed from segments
		var r1 = FlxRect.get().fromTwoPoints(start, end);
		var r2 = FlxRect.get().fromTwoPoints(seg.start, seg.end);

		// TODO use my EPSILON somehow ?
		// In this concrete example Flixel 5.6.0 does not use its own EPSILON
		var inBounds = r1.containsPoint(intersection) && r2.containsPoint(intersection);

		// 3. so if the intersection belongs to both rects
		if (inBounds) {
			r1.destroy();
			r2.destroy();
			// 4. it is the correct intersection
			return intersection;
		}

		// 5. otherwise segments does not intersect
		intersection.put();
		r1.destroy();
		r2.destroy();
		return null;
	}

	public function clone() {
		return new LineSegment(start.x, start.y, end.x, end.y);
	}

	public function translate(dx:Float = 0, dy:Float = 0) {
		start.add(dx, dy);
		end.add(dx, dy);
		setInterval();
		return this;
	}

	function doBoundsIntersect(s:LineSegment):Bool {
		var r1 = new FlxRect().fromTwoPoints(start, end);
		var r2 = new FlxRect().fromTwoPoints(s.start, s.end);

		var r3 = r1.intersection(r2);
		var result = !r1.isEmpty;

		r1.destroy();
		r2.destroy();
		r3.destroy();
		return result;
	}

	public function intersectionPointWithRect(rect:FlxRect):Null<FlxPoint> {
		var top = new LineSegment(rect.left, rect.top, rect.right, rect.top);
		var result:FlxPoint = null;

		if ((result = this.intersectionPoint(top)) != null) {
			top.destroy();
			return result;
		}

		var right = top.set(rect.right, rect.top, rect.right, rect.bottom);
		if ((result = this.intersectionPoint(top)) != null) {
			top.destroy();
			return result;
		}

		var bottom = new LineSegment(rect.right, rect.bottom, rect.left, rect.bottom);
		var left = new LineSegment(rect.left, rect.bottom, rect.left, rect.top);
		return null;
	}

	public function destroy() {
		start.put();
		end.put();
		xInterval.put();
		yInterval.put();
	}

	@:noCompletion
	function test() {
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
}
