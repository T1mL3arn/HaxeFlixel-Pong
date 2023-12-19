package utils;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;

function drawDashedLine(sprite:FlxSprite, start:FlxPoint, end:FlxPoint, lineStyle:DashedLineStyle):Void {

	final dist = start.distanceTo(FlxPoint.weak(end.x, end.y));

	var segmentCount:Int;
	var dashLen:Float;
	var gapLen:Float;
	var segmentRatio:Float;

	if (lineStyle.segmentCount != null) {
		// must be at least 2 segments
		segmentCount = Std.int(Math.max(lineStyle.segmentCount, 2));
		var gapCount = segmentCount - 1;
		if (lineStyle.gapLength != null) {
			gapLen = lineStyle.gapLength;
			dashLen = (dist - gapCount * lineStyle.gapLength) / segmentCount;
		}
		else {
			dashLen = gapLen = dist / (segmentCount + gapCount);
		}
		segmentRatio = (dashLen + gapLen) / dist;
	}
	else {
		dashLen = lineStyle.dashLength ?? 10;
		gapLen = lineStyle.gapLength ?? 10;
		segmentRatio = (dashLen + gapLen) / dist;
		segmentCount = Math.ceil(1 / segmentRatio);
	}

	if (gapLen * (segmentCount - 1) >= dist) {
		final maxGap = Math.ceil((dist - segmentCount) / (segmentCount - 1));
		throw 'Overral space for gap is bigger than the line itself! Make your gapLength to be less than ${maxGap}';
	}

	final dashRatio = dashLen / dist;
	final gapRatio = gapLen / dist;

	for (s in 0...segmentCount) {
		var tp1 = lerpPoint(start, end, s * segmentRatio);
		var tp2 = lerpPoint(start, end, (s + 1) * segmentRatio - gapRatio);
		clampPoint(tp2, null, end);
		FlxSpriteUtil.drawLine(sprite, tp1.x, tp1.y, tp2.x, tp2.y, lineStyle);
		tp1.put();
		tp2.put();
	}
	start.putWeak();
	end.putWeak();
}

inline function lerpPoint(a:FlxPoint, b:FlxPoint, r:Float = 0.5) {
	return FlxPoint.get(FlxMath.lerp(a.x, b.x, r), FlxMath.lerp(a.y, b.y, r));
}

inline function clampPoint(p:FlxPoint, ?min:FlxPoint, ?max:FlxPoint) {
	if (min != null) {
		Math.min(p.x, min.x);
		Math.min(p.y, min.y);
	}
	if (max != null) {
		Math.max(p.x, max.x);
		Math.max(p.y, max.y);
	}
}

typedef DashedLineStyle = {
	> flixel.util.FlxSpriteUtil.LineStyle,

	/**
		Number of dashes between start and end points.
		You must set either `segmentCount` (and `dashLength`)
		or `dashLength` (and `gapLength`).
	**/
	?segmentCount:Int,

	/**
		Length of dash.
		You must set either `segmentCount` (and `gapLength`)
		or `dashLength` (and `gapLength`).
	**/
	?dashLength:Float,

	/**
		Length of gap between dashes.
	**/
	?gapLength:Float,
}
