package ai;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import math.MathUtils.p;
import math.MathUtils.point;
import math.MathUtils.wp;
import utils.Velocity;

/**
	Simple AI does not mean dumb AI. 
	Simple means:
		- Get ball center Y.
		- Try to match racket center Y coord with it.
	NOTE: This AI is not good when a ball comes at sharp adges.
**/
class SimpleAI extends BaseAI {

	public var timeToThink:Float = 0.15;

	/**
		Value in range [0, 1] where 0.5 is the center of racket's hitzone,
		0 and 1 are top/bottom of the hitzone.
	**/
	public var positionVariance:Float = 0.5;

	var timer:Float;

	/**
		Used instead of tween objects to "tween" racket
		to its target position.
	**/
	var moveTimer:FlxTimer;

	var previousShift:Int = 0;
	var velocityContoller:Velocity;

	public function new(racket, name) {
		super(racket, name ?? 'BaseAIv2');

		moveTimer = new FlxTimer(new FlxTimerManager());
		target = point();

		velocityContoller = new Velocity();
		velocityContoller.timer = moveTimer;
	}

	override function onBallCollision(obj:FlxObject, ball:Ball) {

		var isServe = obj == null;

		previousShift = 0;

		if (isServe) {
			positionVariance = 0.5;
		}
		else if (!isServe) {
			updateVariance();
		}
		calcTargetPosition();
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
					positionVariance = Flixel.random.float(3 / 7, 1);
				case 2:
					positionVariance = Flixel.random.float(1 / 7, 6 / 7);
				case 3:
					// variance to hit mostly by racket's bottom
					positionVariance = Flixel.random.float(0, 4 / 7);
			}
			previousShift = newShift;
			// Flixel.watch.addQuick('$name var:', '${FlxMath.roundDecimal(positionVariance, 2)}');
		}

		b.put();
	}

	override function update(dt:Float) {

		// check if it is time to recalc racket position
		if (timer >= timeToThink) {
			timer = 0;
		}

		if (timer == 0) {
			calcTargetPosition();
		}

		timer += dt;
		moveTimer.manager.update(dt);
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
				var b = projectBallPos(timeToThink * 1.15);

				var moveBounds = racket.movementBounds;
				// take new projected value as initial value for calculation
				var top = Math.max(b.y + 1 - racket.height, moveBounds.top);
				var bottom = Math.min(b.y + ball.height - 1, moveBounds.bottom - racket.height);

				top = FlxMath.bound(b.y + 1 - racket.height, moveBounds.top, moveBounds.bottom - racket.height);
				bottom = FlxMath.bound(b.y + ball.height - 1, moveBounds.top, moveBounds.bottom - racket.height);

				target.x = racket.x;
				target.y = FlxMath.lerp(top, bottom, positionVariance);
				topz = top;
				btmz = bottom;
				bx = b.x;
				by = b.y;

				if (active) {
					velocityContoller.moveObjectTo(racket, target, Pong.params.racketSpeed);
				}

				// Flixel.watch.addQuick('$name ty:', '${FlxMath.roundDecimal(target.y, 2)}');

				b.put();
			case _:
				0;
		}
	}

	function stopRacket(_) {
		racket.velocity.set(0, 0);
	}

	override function set_active(v:Bool):Bool {
		moveTimer.manager.active = v;
		moveTimer.cancel();
		if (moveTimer.onComplete != null)
			moveTimer.onComplete(moveTimer);
		return super.set_active(v);
	}

	#if debug
	var topz = 0.0;
	var btmz = 0.0;
	var bx = 0.0;
	var by = 0.0;

	override function drawDebug() {
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
	}
	#end
}
