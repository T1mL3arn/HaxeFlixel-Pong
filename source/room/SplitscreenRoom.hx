package room;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
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

	var left:PlayerGuideUI;
	var right:PlayerGuideUI;

	public function new(room) {
		super();
		this.room = room;
	}

	override function create() {
		super.create();

		add(left = new PlayerGuideUI('W and S', [W, S], Flixel.width * 0.25));
		add(right = new PlayerGuideUI('UP and DOWN', [UP, DOWN], Flixel.width * 0.75));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (left.playerIsReady && right.playerIsReady) {
			close();
		}
	}
}

class PlayerGuideUI extends FlxGroup {

	public var playerIsReady:Bool = false;

	var keys:Array<FlxKey>;
	var flicker:FlxFlicker;

	public function new(labelText:String, keys:Array<FlxKey>, xAlignCoord:Float) {
		super();

		this.keys = keys;

		var w = Flixel.width * 0.5 * 0.8;
		var y = Flixel.height * 0.6;
		var x = xAlignCoord - w * 0.5;

		labelText = 'press ${labelText}\nto move your paddle';

		var infoLabel = new FlxText(x, y, w, labelText, 18);
		infoLabel.width = w;
		infoLabel.alignment = CENTER;

		add(infoLabel);

		var waitLabel = new FlxText(x, Flixel.height * 0.8, w, 'waiting player', 16);
		waitLabel.width = w;
		waitLabel.alignment = CENTER;

		add(waitLabel);

		flicker = FlxFlicker.flicker(waitLabel, 0, 0.5);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.anyJustPressed(keys)) {
			playerIsReady = true;
			if (flicker != null) {
				flicker.stop();
				flicker = null;
			}
		}
	}

	override function destroy() {
		super.destroy();
	}
}
