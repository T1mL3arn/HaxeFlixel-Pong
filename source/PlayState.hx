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
		left: 0.0,
		right: 0.0,
		top: 40.0,
		bottom: Flixel.height - 40.0
	};

	var ball:FlxSprite;
	var walls:FlxTypedGroup<FlxObject> = new FlxTypedGroup();

	override public function create() {
		super.create();

		bgColor = 0xFF111111;

		buildTrainingRoom();
		// buildShadowFightRoom();
		// comment to fuck with git diff

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
			case DOWN:
				wall.y = Flixel.height - thickness - padding;
			case LEFT:
				wall.x = padding;
			case RIGHT:
				wall.x = Flixel.width - thickness - padding;
		}

		return wall;
	}

	function getRacket(dir = FlxDirection.LEFT):Racket {
		return new Racket({
			direction: dir,
			thickness: Pong.defaults.racketThickness,
			size: Pong.defaults.racketLength,
			color: FlxColor.WHITE
		});
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

		var upWall = getWall({pos: UP, padding: 5, size: 0.95});
		var downWall = getWall({pos: DOWN, padding: 5, size: 0.95});
		var batHole = Math.ceil(Pong.defaults.ballSize * 1.5);

		racket.movementBounds = {
			left: 0.0,
			right: 0.0,
			top: upWall.y + upWall.height + batHole,
			bottom: downWall.y - batHole
		};

		add(walls.add(upWall));
		add(walls.add(downWall));
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
