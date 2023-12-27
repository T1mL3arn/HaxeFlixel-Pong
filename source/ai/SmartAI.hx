package ai;

import flixel.FlxObject;
import flixel.math.FlxPoint.get as point;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import math.MathUtils.wp;
import math.RayCast;

typedef SmartAIParams = {

	/**
		Angle variance in degrees
	**/
	angleVariance:Float,

	/** Min part of `angleVariance` to use **/
	angleVarianceMinFactor:Float,

	bouncePlaceBias:Array<Float>,

	// bias for ball serve to be sure that AI never misses the first ball
	bouncePlaceBiasSafe:Array<Float>,

	returnToMiddleChance:Float,
	chanceForRealTrajectory:Float,
};

/**
	This AI calculates ball trajectory to find the best
	spot to bounce the ball. Potentially can be made to never
	miss the ball.

	- listens ball_serve and ball_collision
	- on these signals calcs possible ball trajectory
	- if trajectory is towards this AI - find the best spot to hit the ball
**/
class SmartAI extends SimpleAI {

	public static function buildHardAI(racket, name) {
		return new SmartAI(racket, name);
	}

	public static function buildHardestAI(racket, name) {
		var ai = new SmartAI(racket, name);
		ai.SETTINGS.angleVariance = 0.35;
		ai.SETTINGS.angleVarianceMinFactor = 0.1;
		ai.SETTINGS.bouncePlaceBias = [5, 10, 7, 0.25, 7, 10, 5];
		// bias below to test how AI behaves trying to hit
		// ball with only racket corners
		// ai.SETTINGS.bouncePlaceBias = [1, 0, 0, 0, 0, 0, 1];
		ai.SETTINGS.bouncePlaceBiasSafe = [0, 1, 0, 0, 0, 1, 0];
		ai.SETTINGS.returnToMiddleChance = 0.75;
		ai.SETTINGS.chanceForRealTrajectory = 0.4;
		return ai;
	}

	public var drawTrajectory:Bool = false;

	var target:FlxPoint;
	var model:Array<FlxRect>;

	// some resonable defaults
	var SETTINGS:SmartAIParams = {
		angleVariance: 0.6,
		angleVarianceMinFactor: 0.2,
		bouncePlaceBias: [5, 8, 7, 1, 7, 8, 5],
		bouncePlaceBiasSafe: [0, 2, 3, 0, 3, 1, 0],
		returnToMiddleChance: 0.25,
		chanceForRealTrajectory: 0.1,
	};

	public function new(racket, name) {
		super(racket, name);

		// how does this AI work?

		GAME.signals.ballCollision.add(calcTrajectory);
		GAME.signals.ballServed.add(onBallServed);
		GAME.signals.substateOpened.addOnce((_, _) -> buildRoomModel());

		rayCast = new RayCast();
		rayCast2 = new RayCast();

		// Flixel.random.color()
		var hue = Flixel.random.float(30, 360);
		var tjColor = FlxColor.fromHSB(hue, 1, 1);
		var tjRealColor = FlxColor.WHITE;

		rayCast.trajectoryColor = tjColor;
		rayCast2.trajectoryColor = tjRealColor;
		target = point();
	}

	var rayCast:RayCast;
	var rayCast2:RayCast;

	/** This AI's goal area **/
	var thisGoal:FlxRect;

	override function destroy() {
		super.destroy();

		GAME.signals.ballCollision.remove(calcTrajectory);
		GAME.signals.ballServed.remove(onBallServed);

		rayCast.destroy();
		rayCast2.destroy();

		for (rect in model) {
			if (@:privateAccess !rect._inPool)
				rect.put();
		}
		model = null;

		target.put();
	}

	function onBallServed() {
		calcTrajectory(null, GAME.room.ball);
	}

	function buildRoomModel() {

		// dont build the model more than once
		if (model != null)
			return;

		model = [];

		final bhw = GAME.room.ball.width * 0.5;

		// - use ball's center of mass to calc its trajectory and collisions
		// - this means I have to ~adjust~ wall sizes for room model,
		// 		wall must be bigger on half_ball from every side

		for (w in GAME.room.walls.members) {
			var box = w.getHitbox();
			if (w is Racket) {
				// wall model from racket get scaled to fill
				// the entire screen height
				box.top = 0;
				box.bottom = Flixel.height;

				if (w == this.racket)
					thisGoal = box;
			}

			box.left -= bhw;
			box.top -= bhw;
			box.right += bhw;
			box.bottom += bhw;

			model.push(box);
		}

		rayCast.model = rayCast2.model = model;
	}

	function calcTrajectory(object:FlxObject, ball:Ball) {

		if (object == racket) {
			// ball is bounced by this ai, lets return to the middle (sometime)
			if (Math.random() <= SETTINGS.returnToMiddleChance) {
				target.y = Flixel.height * 0.5 - racket.height * 0.5;
				moveRacketTo(target);
				// trace('$name: return to middle');
			}

			return;
		}

		final ballServe = object == null;
		// trajectory is calculated only when:
		// - ball is served
		// - when ball is hit by other racket
		if (!(ballServe || (object is Racket && object != racket)))
			return;

		var ballPos = ball.getWorldPos();
		var ray1 = ball.velocity.clone(wp());
		// max trajectory length is a diagonal of screen
		ray1.length = Math.sqrt(Math.pow(Flixel.width, 2) + Math.pow(Flixel.height, 2));
		var ray2 = ray1.clone(wp());

		var a = 0.0;

		if (Math.random() >= SETTINGS.chanceForRealTrajectory) {
			a = SETTINGS.angleVariance;
			a = Flixel.random.float(a * SETTINGS.angleVarianceMinFactor, a);
			a *= Flixel.random.sign();
		}

		// real trajectory (for debug purpose)
		rayCast2.castRay(ballPos, ray2, 3, 0, thisGoal);

		var tj = rayCast.castRay(ballPos, ray1.rotateByDegrees(a), 3, 0, thisGoal);
		target = tj[tj.length - 1].copyTo(target);

		target = calcRacketDestination(ball, target, ballServe);
		moveRacketTo(target);

		ballPos.put();
	}

	var bouncePlace = [-3, -2, -1, 0, 1, 2, 3].map(x -> x + 3);

	function calcRacketDestination(ball:Ball, ballPos:FlxPoint, isServe:Bool):FlxPoint {
		// var bhs = ball.width * 0.5;
		// var ballBounds = ball.getHitbox(tmprect1);
		// var racketBounds = racket.getHitbox(tmprect2);

		switch (racket.position) {
			case LEFT, RIGHT:
				var target = ballPos;

				// in model the target point represents ball's center,
				// here I convert modeled Y back to ball's real Y
				target.y -= ball.height * 0.5;

				/**
					By, Bh - ball Y and Height
					Ry, Rh - racket Y and Height
					Racket can hit the ball in segment of (By + Bh, By - Rh) => hit-zone (HZ)
					but ONLY when Ry0 = By + Bh.
					So I can chose any value from HZ and
					So target Ry must be:
					Ry = Ry0 + rnd(0, HZ)
					(HZ can be simplified to Rh + Bh)
				**/

				// TODO store and read this from racket?
				final segmentCount = 7;
				var HZ = racket.height + ball.height - 2; // -2 to be sure the ball will be hit
				var SS = HZ / segmentCount;
				var Ry0 = target.y + ball.height - 1; // -1 to be sure the ball will be hit

				// adjusting bias for the ball-serve case
				// so the AI will never try to bounce a ball
				// with racket's angles in ball-serve
				var bias = isServe ? SETTINGS.bouncePlaceBiasSafe : SETTINGS.bouncePlaceBias;

				// when target is in dead zone adjust bias in a way
				// to prevent moving low/high part of racket to the deadzone
				if (target.y < (racket.movementBounds.top + HZ * 5 / 7)) {
					bias = bias.slice(0, 3).concat([0, 0, 0, 0]);
					// trace('top deadzone hit', bias);
				}
				else if (target.y > (racket.movementBounds.bottom - HZ * 5 / 7)) {
					bias = [0, 0, 0, 0.0].concat(bias.slice(4));
					// trace('bottom deadzone hit', bias);
				}

				// randomly choose what part of 7-parts model to use
				var part = Flixel.random.getObject(bouncePlace, bias);
				// trace('chosen bounce segment ${part - 3}');

				// displacement of racket in relation to target
				var racketDisplacement = -(SS * part + FLixel.random.float(0, SS) * 0);
				var targetRacketY = Ry0 + racketDisplacement;

				// tests to see the real ball target
				// var realTarget = rayCast2.path[rayCast.path.length - 1].clone();
				// var b = realTarget;
				// b.y -= ball.height * 0.5;

				// if (name.indexOf('hardest') != -1) {
				// 	var diff = Math.abs((b.y + ball.height - 1) - (b.y + 1 - racket.height));
				// 	trace(b.y + 1 - racket.height, b.y + ball.height - 1, targetRacketY, diff, HZ, racket.height + ball.height);
				// }
				// realTarget.put();

				return target.set(racket.x, targetRacketY);
			case UP, DOWN:
				throw "Implement it later";
		}

		// no changes in position
		return target.set(racket.x, racket.y);
	}

	function moveRacketTo(p:FlxPoint) {
		if (tween != null)
			tween.cancel();

		// don't move the racket if target point is the same
		// as current position
		if (p.equals(wp(racket.x, racket.y)))
			return;

		var path = p.distanceTo(wp(racket.x, racket.y));
		var duration = path / Pong.params.racketSpeed;
		tween = GAME.aiTweens.tween(racket, {y: p.y, x: p.x}, duration, {ease: FlxEase.linear});
	}

	override function update(dt:Float) {
		// I dont want any update code from the superclass
	}

	override function draw() {
		super.draw();

		if (drawTrajectory)
			debugDraw();
	}

	function debugDraw() {
		rayCast.draw(Flixel.camera.debugLayer.graphics);
		rayCast2.draw(Flixel.camera.debugLayer.graphics);

		return;

		var gfx = Flixel.camera.debugLayer.graphics;
		// draw ball velocity
		var ball = GAME.room.ball;
		gfx.lineStyle(1.5, 0x00FF55, 0.5);
		gfx.moveTo(ball.x, ball.y - 15);
		gfx.lineTo(ball.velocity.x + ball.x, ball.velocity.y + ball.y - 15);
		gfx.endFill();
	}
}
