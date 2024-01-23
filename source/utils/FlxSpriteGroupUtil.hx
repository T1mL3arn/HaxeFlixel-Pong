package utils;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;

function getGroupBounds(group:FlxSpriteGroup):FlxRect {
	var x = group.findMinX();
	var y = group.findMinY();
	var w = group.findMaxX() - x;
	var h = group.findMaxY() - y;
	return FlxRect.get(x, y, w, h);
}

/**
	All of a suddent HL doesn't work again, so I had to recreate `setPosition`
	with proper typed way and just do direct transformation instead of
	magick with typing and generics. Fuck you HL!
	@param group 
	@param x 
	@param y 
	@return T
**/
@:access(flixel.group.FlxTypedSpriteGroup)
function setPosition<T:FlxSpriteGroup>(group:T, x:Float, y:Float):T {
	// fuck you hashlink
	// Transform children by the movement delta
	var dx:Float = x - group.x;
	var dy:Float = y - group.y;
	// group.multiTransformChildren([xTransform, yTransform], [dx, dy]);

	if (group._skipTransformChildren || group.group == null)
		return group;

	for (sprite in group._sprites) {
		if ((sprite != null) && sprite.exists) {
			sprite.x += dx;
			sprite.y += dy;
		}
	}

	// don't transform children twice
	group._skipTransformChildren = true;
	group.x = x; // this calls set_x
	group.y = y; // this calls set_y
	group._skipTransformChildren = false;
	return group;
}
