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
	var afterGoalSpeedMod:Float = 0;
	// speed mod after N racket hits
	var racketHitsSpeedMod:Float = 0.0325;
	// number of racket hits (let it be ODD number)
	var racketHitsBeforeSpeedup:Int = 5;

	var racketHitsCount:Int = 0;
	var goalsCount:Int = 0;

	var initialParams:PongParams;
	var currentParams:PongParams;

	public function new() {
		init();

		GAME.signals.goal.add(onGoal);
	}

	public function init() {
		initialParams = merge({}, Pong.params);
		currentParams = Pong.params;
		racketHitsCount = 0;
		goalsCount = 0;

		// Speed mod is calculated to fit the max ball speed.
		// Math.max() is to prevent devision by ZERO (it happened during tests)
		afterGoalSpeedMod = (ballSpeedMaxFactor - 1) / Math.max(1, (initialParams.scoreToWin - 1) * 2);
		// trace('MOD speed: $afterGoalSpeedMod');
		// trace('INIT speed: ${currentParams.ballSpeed}');
	}

	public function onGoal(?_) {
		goalsCount += 1;
		racketHitsCount = 0;
		currentParams.ballSpeed = limitBallSpeed(initialParams.ballSpeed * (1 + goalsCount * afterGoalSpeedMod));
		// trace('GOAL speed: ${currentParams.ballSpeed}');
	}

	/**
		@return `true` if ball's speed is modified
	**/
	public function onRacketHit():Bool {
		// NOTE this must be called BEFORE racket bouncer!
		racketHitsCount += 1;
		if (racketHitsCount % racketHitsBeforeSpeedup == 0) {
			var speedAddon = initialParams.ballSpeed * racketHitsSpeedMod;
			currentParams.ballSpeed += speedAddon;
			// let's not limit such speed
			// currentParams.ballSpeed = limitBallSpeed(currentParams.ballSpeed);
			playSpeedupSound();
			// trace('RACKETHIT speed: ${currentParams.ballSpeed}');
			return true;
		}
		return false;
	}

	public function playSpeedupSound() {
		Flixel.sound.play(AssetPaths.sfx_speedup__ogg, 0.4, GAME.gameSoundGroup);
	}

	inline function limitBallSpeed(speed):Float {
		return Math.min(speed, initialParams.ballSpeed * ballSpeedMaxFactor);
	}

	public function destroy() {
		GAME.signals.goal.remove(onGoal);
	}
}
