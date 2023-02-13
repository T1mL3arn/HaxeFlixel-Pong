package;

import Main.Pong;
import RacketController.KeyboardMovementController;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

typedef WallParams = {
	?pos:FlxDirection,
	?thickness:Int,
	?size:Float,
	?padding:Float,
};

final defaultWallParams:WallParams = {
	pos: FlxDirection.UP,
	thickness: 5,
	size: 1.0,
	padding: 0,
}

class PlayState extends FlxState {

	final racketBounds = {
		x: 0.0,
		right: 0.0,
		y: 40.0,
		bottom: Flixel.height - 40.0
	};

	var ball:FlxSprite;

	var walls:FlxTypedGroup<FlxObject>;

	override public function create() {
		super.create();

		bgColor = FlxColor.GRAY;

		walls = new FlxTypedGroup();

		// buildTrainingRoom();
		buildShadowFightRoom();

		/*
			TODO:
			- allow a racket to be controlled in dfferent ways:
				- user keyboard control
				- ai control
		 */
	}

	function getWall(?options:WallParams):FlxSprite {

		if (options == null)
			options = defaultWallParams;

		var pos = options.pos == null ? defaultWallParams.pos : options.pos;
		var thickness = options.thickness == null ? defaultWallParams.thickness : options.thickness;
		var size = options.size == null ? defaultWallParams.size : options.size;
		var padding = options.padding == null ? defaultWallParams.padding : options.padding;

		var wall = new FlxSprite();
		wall.elasticity = 1;
		wall.immovable = true;

		switch (pos) {
			case UP, DOWN:
				wall.makeGraphic(Std.int(Flixel.width * size), thickness);
			case LEFT, RIGHT:
				wall.makeGraphic(thickness, Std.int(Flixel.height * size));
		}

		wall.screenCenter();

		switch (pos) {
			case UP:
				wall.y = padding;
			// wall.setPosition(padding, 0);
			case DOWN:
				wall.y = Flixel.height - thickness - padding;
			// wall.setPosition(0, Flixel.height - thickness - padding);
			case LEFT:
				wall.x = padding;
			// wall.setPosition(0, 0);
			case RIGHT:
				wall.x = Flixel.width - thickness - padding;
				// wall.setPosition(Flixel.width - thickness, 0);
		}

		return wall;
	}

	function getRacket(dir = FlxDirection.LEFT) {
		return new Racket(Pong.defaults.racketLength, Pong.defaults.racketThickness, dir);
	}

	function buildTrainingRoom() {
		var racket = getRacket();
		racket.screenCenter();
		racket.x = Pong.defaults.racketPadding;
		racket.movementBounds = racketBounds;

		walls.add(racket);
		add(racket);

		var kbd = new KeyboardMovementController(racket);
		kbd.speed = Pong.defaults.racketSpeed;
		add(kbd);

		ball = new FlxSprite();
		ball.makeGraphic(Pong.defaults.ballSize, Pong.defaults.ballSize, FlxColor.WHITE);
		ball.centerOrigin();
		ball.screenCenter();
		ball.velocity.set(0, 0);
		ball.elasticity = 1;
		add(ball);

		add(walls.add(getWall({pos: UP, padding: 5, size: 0.95})));
		add(walls.add(getWall({pos: DOWN, padding: 5, size: 0.95})));
		add(walls.add(getWall({pos: RIGHT, padding: 5, size: 0.95})));
	}

	function buildShadowFightRoom() {
		// LEFT racket
		var racket = getRacket(FlxDirection.LEFT);
		racket.screenCenter();
		racket.x = Pong.defaults.racketPadding;
		racket.movementBounds = racketBounds;
		walls.add(racket);
		add(racket);

		var kbd = new KeyboardMovementController(racket);
		kbd.speed = Pong.defaults.racketSpeed;
		add(kbd);

		// RIGHT racket
		var racket = getRacket(FlxDirection.RIGHT);
		racket.screenCenter();
		racket.x = Flixel.width - racket.width - Pong.defaults.racketPadding;
		racket.movementBounds = racketBounds;
		walls.add(racket);
		add(racket);

		var kbd = new KeyboardMovementController(racket);
		kbd.speed = Pong.defaults.racketSpeed;
		add(kbd);

		ball = new FlxSprite();
		ball.makeGraphic(Pong.defaults.ballSize, Pong.defaults.ballSize, FlxColor.WHITE);
		ball.centerOrigin();
		ball.screenCenter();
		ball.velocity.set(0, 0);
		ball.elasticity = 1;
		add(ball);

		add(walls.add(getWall({pos: UP, padding: 0})));
		add(walls.add(getWall({pos: DOWN, padding: 0})));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (ball.velocity.lengthSquared == 0 && Flixel.keys.justPressed.ANY) {
			ball.velocity.setPolarDegrees(300, 135 + Flixel.random.int(0, 105));
		}

		Flixel.collide(walls, ball);

		// ball resets its position when its is outside world's boundaries
		var rect = FlxRect.get();
		if (!Flixel.worldBounds.overlaps(ball.getScreenBounds(rect))) {
			ball.velocity.set(0, 0);
			ball.screenCenter();
		}
		rect.put();
	}

	function ballCollision(racket:Racket, ball:FlxSprite) {
		// TODO some sound
	}
}
