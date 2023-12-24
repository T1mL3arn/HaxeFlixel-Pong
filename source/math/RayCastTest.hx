package math;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import utils.FlxDragManager;

class RayCastTest extends FlxState {

	var start:FlxSprite;
	var end:FlxSprite;
	var rayCast = new RayCast();
	var drag:FlxDragManager;
	var model:Array<FlxRect> = [];
	var startPoint = new FlxPoint();
	var endPoint = new FlxPoint();

	public function new() {
		super();
	}

	override function create() {
		super.create();

		bgColor = 0xFF222222;

		start = new FlxSprite(0, 0);
		start.makeGraphic(8, 8, FlxColor.WHITE);
		start.updateHitbox();
		start.centerOffsets();
		start.setPosition(100, 100);
		add(start);

		end = new FlxSprite(0, 0);
		end.makeGraphic(10, 10, 0xFFFFBF0E);
		end.updateHitbox();
		end.centerOffsets();
		end.setPosition(400, 300);
		add(end);

		updatePositions();

		drag = Flixel.plugins.get(FlxDragManager) ?? new FlxDragManager();
		Flixel.plugins.add(drag);
		drag.onDragStop = cast doCast;

		drag.add(start);
		drag.add(end);

		rayCast.model = buildModel();
		doCast();
	}

	function buildModel() {
		var model = [];
		var box = new FlxObject(0, 0, 150, 150);
		box.screenCenter();

		model.push(box.getHitbox());
		model.push(new FlxObject(10, 20, 20, 400).getHitbox());
		model.push(new FlxObject(450, 0, 20, 400).getHitbox());
		model.push(new FlxObject(50, 440, 400, 15).getHitbox());

		return model;
	}

	function doCast(?_) {
		updatePositions();
		var dir = endPoint.subtractNew(startPoint).scale(3);
		rayCast.castRay(startPoint, dir, 7, 500);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	function updatePositions() {
		var s = start.width * 0.5;
		startPoint.set(start.x + s, start.y + s);
		s = end.width * 0.5;
		endPoint.set(end.x + s, end.y + s);
	}

	override function draw() {
		super.draw();

		// lst.update(Flixel.elapsed);

		updatePositions();

		if (Flixel.mouse.justMoved && Flixel.mouse.pressed) {
			// updatePositions();
			// doCast();
		}

		var gfx = Flixel.camera.debugLayer.graphics;
		rayCast.draw(gfx);

		// draw ours start-end segment
		gfx.lineStyle(2, 0xFFFFFF);
		gfx.moveTo(startPoint.x, startPoint.y);
		gfx.lineTo(endPoint.x, endPoint.y);
		gfx.endFill();

		rayCast.drawRays(gfx);
	}
}
