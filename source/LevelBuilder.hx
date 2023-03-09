package;

import Player.PlayerOptions;
import RacketController.KeyboardMovementController;
import Utils.merge;
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

		var player = getPlayer(Reflect.copy(Player.defaultOptions));

		var ball = new Ball();
		ball.x += Flixel.width * 0.25;

		var walls = [
			getWall({pos: UP, padding: 5, size: 0.95}),
			getWall({pos: DOWN, padding: 5, size: 0.95}),
			getWall({pos: RIGHT, padding: 5, size: 0.95})
		];

		var batHole = Math.ceil(Pong.defaults.ballSize * 1.5);

		player.racket.movementBounds = getMovementBounds(walls[0], walls[1], batHole);
		player.scoreLabel.setPosition(Flixel.width * 0.75, Flixel.height * 0.15);
		player.scoreLabelText = 'balls: ';
		player.score = 0;

		return {
			ball: ball,
			walls: walls,
			player: player,
		};
	}

	function getPlayer(options:PlayerOptions):Player {
		var racket = new Racket({
			direction: options.position,
			thickness: Pong.defaults.racketThickness,
			size: Pong.defaults.racketLength,
			color: options.color
		});
		racket.screenCenter();
		racket.x = switch (options.position) {
			case LEFT:
				Pong.defaults.racketPadding;
			case RIGHT:
				Flixel.width - racket.width - Pong.defaults.racketPadding;
			default:
				racket.x;
		}

		var player = new Player(racket);
		player.options = options;
		player.name = options.name;
		player.scoreLabelText = '';
		player.score = 0;
		player.add(options.getController(racket));

		return player;
	}

	public function buildTwoPlayersRoom(?left:PlayerOptions, ?right:PlayerOptions):{
		ball:Ball,
		walls:Array<FlxSprite>,
		players:Array<Player>,
	} {
		if (left == null)
			left = Reflect.copy(Player.defaultOptions);
		else
			left = merge(Reflect.copy(Player.defaultOptions), left);

		if (right == null) {
			right = Reflect.copy(Player.defaultOptions);
			right.position = RIGHT;
		}
		else
			right = merge(Reflect.copy(Player.defaultOptions), right);

		var walls = [getWall({pos: UP, padding: 0}), getWall({pos: DOWN, padding: 0})];

		var batHole = Math.ceil(Pong.defaults.ballSize * 1.5);
		var movementBounds = getMovementBounds(walls[0], walls[1], batHole);

		var players = [getPlayer(left), getPlayer(right)];
		players[0].racket.movementBounds = players[1].racket.movementBounds = movementBounds;

		var label = players[0].scoreLabel;
		label.alignment = RIGHT;
		label.width = label.fieldWidth = 50;
		label.screenCenter(X);
		label.y = Flixel.height * 0.07;
		label.x -= 50;

		label = players[1].scoreLabel;
		label.alignment = LEFT;
		label.width = label.fieldWidth = 50;
		label.screenCenter(X);
		label.y = Flixel.height * 0.07;
		label.x += 50;

		return {
			ball: new Ball(),
			walls: walls,
			players: players,
		};
	}
}
