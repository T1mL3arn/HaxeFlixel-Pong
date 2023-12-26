package ai;

import haxe.ds.ObjectMap;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint.get as point;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.path.FlxPath;
import flixel.tweens.FlxEase;
import flixel.util.FlxSpriteUtil;
import math.LineSegment;
import math.MathUtils.lerp;
import math.MathUtils.wp;
import math.RayCast;
import openfl.display.Graphics;

typedef SmartAIParams = {

	/**
		Angle variance in degrees
	**/
	angleVariance:Float,

	bouncePlaceBias:Array<Float>,
	// bias for ball serve to be sure that AI never misses the first ball
	bouncePlaceBiasSafe:Array<Float>,
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

	public var drawTrajectory:Bool = false;

	var target:FlxPoint;

	var SETTINGS:SmartAIParams = {
		angleVariance: 0.6,
		bouncePlaceBias: [4, 10, 7, 1, 7, 10, 4],
		bouncePlaceBiasSafe: [0, 10, 7, 0, 7, 10, 0],
	};

	var bouncePlaceBiasSafe = [0, 10, 7, 0, 7, 10, 0];

	public function new(racket, name) {
		super(racket, name);

		// how does this AI work?

		GAME.ballCollision.add(calcTrajectory);
		GAME.signals.ballServed.add(onBallServed);
		Flixel.signals.postStateSwitch.add(buildRoomModel);

		rayCast = new RayCast();
		rayCast2 = new RayCast();
		rayCast2.trajectoryColor = 0xFFBB00;

		target = point();
	}

	var rayCast:RayCast;
	var rayCast2:RayCast;

	/** This AI's goal area **/
	var thisGoal:FlxRect;

	override function destroy() {
		super.destroy();

		GAME.ballCollision.remove(calcTrajectory);
		GAME.signals.ballServed.remove(onBallServed);

		Flixel.signals.postStateSwitch.remove(buildRoomModel);

		rayCast.destroy();
		rayCast2.destroy();

		target.put();
	}

	function onBallServed() {
		calcTrajectory(null, GAME.room.ball);
	}

	function buildRoomModel() {

		var roomModel = [];

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

			roomModel.push(box);
		}

		rayCast.model = rayCast2.model = roomModel;
	}

	function calcTrajectory(object:FlxObject, ball:Ball) {

		// trajectory is calculated only when:
		// - ball is served
		// - when ball is hit by other racket
		if (!(object == null || (object is Racket && object != racket)))
			return;

		var ballPos = ball.getWorldPos();
		var ray1 = ball.velocity.clone(wp());
		// max trajectory length is a diagonal of screen
		ray1.length = Math.sqrt(Math.pow(Flixel.width, 2) + Math.pow(Flixel.height, 2));
		var ray2 = ray1.clone(wp());

		ray1.rotateByDegrees(-SETTINGS.angleVariance);
		ray2.rotateByDegrees(SETTINGS.angleVariance);

		var t1 = rayCast.castRay(ballPos, ray1, 3, 0, thisGoal);
		var t2 = rayCast2.castRay(ballPos, ray2, 3, 0, thisGoal);

		// possible ball position segment
		var p1 = t1[t1.length - 1].clone();
		var p2 = t2[t2.length - 1].clone();

		if (t1.length == t2.length) {
			// 99% sure trajectories are hit the same vertical wall

			// TODO be 100% sure that last points of both trajectories
			// are lie on the same vertical line, or at least "close enough" ?

			target = lerp(p1, p2, Flixel.random.int(0, 1000) * 0.001, target);
		}
		else {
			// but if these trajectories dont

			var closest = p1.distSquared(wp(racket.x, racket.y)) < p2.distSquared(wp(racket.x, racket.y)) ? p1 : p2;
			target.copyFrom(closest);
		}

		target = calcRacketDestination(ball, target, object == null);
		moveRacketTo(target);

		p1.put();
		p2.put();
		ballPos.put();
	}

	var bouncePlace = [-3, -2, -1, 0, 1, 2, 3].map(x -> x + 3);

	function calcRacketDestination(ball:Ball, ballPos:FlxPoint, isServe:Bool):FlxPoint {
		var bhs = ball.width * 0.5;
		// var ballBounds = ball.getHitbox(tmprect1);
		// var racketBounds = racket.getHitbox(tmprect2);

		switch (racket.position) {
			case LEFT, RIGHT:
				var target = ballPos;

				// in model the target point represents ball's center,
				// here I convert modeled Y back to ball's real Y
				target.y -= ball.height * 0.5;

				// TODO store and read this from racket?
				final segmentCount = 7;
				var hitZone = racket.height + ball.height;
				var segmentSize = hitZone / segmentCount;

				// adjusting bias for the ball-serve case
				// so the AI will never try to bounce a ball
				// with racket's angles in ball-serve
				var bias = isServe ? SETTINGS.bouncePlaceBiasSafe : SETTINGS.bouncePlaceBias;

				// randomly choose what part of 7-parts model to use
				var part = Flixel.random.getObject(bouncePlace, bias);
				// trace('chosen bounce segment ${part - 3}');

				// displacement of racket in relation to target
				var racketDisplacement = -(segmentSize * part + FLixel.random.float(0, segmentSize));
				var targetRacketY = target.y + racketDisplacement;

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
