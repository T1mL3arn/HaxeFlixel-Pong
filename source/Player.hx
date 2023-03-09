package;

import RacketController.KeyboardMovementController;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

typedef PlayerOptions = {
	?name:String,
	position:FlxDirection,
	?color:FlxColor,
	?getController:Racket->RacketController
}

class Player extends FlxGroup {

	public static final defaultOptions:PlayerOptions = {
		name: 'player',
		position: LEFT,
		color: FlxColor.WHITE,
		getController: racket -> {
			var c = new KeyboardMovementController(racket);
			c.speed = Pong.defaults.racketSpeed;
			return c;
		},
	};

	public var name:String;
	public var racket:Racket;
	public var score(default, set):Int = 0;
	public var scoreLabel:FlxText;
	public var scoreLabelText:String = '';
	public var options:PlayerOptions;

	public var hitArea:FlxObject;

	public function new(racket:Racket) {
		super();

		this.racket = racket;
		add(racket);

		scoreLabel = new FlxText(0, 0, 150, "", 24);
		add(scoreLabel);

		// ball collision area
		hitArea = switch (racket.position) {
			case LEFT, RIGHT:
				new FlxObject(0, 0, 40, Flixel.height);
			case UP, DOWN:
				new FlxObject(0, 0, Flixel.width, 40);
		}

		switch (racket.position) {
			case LEFT:
				hitArea.x = -hitArea.width * 1.2;
			case RIGHT:
				hitArea.x = Flixel.width + hitArea.width * 0.2;
			default:
				// TODO UP and DOWN
				0;
		}

		add(hitArea);
	}

	function set_score(score):Int {
		this.score = score;
		scoreLabel.text = '$scoreLabelText$score';
		return score;
	}
}
