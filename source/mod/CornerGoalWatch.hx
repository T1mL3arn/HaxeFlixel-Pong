package mod;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import racket.Racket;
import state.BaseGameState;
import utils.FlxSpriteDraw.twinkle;

using Lambda;

/**
		
	Purpose: detect when corner goal happens and 
	reward such goal with more points.

	How it works:

	- place some CORNER objects at corners
	- check ball overlaps any CORNER object
	- when overlaping occurs then mark next goal as CORNER goal
	- when goal happens and it is a CORNER goal - apply bonus points
		to the player who scored a goal

	Considerations:

	- be sure that when corner OVERLAP happens you don't miss the goal
	- don't make the wrong player to get bonus points
**/
@:build(utils.BuildMacro.addField_GAME())
class CornerGoalWatch extends FlxBasic {

	public var bonusPoints:Int = 1;

	var corners:FlxGroup;

	var waitForGoal:Bool;
	var rewardPlayer:Player;
	var yeahSound:FlxSound;

	public function new(rackets:Array<Racket>) {
		super();

		corners = new FlxGroup();

		yeahSound = Flixel.sound.load(AssetPaths.yeah_crowd_men__ogg, 1.0, GAME.gameSoundGroup);

		for (racket in rackets) {
			switch (racket.position) {
				case LEFT | RIGHT:
					var bounds = racket.movementBounds;
					var cornerBoxWidth = Pong.params.racketThickness * 1.1;
					var c1 = new FlxObject();
					var c2 = new FlxObject();
					c1.setSize(cornerBoxWidth, bounds.top - Pong.params.ballSize * 0.75);
					c2.setSize(cornerBoxWidth, bounds.top - Pong.params.ballSize * 0.75);
					c1.moves = c2.moves = false;

					var offset = 0.1;
					c1.x = c2.x = racket.x + racket.width * (1 - offset) - c1.width;
					c1.y = 0;
					c2.y = Flixel.height - c2.height;

					if (racket.position == RIGHT) {
						c1.x = c2.x = racket.x + racket.width * offset;
					}

					// trace(racket.position.toString(), c1.x, c1.y, c2.x, c2.y);

					// Since corner objects dont belong to any state
					// (means they are not updated)
					// I have manually set its last position
					// to make collision work.
					c1.last.set(c1.x, c1.y);
					c2.last.set(c2.x, c2.y);

					corners.add(c1);
					corners.add(c2);

				case _:
			}
		}

		GAME.signals.goal.add(onGoal);
		GAME.signals.ballCollision.add(possibleResetState);
		GAME.signals.ballServed.add(reset);
	}

	override function destroy() {
		super.destroy();

		yeahSound.destroy();
		corners.destroy();
		GAME.signals.goal.remove(onGoal);
		GAME.signals.ballCollision.remove(possibleResetState);
		GAME.signals.ballServed.remove(reset);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		Flixel.overlap(corners, GAME.room.ball, possibleCornerGoal);
	}

	function possibleCornerGoal(_, ball:Ball) {
		//
		waitForGoal = true;
		var whoHitBall = GAME.room.players.find(p -> p.racket == ball.hitBy);
		rewardPlayer = whoHitBall;
		// trace('POSSIBLE corner goal by ${rewardPlayer.name}');
	}

	function onGoal(player) {
		if (waitForGoal) {
			waitForGoal = false;
			if (rewardPlayer == null || player != rewardPlayer) {
				throw 'ERROR: Corner goal from the wrong player detected!\n\nWhant ${rewardPlayer}\nGet ${player}';
			}

			yeahSound.play();
			GAME.room.updateScore(rewardPlayer, rewardPlayer.score + bonusPoints);
			showLabel(rewardPlayer);
			// trace('CORNER GOAL! Bonus for ${rewardPlayer.name}');
		}
		waitForGoal = false;
	}

	function possibleResetState(obj:FlxObject, _) {
		if (obj is Racket)
			reset();
	}

	override function draw() {
		corners.draw();
	}

	public function reset() {
		waitForGoal = false;
		rewardPlayer = null;
	}

	/**
		Shows label when playr scores corner goal
		@param forPlayer 
	**/
	public function showLabel(player:Player, label = 'CORNER !!!') {
		var twinkleTime = Pong.params.ballServeDelay;
		var state:BaseGameState = cast GAME.room;

		var text = new FlxText(0, 0, 0, label, 24);
		state.uiObjects.add(text);

		switch (player.racket.position) {
			case LEFT:
				text.x = player.scoreLabel.x - text.width - 15;
				text.y = player.scoreLabel.y;
			case RIGHT:
				text.x = player.scoreLabel.x + player.scoreLabel.width + 15;
				text.y = player.scoreLabel.y;
			case _:
				0;
		}

		var removeText = ()->state.uiObjects.remove(text).destroy();
		var twinkleComplete = () -> {
			state.tweenManager.tween(text, {alpha: 0}, 0.25, {onComplete: _ -> removeText()});
		};
		twinkle(text, FlxColor.ORANGE, twinkleTime, 1 / 20, state.timerManager, twinkleComplete);
	}
}
