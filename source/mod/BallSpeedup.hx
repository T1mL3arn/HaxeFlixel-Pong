package mod;

import Pong.PongParams;
import Utils.merge;
import flixel.sound.FlxSound;

/**
	This object tracks goals and paddle hits to update
	initial ball speed in the way that the speed increases after 
	every goal and after series of a paddle collision. 
	Thus, making gameplay more spicy.
**/
@:build(utils.BuildMacro.addField_GAME())
class BallSpeedup {

	var ballSpeedMaxFactor:Float = 1.55;
	var afterGoalSpeedMod:Float;
	// speed mod after N racket hits
	var racketHitsSpeedMod:Float = 0.0325;
	// number of racket hits (let it be ODD number)
	var racketHitsBeforeSpeedup:Int = 5;

	var racketHitsCount:Int = 0;
	var goalsCount:Int = 0;

	var initialParams:PongParams;
	var currentParams:PongParams;

	var speedUpSound:FlxSound;

	public function new() {
		init();

		speedUpSound = Flixel.sound.load(AssetPaths.sfx_speedup__ogg, 0.45);
		speedUpSound.group = GAME.gameSoundGroup;
	}

	public function init() {
		initialParams = merge({}, Pong.params);
		currentParams = Pong.params;

		// Speed mod is calculated to fit the max ball speed.
		// Math.max() is to prevent devision by ZERO (it happened during tests)
		afterGoalSpeedMod = (ballSpeedMaxFactor - 1) / Math.max(1, (initialParams.scoreToWin - 1) * 2);
	}

	public function onGoal() {
		goalsCount += 1;
		racketHitsCount = 0;
		currentParams.ballSpeed = limitBallSpeed(initialParams.ballSpeed * (1 + goalsCount * afterGoalSpeedMod));
	}

	public function onRacketHit() {
		// NOTE this must be called BEFORE racket bouncer!
		racketHitsCount += 1;
		if (racketHitsCount % racketHitsBeforeSpeedup == 0) {
			var speedAddon = initialParams.ballSpeed * racketHitsSpeedMod;
			currentParams.ballSpeed += speedAddon;
			// let's not limit such speed
			// currentParams.ballSpeed = limitBallSpeed(currentParams.ballSpeed);
			speedUpSound.play();
		}
	}

	inline function limitBallSpeed(speed):Float {
		return Math.min(speed, initialParams.ballSpeed * ballSpeedMaxFactor);
	}
}
