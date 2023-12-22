package math;

import Utils.invLerp;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import utils.FlxSpriteDraw.lerpPoint;

@:forward(set, put)
abstract Interval(FlxPoint) from FlxPoint to FlxPoint {

	public inline function min():Float
		return this.x;

	public inline function max():Float
		return this.y;

	public inline function has(val:Float):Bool {
		return (min() - LineSegment.EPSILON) <= val && val <= max() + LineSegment.EPSILON;
	}
}

@:forward
abstract IntersectionPoint(FlxPoint) from FlxPoint to FlxPoint {

	/**
		Contains left normal of edge's rect intersection
		found with `LineSegment.intersectionPointWithRect`.

		**NOTE**: Internally it uses single static variable, 
		so the actual value 
		@return FlxPoint
	**/
	public inline function intersectionLeftNormal():FlxPoint
		return @:privateAccess LineSegment.ilNormal;

	/**
		Same as `intersectionLeftNormal`
		@return FlxPoint 
	**/
	public inline function iLeftNorm():FlxPoint
		return @:privateAccess LineSegment.ilNormal;
}

/**
	Line segment
**/
class LineSegment {

	public static var EPSILON = 0.000001;

	public var start:FlxPoint;
	public var end:FlxPoint;

	/**
		Left normal of last rect edge intersection.
	**/
	static private var ilNormal(default, null):FlxPoint = new FlxPoint();

	var xInterval:Interval;
	var yInterval:Interval;

	public function new(sx = 0.0, sy = 0.0, ex = 1.0, ey = 1.0) {
		if (ilNormal == null)
			ilNormal = new FlxPoint();

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
		xInterval.set(Math.min(start.x, end.x), Math.max(start.x, end.x));
		yInterval.set(Math.min(start.y, end.y), Math.max(start.y, end.y));
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

		// 2. the idea is to test that intersection point lies
		// inside both X and Y intervals constructed from segments
		var inBounds = xInterval.has(px) && seg.xInterval.has(px) && yInterval.has(py) && seg.yInterval.has(py);

		// 3. so if the intersection belongs to both segments' intervals
		if (inBounds) {
			// 4. it is the correct intersection
			return intersection;
		}

		// 5. otherwise segments does not intersect
		intersection.put();
		return null;
	}

	public function clone() {
		return new LineSegment(start.x, start.y, end.x, end.y);
	}

	/**
		Translates this line segment
		@param dx 
		@param dy 
	**/
	public function translate(dx:Float = 0, dy:Float = 0) {
		start.add(dx, dy);
		end.add(dx, dy);
		setInterval();
		return this;
	}

	/**
		Rotates this segment by given angle (in radians)
		@param rad angle in radians
		@param origin 
	**/
	public function rotate(rad:Float, ?origin:FlxPoint):LineSegment {
		if (origin != null)
			// TODO
			throw 'Not implemented';

		start.rotateByRadians(rad);
		end.rotateByRadians(rad);
		setInterval();
		return this;
	}

	/**
		Rotates this segment by given angle (in degrees)
		@param deg angle in degrees
		@param origin 
	**/
	public inline function rotateByDegrees(deg:Float, ?origin:FlxPoint) {
		return rotate(deg * Math.PI / 180.0);
	}

	/**
		Returns intersection point with rect treating
		the rect as 4 different line segments.
		Immideately returns if such point is found.
		@param rect 
		@return Null<FlxPoint>
	**/
	public function intersectionPointWithRectSegments(rect:FlxRect):Null<FlxPoint> {
		var top = new LineSegment(rect.left, rect.top, rect.right, rect.top);
		var result:FlxPoint = null;

		if ((result = this.intersectionPoint(top)) != null) {
			top.destroy();
			return result;
		}

		var right = top.set(rect.right, rect.top, rect.right, rect.bottom);
		if ((result = this.intersectionPoint(right)) != null) {
			right.destroy();
			return result;
		}

		var bottom = right.set(rect.right, rect.bottom, rect.left, rect.bottom);
		if ((result = this.intersectionPoint(bottom)) != null) {
			bottom.destroy();
			return result;
		}

		var left = bottom.set(rect.left, rect.bottom, rect.left, rect.top);
		if ((result = this.intersectionPoint(left)) != null) {
			left.destroy();
			return result;
		}

		left.destroy();

		return null;
	}

	public function leftNormal(?p:FlxPoint):FlxPoint {
		p = p ?? FlxPoint.get(0, 0);
		return end.clone(p).subtractPoint(start).leftNormal(p);
	}

	/**
		Returns an intersection point with given rect.
		The closest (to the segment start) point will return.
		@param rect 
		@param normal vector to store normal of the intersected edge
		@return IntersectionPoint
	**/
	public function intersectionPointWithRect(rect:FlxRect, ?normal:FlxPoint):Null<IntersectionPoint> {
		// reset global normal storage
		LineSegment.ilNormal.set(0, 0);
		var points = [];
		var normals = [];
		var needNormal = normal != null;
		var result:FlxPoint = null;

		var top = new LineSegment(rect.left, rect.top, rect.right, rect.top);
		if ((result = this.intersectionPoint(top)) != null) {
			points.push(result);
			needNormal ? normals.push(top.leftNormal()) : 0;
		}

		var right = top.set(rect.right, rect.top, rect.right, rect.bottom);
		if ((result = this.intersectionPoint(right)) != null) {
			points.push(result);
			needNormal ? normals.push(right.leftNormal()) : 0;
		}

		var bottom = right.set(rect.right, rect.bottom, rect.left, rect.bottom);
		if ((result = this.intersectionPoint(bottom)) != null) {
			points.push(result);
			needNormal ? normals.push(bottom.leftNormal()) : 0;
		}

		var left = bottom.set(rect.left, rect.bottom, rect.left, rect.top);
		if ((result = this.intersectionPoint(left)) != null) {
			points.push(result);
			needNormal ? normals.push(left.leftNormal()) : 0;
		}

		left.destroy();
		if (points.length == 0)
			return null;

		var r = 1.0;
		var pointInd = 1;
		result = points[0];
		for (i in 0...points.length) {
			var point = points[i];
			// finding ratio of current point on the line segment
			// NOTE: in case of horizontal|vertical lines
			// I have to opt out division by zero (comes from invLerp)
			var pr = point.x == end.x ? invLerp(start.y, end.y, point.y) : invLerp(start.x, end.x, point.x);
			if (pr < r) {
				pointInd = i;
				result = point;
				r = pr;
			}
		}

		result = result.clone();
		if (needNormal) {
			normal.copyFrom(normals[pointInd]);
			ilNormal.copyFrom(normal);
		}

		for (point in points) {
			point.put();
		}

		for (n in normals) {
			n.put();
		}

		return result;
	}

	public function toString() {
		return '${start.toString()} - ${end.toString()}';
	}

	public function destroy() {
		start.put();
		end.put();
		xInterval.put();
		yInterval.put();
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

/**
	To visualize that everything works.
	This thing helped to see that there were bugs
	so they are fixed.
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
		if (ip != null) {
			// gfx.lineStyle(1, 0xFF0000);
			gfx.endFill();
			gfx.lineStyle(null);
			gfx.beginFill(0x00FF6A);
			gfx.drawCircle(ip.x, ip.y, 5);
			gfx.endFill();
			ip.put();
		}
	}
}
