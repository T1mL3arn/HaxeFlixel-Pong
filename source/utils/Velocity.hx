package utils;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import math.MathUtils.point;
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

	/**
		Moves an object to a target point with given speed.
		Movement stops after a time needed to reach the target.
		NOTE: Method does not guarantee that target point will be reached.
		@param object 
		@param target 
		@param speed 
	**/
	public function moveObjectTo(object:FlxSprite, target:FlxPoint, speed:Float) {
		timer.cancel();

		lastObj = object;
		// don't move obj if target point is the same
		// as current position
		if (target.equals(wp(object.x, object.y)))
			return;

		var angle = FlxAngle.angleFromOrigin(target.x - object.x, target.y - object.y);
		object.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);

		var path = target.distanceTo(wp(object.x, object.y));
		var time = path / speed;
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

	var target = point(0, 0);

	/**
		Moves an object to a target point with given speed.
		Movement stops when the object is reached(or overreached) the target.
		@param object 
		@param target 
		@param speed 
	**/
	public function moveUntilReached(object:FlxSprite, target:FlxPoint, speed:Float) {
		timer.cancel();

		lastObj = object;
		// don't move obj if target point is the same
		// as current position
		if (target.equals(wp(object.x, object.y)))
			return;

		var angle = FlxAngle.angleFromOrigin(target.x - object.x, target.y - object.y);
		object.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);

		this.target.copyFrom(target);
		target.putWeak();

		timer.start(1 / (Flixel.updateFramerate + 1), checkObjectReachedTarget, 0);
	}

	function checkObjectReachedTarget(t) {
		// check if obj velocity and (TARGET - OBJECT) is (kinda) colinear.
		// if they arent - we overreached, stop movement
		var diff = point().copyFrom(this.target).subtract(lastObj.x, lastObj.y);
		var dot = lastObj.velocity.dot(wp(diff));
		// trace('dot: $dot');
		if (dot < 0) {
			t.cancel();
			stopMovement();
		}
	}
}
