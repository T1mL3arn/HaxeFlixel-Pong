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
