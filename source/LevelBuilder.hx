package;

import Main.Pong;
import RacketController.KeyboardMovementController;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

typedef WallParams = {
	?pos:FlxDirection,
	?thickness:Int,
	?size:Float,
	?padding:Float,
}

final defaultWallParams:WallParams = {
	pos: FlxDirection.UP,
	thickness: 5,
	size: 1.0,
	padding: 0,
}

class LevelBuilder {

	static public final inst = new LevelBuilder();

	function new() {}

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

	public function buildTraningRoom():{
		player:Player,
		walls:Array<FlxSprite>,
		ball:Ball,
	} {

		var ball = new Ball();
		ball.x += Flixel.width * 0.25;

		var racket = new Racket({
			direction: FlxDirection.LEFT,
			thickness: Pong.defaults.racketThickness,
			size: Pong.defaults.racketLength,
			color: FlxColor.WHITE
		});
		racket.screenCenter();
		racket.x = Pong.defaults.racketPadding;

		var walls = [
			getWall({pos: UP, padding: 5, size: 0.95}),
			getWall({pos: DOWN, padding: 5, size: 0.95}),
			getWall({pos: RIGHT, padding: 5, size: 0.95})
		];

		var batHole = Math.ceil(Pong.defaults.ballSize * 1.5);

		racket.movementBounds = getMovementBounds(walls[0], walls[1], batHole);

		var player;
		player = new Player(racket);
		player.scoreLabel.setPosition(Flixel.width * 0.75, Flixel.height * 0.15);
		player.scoreLabelText = 'balls: ';
		player.score = 0;
		player.add({
			var kbd = new KeyboardMovementController(racket);
			kbd.speed = Pong.defaults.racketSpeed;
			kbd;
		});

		return {
			ball: ball,
			walls: walls,
			player: player,
		};
	}

	function getPlayer(dir:FlxDirection, ?controller):Player {
		var racket = new Racket({
			direction: dir,
			thickness: Pong.defaults.racketThickness,
			size: Pong.defaults.racketLength,
			color: FlxColor.WHITE
		});
		racket.screenCenter();
		racket.x = switch (dir) {
			case LEFT:
				Pong.defaults.racketPadding;
			case RIGHT:
				Flixel.width - racket.width - Pong.defaults.racketPadding;
			default:
				racket.x;
		}

		var player = new Player(racket);
		player.scoreLabelText = '';
		player.score = 0;
		player.add({
			var kbd = new KeyboardMovementController(racket);
			kbd.speed = Pong.defaults.racketSpeed;
			kbd;
		});

		return player;
	}

	public function buildTwoPlayersRoom():{
		ball:Ball,
		walls:Array<FlxSprite>,
		players:Array<Player>,
	} {
		var walls = [getWall({pos: UP, padding: 0}), getWall({pos: DOWN, padding: 0})];

		var batHole = Math.ceil(Pong.defaults.ballSize * 1.5);
		var movementBounds = getMovementBounds(walls[0], walls[1], batHole);

		var players = [getPlayer(LEFT), getPlayer(RIGHT)];
		players[0].racket.movementBounds = players[1].racket.movementBounds = movementBounds;

		players[0].scoreLabel.width = 50;
		players[0].scoreLabel.textField.width = 50;
		players[0].scoreLabel.alignment = RIGHT;
		players[0].scoreLabel.screenCenter(X);
		players[0].scoreLabel.y = Flixel.height * 0.07;
		players[0].scoreLabel.x -= 50;

		players[1].scoreLabel.width = 50;
		players[1].scoreLabel.textField.width = 50;
		players[1].scoreLabel.alignment = LEFT;
		players[1].scoreLabel.screenCenter(X);
		players[1].scoreLabel.y = Flixel.height * 0.07;
		players[1].scoreLabel.x += 50;

		return {
			ball: new Ball(),
			walls: walls,
			players: players,
		};
	}
}
