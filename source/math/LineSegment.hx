package math;

import Utils.invLerp;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import utils.FlxSpriteDraw.lerpPoint;
import math.MathUtils.point;

/**
	Represents interval like [min, max]
**/
@:forward(put)
abstract Interval(FlxPoint) from FlxPoint to FlxPoint {

	/**
		Set interval from given values `a` and `b`.
		This `Interval` will find what is `min` and 
		what is `max` value.
		@param a 
		@param b 
		@return this `Interval` instance
	**/
	public inline function set(a:Float, b:Float):Interval {
		this.x = Math.min(a, b);
		this.y = Math.max(a, b);
		return this;
	}

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

	/**
		Start coord of this segment. 

		NEVER write this directly, use `set()` or `setPoints()`
	**/
	public var start(default, null):FlxPoint;

	/**
		End coord of this segment. 

		NEVER write this directly, use `set()` or `setPoints()`
	**/
	public var end(default, null):FlxPoint;

	/**
		Left normal of last rect edge intersection.
	**/
	static private var ilNormal(default, null):FlxPoint = new FlxPoint();

	var xInterval:Interval;
	var yInterval:Interval;

	public function new(sx = 0.0, sy = 0.0, ex = 1.0, ey = 1.0) {
		if (ilNormal == null)
			ilNormal = new FlxPoint();

		start = point(sx, sy);
		end = point(ex, ey);

		xInterval = point();
		yInterval = point();
		invalidateInterval();
	}

	public function set(sx, sy, ex, ey) {
		start.set(sx, sy);
		end.set(ex, ey);
		invalidateInterval();
		return this;
	}

	public inline function setPoints(start:FlxPoint, end:FlxPoint):LineSegment {
		set(start.x, start.y, end.x, end.y);
		start.putWeak();
		end.putWeak();
		return this;
	}

	function invalidateInterval() {
		xInterval.set(start.x, end.x);
		yInterval.set(start.y, end.y);
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
		var intersection = point(px, py);

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
		invalidateInterval();
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
		invalidateInterval();
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
		p = p ?? point(0, 0);
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
		var pointInd = 0;
		result = points[0];
		for (i in 0...points.length) {
			var point = points[i];
			var ratio = ratioOf(point);
			if (ratio < r) {
				pointInd = i;
				result = point;
				r = ratio;
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

	/**
		Finds ratio of given point on the line segment,
		assuming the given point actually lies on the line.
		@param p 
	**/
	public function ratioOf(p:FlxPoint) {
		// NOTE: in case of horizontal|vertical lines
		// I have to opt out division by zero (comes from invLerp)
		return p.x == end.x ? invLerp(start.y, end.y, p.y) : invLerp(start.x, end.x, p.x);
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
}
