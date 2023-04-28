package room;

import flixel.FlxObject;
import flixel.FlxSubState;

class SplitscreenRoom extends TwoPlayersRoom {

	public function new(left, right) {
		super(left, right);

		this.persistentDraw = true;
		this.persistentUpdate = false;
	}

	override function create() {
		super.create();

		this.openSubState(new SplitscreenRoomGuide(this));
	}
}

class SplitscreenRoomGuide extends FlxSubState {

	var room:SplitscreenRoom;
	var leftIsReady:Bool = false;
	var rightIsReady:Bool = false;

	public function new(room) {
		super();
		this.room = room;
	}

	override function create() {
		super.create();

		add(buildGuideUI('left', 0, 0));
		add(buildGuideUI('right', 0, 0));
	}

	function buildGuideUI(label:String, x, y) {
		return new FlxObject();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.anyJustPressed([W, S])) {
			leftIsReady = true;
		}

		if (Flixel.keys.anyJustPressed([UP, DOWN])) {
			rightIsReady = true;
		}

		if (leftIsReady && rightIsReady) {
			close();
		}
	}
}
