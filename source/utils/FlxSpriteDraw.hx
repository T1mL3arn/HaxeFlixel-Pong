package utils;

import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;

typedef DashedLineStyle = {
	> flixel.util.FlxSpriteUtil.LineStyle,

	/**
		Number of dashes between start and end points.
		You must set either `segmentCount` (and `dashLength`)
		or `dashLength` (and `gapLength`).
	**/
	@:optional var segmentCount:Int;

	/**
		Length of dash.
		You must set either `segmentCount` (and `gapLength`)
		or `dashLength` (and `gapLength`).
	**/
	@:optional var dashLength:Float;

	/**
		Length of gap between dashes.
	**/
	@:optional var gapLength:Float;
}

/**
	Draw a dashed line on a sprite. 

	**NOTE**: function respects flixel's weak points convention!

	**Example**:
	```haxe
	drawDashedLine(sprite, FlxPoint.weak(0,0),  FlxPoint.weak(100,100), {
		thickness: 10,
		// there will be exactly 10 dashes and (9 gaps)
		segmentCount: 10,
		// all gaps will be 5px (dash length is calculated) 
		gapLength: 5,
	});
	// or
	drawDashedLine(sprite, FlxPoint.weak(0,0),  FlxPoint.weak(100,100), {
		thickness: 10,
		// dash length will be exactly 15px
		dashLength: 15,
		// gap length will be exactly 10px
		gapLength: 10,
	});
	```

	@param sprite target sprite
	@param start start point of the line
	@param end end point of the line
	@param lineStyle line options like thickness, dash counts etc, see `utils.DashedLineStyle`
**/
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

/**
	Twinkle a sprite with given color.
	It is a shorthand for setting `FlxFlicker` to do the same.
	@param sprite object to twinkle
	@param color target color
	@param duration how long effect lasts, in seconds
	@param interval how long before changing the color, in seconds
	@return `FlxFlicker` object
**/
function twinkle(sprite:FlxSprite, color:Int, duration:Float, interval:Float):FlxFlicker {
	final initialColor = sprite.color;
	return FlxFlicker.flicker(sprite, duration, interval, true, true, _ -> {
		sprite.color = initialColor;
	}, f -> {
		sprite.visible = true;
		sprite.color = f.timer.loopsLeft % 2 == 0 ? color : initialColor;
	});
}
