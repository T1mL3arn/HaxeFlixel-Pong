package room;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import haxe.Timer;

/**
	Room for two human players meant to play on the same PC.
**/
class SplitscreenRoom extends TwoPlayersRoom {

	public function new(left, right) {
		super(left, right);

		canPause = false;
		canOpenPauseMenu = false;
	}

	override function create() {
		super.create();

		// disable players so they could not move
		// when this state is created
		for (player in players) {
			player.active = false;
		}

		var guideState = new SplitscreenRoomGuide(this);
		guideState.closeCallback = () -> {
			canOpenPauseMenu = true;
			canPause = true;
		};
		openSubState(guideState);
	}
}

/**
	Substate to show Help info for both human players.
	Closes itself when players are ready.
**/
@:access(room.TwoPlayersRoom)
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

		// TODO show countdown when both players are ready
		// TODO when countdown ends serve the ball for the first time
		if (left.complete && right.complete) {
			close();
		}

		if (left.playerIsReady)
			room.players[0].active = true;

		if (right.playerIsReady)
			room.players[1].active = true;
	}
}

/**
	Help info for a human player
**/
class PlayerGuideUI extends FlxGroup {

	/**
		Indicates the player is ready to play
	**/
	public var playerIsReady:Bool = false;

	/**
		Indicates this ui completed its animations and ready
		to be disposed.
	**/
	public var complete:Bool = false;

	var keys:Array<FlxKey>;
	var flicker:FlxFlicker;
	var readyLabel:FlxText;
	var ui:FlxGroup;

	public function new(labelText:String, keys:Array<FlxKey>, xAlignCoord:Float) {
		super();

		this.keys = keys;

		var w = Flixel.width * 0.5 * 0.8;
		var y = Flixel.height * 0.6;
		var x = xAlignCoord - w * 0.5;

		labelText = 'press ${labelText}\nto move your paddle';

		ui = new FlxGroup();

		add(ui);

		var infoLabel = new FlxText(x, y, w, labelText, 18);
		infoLabel.width = w;
		infoLabel.alignment = CENTER;

		ui.add(infoLabel);

		var waitLabelY = Flixel.height * 0.8;
		var waitLabel = new FlxText(x, waitLabelY, w, 'waiting player', 16);
		waitLabel.width = w;
		waitLabel.alignment = CENTER;

		ui.add(waitLabel);

		flicker = FlxFlicker.flicker(waitLabel, 0, 0.5);

		readyLabel = new FlxText(x, waitLabelY, w, 'READY!', 20);
		readyLabel.alignment = CENTER;
	}

	function showReadyLabel() {
		add(readyLabel);

		Timer.delay(() -> {
			var f = FlxFlicker.flicker(readyLabel, 0.66, 0.066, false);
			@:privateAccess
			f.completionCallback = _ -> {
				readyLabel.kill();
				this.complete = true;
			};
		}, 750);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.anyJustPressed(keys)) {
			playerIsReady = true;
			if (flicker != null) {
				flicker.stop();
				flicker = null;
				ui.kill();
				showReadyLabel();
			}
		}
	}
}
