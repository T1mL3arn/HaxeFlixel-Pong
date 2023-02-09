package;

import flixel.FlxSprite;

function setSpritePosition(sprite:FlxSprite, ?x:Float, ?y:Float) {
	if (x != null)
		sprite.x = x - sprite.origin.x;
	if (y != null)
		sprite.y = y - sprite.origin.y;

	return sprite;
}
