package room;

import Player.PlayerOptions;
import flixel.FlxState;

class SplitscreenRoom extends FlxState {

	var left(default, null):Null<PlayerOptions>;
	var right(default, null):Null<PlayerOptions>;

	var readyCounter:Int = 0;
	var playersAreReady:Bool = false;

	public function new(left, right) {
		super();

		this.left = left;
		this.right = right;
		this.persistentDraw = true;
		this.persistentUpdate = true;
	}

	override function create() {
		super.create();

		this.openSubState(new TwoPlayersRoom(left, right));
		subStateOpened.addOnce(state -> {
			state.active = false;
			trace('substate disabled');
		});
	}

	override function update(dt:Float) {
		super.update(dt);

		if (!playersAreReady && Flixel.keys.anyJustPressed([W, S, UP, DOWN])) {
			readyCounter += 1;
		}

		if (!playersAreReady && readyCounter >= 2) {
			playersAreReady = true;
			subState.active = true;
		}
	}
}
