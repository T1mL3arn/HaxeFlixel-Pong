package utils;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import math.MathUtils.round;
import math.MathUtils.wp;

class Velocity {

	public var timer:FlxTimer;

	var lastObj:FlxObject;

	public function new() {
		//
		// replacing trace (for tests)
		// var oldTrace = haxe.Log.trace;
		// haxe.Log.trace = function(v, ?infos) {
		// 	// handle trace
		// 	if (infos != null) {
		// 		infos.fileName = '';
		// 		infos.lineNumber = 1;
		// 	}
		// 	oldTrace(v, infos);
		// }

		timer = new FlxTimer();
	}

	public function moveObjectTo(object:FlxSprite, target:FlxPoint, speed:Float) {
		//
		lastObj = object;
		// don't move obj if target point is the same
		// as current position
		if (target.equals(wp(object.x, object.y)))
			return;

		var path = target.distanceTo(wp(object.x, object.y));
		var time = path / speed;
		var angle = FlxAngle.angleFromOrigin(target.x - object.x, target.y - object.y);
		object.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
		timer.cancel();
		timer.start(time, stopMovement_internal);
		target.putWeak();
		// trace('move to: ${target} for ${round(time)} secs; vel: ${object.velocity}; path: ${round(path)} ');
	}

	function stopMovement_internal(?_) {
		lastObj.velocity.set(0, 0);
		// trace('movement stopped');
	}

	public function stopMovement() {
		stopMovement_internal();
	}
}
