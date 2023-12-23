package utils;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.input.mouse.FlxMouse;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxPoint;

class FlxDragManager extends FlxBasic {

	var isDragging:Bool = false;
	var offset:FlxPoint;
	var objects:Array<FlxObject>;
	var current:FlxObject;

	public function new() {
		super();
		objects = [];
		offset = FlxPoint.get();
	}

	public function add<T:FlxObject>(object:T) {
		if (object == null)
			return;

		if (objects.indexOf(object) == -1)
			objects.push(object);

		FlxMouseEvent.add(object, startDrag, stopDrag, null, null, false);
	}

	public function remove<T:FlxObject>(object:T) {
		if (object == null)
			return;
		objects.remove(object);
		FlxMouseEvent.remove(object);
	}

	public function removeAll() {
		stopDrag();
		for (obj in objects) {
			FlxMouseEvent.remove(obj);
		}
		objects = [];
	}

	override public function destroy() {
		super.destroy();
		removeAll();
		objects = null;
		offset.put();
	}

	public function startDrag(obj:FlxObject) {
		if (isDragging)
			stopDrag(current);

		offset.x = FlxG.mouse.screenX + obj.scrollFactor.x * (FlxG.mouse.x - FlxG.mouse.screenX) - obj.x;
		offset.y = FlxG.mouse.screenY + obj.scrollFactor.y * (FlxG.mouse.y - FlxG.mouse.screenY) - obj.y;
		current = obj;
		isDragging = true;
	}

	function stopDrag(?obj:FlxObject) {
		if (current != null) {
			offset.x = FlxG.mouse.screenX + obj.scrollFactor.x * (FlxG.mouse.x - FlxG.mouse.screenX) - obj.x;
			offset.y = FlxG.mouse.screenY + obj.scrollFactor.y * (FlxG.mouse.y - FlxG.mouse.screenY) - obj.y;
		}
		offset.set(0, 0);
		current = null;
		isDragging = false;
	}

	override function update(dt:Float) {

		if (FlxG.mouse.justReleased) {
			stopDrag(current);
		}

		if (isDragging) {
			current.x = FlxG.mouse.screenX + current.scrollFactor.x * (FlxG.mouse.x - FlxG.mouse.screenX) - offset.x;
			current.y = FlxG.mouse.screenY + current.scrollFactor.y * (FlxG.mouse.y - FlxG.mouse.screenY) - offset.y;
		}
	}
}
