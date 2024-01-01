package ai;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tweens.misc.VarTween;

class BaseAI extends RacketController {

	public var name:String;

	public var drawDebugInfo:Bool = false;

	/**
		Target coord for the racket.
	**/
	public var target(default, null):FlxPoint;

	var tween:VarTween;

	public function new(racket:Racket, ?name:String) {
		super(racket);
		this.name = name ?? 'base AI';
		GAME.aiTweens.active = true;
		GAME.signals.ballCollision.add(onBallCollision);
		GAME.signals.ballServed.add(onBallServe);
	}

	override function destroy() {
		super.destroy();

		GAME.signals.ballCollision.remove(onBallCollision);
		GAME.signals.ballServed.remove(onBallServe);
	}

	override function update(dt:Float) {}

	@:noCompletion
	function onBallServe() {
		onBallCollision(null, GAME.room.ball);
	}

	/**
		Called when ball is served or colide with something
		@param obj an object with which a ball is collide (`null` if it is `serve` event)
		@param ball 
	**/
	function onBallCollision(obj:FlxObject, ball:Ball) {}

	/**
		Draw any debug things you implemented.
	**/
	public function drawDebug() {}

	#if debug
	override function draw() {
		super.draw();

		if (drawDebugInfo)
			drawDebug();
	}
	#end
}
