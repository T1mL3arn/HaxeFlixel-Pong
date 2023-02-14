package;

import Main.Pong;
import RacketController.KeyboardMovementController;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
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

class TrainingRoom extends FlxState {

	public var walls:FlxTypedGroup<FlxObject> = new FlxTypedGroup();
	public var ball:Ball;
	public var player:Player;

	var onGoal:Dynamic->Dynamic->Void;

	override function create() {

		add(ball = new Ball());

		var racket = new Racket({
			direction: FlxDirection.LEFT,
			thickness: Pong.defaults.racketThickness,
			size: Pong.defaults.racketLength,
			color: FlxColor.WHITE
		});
		racket.screenCenter();
		racket.x = Pong.defaults.racketPadding;
		walls.add(racket);

		var upWall = getWall({pos: UP, padding: 5, size: 0.95});
		var downWall = getWall({pos: DOWN, padding: 5, size: 0.95});
		var batHole = Math.ceil(Pong.defaults.ballSize * 1.5);

		racket.movementBounds = getMovementBounds(upWall, downWall, batHole);

		add(walls.add(upWall));
		add(walls.add(downWall));
		add(walls.add(getWall({pos: RIGHT, padding: 5, size: 0.95})));

		var kbd = new KeyboardMovementController(racket);
		kbd.speed = Pong.defaults.racketSpeed;
		add(kbd);

		player = new Player(racket);
		player.scoreLabel.setPosition(Flixel.width * 0.75, Flixel.height * 0.15);
		player.scoreLabelText = 'balls: ';
		player.score = 0;
		add(player);

		onGoal = (_, _) -> {
			resetBall();
			player.score += 1;
		}
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

	function getMovementBounds(a:FlxObject, b:FlxObject, gap:Float) {
		return {
			left: 0.0,
			right: 0.0,
			top: a.y + a.height + gap,
			bottom: b.y - gap
		};
	}

	override function update(dt:Float) {
		super.update(dt);

		if (ball.velocity.lengthSquared == 0 && Flixel.keys.justPressed.ANY) {
			ball.velocity.setPolarDegrees(300, 135 + Flixel.random.int(0, 105));
		}

		Flixel.collide(walls, ball, ballCollision);
		Flixel.overlap(player.hitArea, ball, onGoal);

		if (!ball.inWorldBounds()) {
			resetBall();
		}
	}

	function resetBall() {
		ball.velocity.set(0, 0);
		ball.screenCenter();
	}

	function ballCollision(wall:FlxObject, ball:Ball) {
		ball.hitBy = wall;
	}
}

class Ball extends FlxSprite {

	public var hitBy:FlxObject;

	public function new() {
		super();

		makeGraphic(Pong.defaults.ballSize, Pong.defaults.ballSize, FlxColor.WHITE);
		centerOrigin();
		screenCenter();
		elasticity = 1;
	}
}
