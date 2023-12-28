package ai;

import flixel.FlxObject;
import flixel.math.FlxMath;
// import flixel.math.FlxPoint.get as p;
// import flixel.math.FlxPoint.get as point;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxTimer;
import math.MathUtils.p;
import math.MathUtils.point;
import math.MathUtils.wp;

class BaseAI extends RacketController {

	public var name:String;

	/**
		Target coord for the racket.
	**/
	public var target(default, null):FlxPoint;

	var tween:VarTween;

	public function new(racket:Racket, ?name:String) {
		super(racket);
		this.name = name ?? 'base AI';
		GAME.aiTweens.active = true;
		GAME.signals.ballCollision.add(onBallEvent);
		GAME.signals.ballServed.add(onBallServe);
	}

	override function destroy() {
		super.destroy();

		GAME.signals.ballCollision.remove(onBallEvent);
		GAME.signals.ballServed.remove(onBallServe);
	}

	override function update(dt:Float) {}

	@:noCompletion
	function onBallServe() {
		onBallEvent(null, GAME.room.ball);
	}

	/**
		Called when ball is served or colide with something
		@param obj 
		@param ball 
	**/
	function onBallEvent(obj:FlxObject, ball:Ball) {}
}

class BaseAI2 extends BaseAI {

	public var timeToThink:Float = 0.15;

	/**
		Value in range [0, 1] where 0.5 is the center of racket's hitzone,
		0 and 1 are top/bottom of the hitzone.
	**/
	public var positionVariance:Float = 0.5;

	var timer:Float;
	var moveDuration:Float = 0.0;
	var moveDurationTime:Float = 0;

	/**
		Used instead of tween objects to "tween" racket
		to its target position.
	**/
	var moveTimer:FlxTimer;

	var previousShift:Int = 0;

	public function new(racket, name) {
		super(racket, name ?? 'BaseAIv2');

		moveTimer = new FlxTimer();
		target = point();
	}

	override function onBallEvent(obj:FlxObject, ball:Ball) {

		var isServe = obj == null;

		previousShift = 0;
		updateVariance();

		if (isServe) {
			positionVariance = 0.5;
		}
		else if (!isServe) {
			// updateVariance();
		}
		calcTargetPosition();
		trace('$name: new target');
	}

	function updateVariance() {
		var ball = GAME.room.ball;
		var b = projectBallPos(timeToThink * 1.15);
		var newShift = previousShift;
		if (b.y + ball.height < racket.y || b.y > racket.movementBounds.bottom - racket.height * .5) {
			newShift = 1;
		}
		else if (b.y > racket.y + racket.height || b.y < racket.movementBounds.top + racket.height * .5) {
			newShift = 3;
		}
		else {
			newShift = 2;
		}

		// udpate variance but only there was change in shift
		if (newShift != previousShift) {
			switch (newShift) {
				case 1:
					// variance to hit mostly by racket's top
					positionVariance = Flixel.random.float(4 / 7, 1);
				case 2:
					positionVariance = Flixel.random.float(1 / 7, 6 / 7);
				case 3:
					// variance to hit mostly by racket's bottom
					positionVariance = Flixel.random.float(0, 3 / 7);
			}
			trace('$name: NEW variance: ${FlxMath.roundDecimal(positionVariance, 2)}\n');
			Flixel.watch.addQuick('$name var:', '${FlxMath.roundDecimal(positionVariance, 2)}');
			previousShift = newShift;
		}

		b.put();
	}

	override function update(dt:Float) {

		moveDurationTime += dt;

		// check if it is time to recalc racket position
		if (timer >= timeToThink) {
			timer = 0;
		}

		if (timer == 0) {
			calcTargetPosition();
			// update variance according to ball's shift from hitzone
			updateVariance();
		}

		// if (moveDurationTime >= moveDuration) {
		// 	moveDurationTime = 0;
		// 	moveDuration = 0;
		// 	racket.velocity.set(0, 0);
		// }

		timer += dt;
	}

	function projectBallPos(time:Float) {
		var ball = GAME.room.ball;
		// project ball pos
		var b:FlxPoint = p(ball.x, ball.y).addPoint(wp(ball.velocity * time));
		if (!b.inCoords(0, 0, FLixel.width, Flixel.height)) {
			b.set(ball.x, ball.y).addPoint(wp(ball.velocity * timeToThink));
		}
		// clamp that value to be in world's bounds
		b.x = FlxMath.bound(b.x, 0, Flixel.width);
		b.y = FlxMath.bound(b.y, 0, Flixel.height);
		return b;
	}

	function calcTargetPosition() {

		var ball = GAME.room.ball;
		switch (racket.position) {
			case LEFT, RIGHT:
				// var targetCenterY = ball.y + ball.height * 0.5;
				// var targetRacketY = targetCenterY - racket.height / 2;

				// var b = projectBallPos(Math.max(timeToThink * 2, 0.175));
				var b = projectBallPos(timeToThink * 1.15);

				var moveBounds = racket.movementBounds;
				// take new projected value as initial value for calculation
				var top = Math.max(b.y + 1 - racket.height, moveBounds.top);
				var bottom = Math.min(b.y + ball.height - 1, moveBounds.bottom - racket.height);

				top = FlxMath.bound(b.y + 1 - racket.height, moveBounds.top, moveBounds.bottom - racket.height);
				bottom = FlxMath.bound(b.y + ball.height - 1, moveBounds.top, moveBounds.bottom - racket.height);

				target.y = FlxMath.lerp(top, bottom, positionVariance);
				topz = top;
				btmz = bottom;
				bx = b.x;
				by = b.y;
				// target.y = FlxMath.bound(target.y, moveBounds.top, moveBounds.bottom - racket.height);

				var path = Math.abs(target.y - racket.y);
				var duration = path / Pong.params.racketSpeed;
				moveDuration = duration;

				racket.velocity.set(0, Pong.params.racketSpeed);
				racket.y > target.y ? racket.velocity.y *= -1 : 0;
				moveTimer.cancel();
				moveTimer.start(duration, stopRacket);

				// tween?.cancel();
				// tween = GAME.aiTweens.tween(racket, {y: target.y}, duration, {ease: FlxEase.linear});

				Flixel.watch.addQuick('$name ty:', '${FlxMath.roundDecimal(target.y, 2)}');

				b.put();
			case _:
				0;
		}
	}

	function stopRacket(_) {
		racket.velocity.set(0, 0);
		// racket.y = target.y;
		// calcTargetPosition();
	}

	var topz = 0.0;
	var btmz = 0.0;
	var bx = 0.0;
	var by = 0.0;

	override function draw() {
		super.draw();

		#if debug
		var ball = GAME.room.ball;
		var gfx = Flixel.camera.debugLayer.graphics;

		gfx.lineStyle(1.5, 0x8DDBFF, 0.75);
		gfx.moveTo(racket.x - 20, topz);
		gfx.lineTo(racket.x + 20, topz);
		gfx.lineStyle(1.5, 0x68F88C, 0.75);
		gfx.moveTo(racket.x - 20, btmz);
		gfx.lineTo(racket.x + 20, btmz);
		gfx.lineStyle(1.5, 0xFD7BDD, 0.75);
		gfx.moveTo(racket.x - 20, target.y);
		gfx.lineTo(racket.x + 20, target.y);
		gfx.lineStyle(1, 0xFF0000, 0.5);
		gfx.drawRect(bx, by, ball.width, ball.height);
		gfx.endFill();
		#end
	}
}
