package room;

import flixel.FlxSubState;
import flixel.text.FlxText;

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

		add(buildGuideUI('W and S', Flixel.width * 0.25));
		add(buildGuideUI('UP and DOWN', Flixel.width * 0.75));
	}

	function buildGuideUI(labelText:String, ?alignLineX:Float):FlxText {

		var w = Flixel.width * 0.5 * 0.8;
		var y = Flixel.height * 0.6;
		var x = alignLineX - w * 0.5;

		labelText = 'use ${labelText} keys\nto move your paddle';

		var label = new FlxText(x, y, w, labelText, 18);
		label.width = w;
		label.alignment = CENTER;

		return label;
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
