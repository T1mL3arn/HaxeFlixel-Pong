package;

import Player.PlayerOptions;
import Utils.merge;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;
import math.MathUtils.wp;
import netplay.Netplay.nextUid;
import racket.Racket;
import utils.FlxSpriteDraw.DashedLineStyle;
import utils.FlxSpriteDraw.drawDashedLine;

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

	public static final inst = new LevelBuilder();

	function new() {}

	function getWall(?options:WallParams):FlxSprite {

		if (options == null)
			options = defaultWallParams;

		var pos = options.pos == null ? defaultWallParams.pos : options.pos;
		var thickness = options.thickness == null ? defaultWallParams.thickness : options.thickness;
		var size = options.size == null ? defaultWallParams.size : options.size;
		var padding = options.padding == null ? defaultWallParams.padding : options.padding;

		var wall = new FlxSprite();
		wall.netplayUid = nextUid();
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

		var batHole = Math.ceil(Pong.params.ballSize * 1.5);

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
			thickness: Pong.params.racketThickness,
			size: Pong.params.racketLength,
			color: options.color
		});
		racket.netplayUid = nextUid();
		racket.screenCenter();
		racket.x = switch (options.position) {
			case LEFT:
				Pong.params.racketPadding;
			case RIGHT:
				Flixel.width - racket.width - Pong.params.racketPadding;
			default:
				racket.x;
		}

		var player = new Player(racket);
		player.netplayUid = nextUid();
		player.options = options;
		player.name = options.name;
		player.uid = options.uid ?? Std.string(haxe.Timer.stamp());
		player.scoreLabelText = '';
		player.score = 0;
		player.racketController = options.getController(racket);

		return player;
	}

	public function buildTwoPlayersRoom(?left:PlayerOptions, ?right:PlayerOptions) {
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

		var middleLine = new FlxSprite();
		var th = 5;
		middleLine.makeGraphic(th, Flixel.height, FlxColor.TRANSPARENT);
		middleLine.centerOrigin();
		middleLine.centerOffsets(true);

		var lineStyle:DashedLineStyle = {
			thickness: th,
			color: FlxColor.WHITE,
			capsStyle: NONE,
			segmentCount: 12,
			// dashLength: 20,
			// gapLength: 20,
		};
		drawDashedLine(middleLine, wp(th / 2, 15), wp(th / 2, Flixel.height - 15), lineStyle);
		middleLine.screenCenter();

		var batHole = Math.ceil(Pong.params.ballSize * 1.5);
		var movementBounds = getMovementBounds(walls[0], walls[1], batHole);

		var players = [getPlayer(left), getPlayer(right)];
		players[0].racket.movementBounds = players[1].racket.movementBounds = movementBounds;

		final scoreLabelPadding = 60.0;
		var label = players[0].scoreLabel;
		label.alignment = RIGHT;
		label.width = label.fieldWidth = 50;
		label.screenCenter(X);
		label.y = Flixel.height * 0.0675;
		label.x -= scoreLabelPadding;

		label = players[1].scoreLabel;
		label.alignment = LEFT;
		label.width = label.fieldWidth = 50;
		label.screenCenter(X);
		label.y = Flixel.height * 0.0675;
		label.x += scoreLabelPadding;

		var ball = new Ball();
		ball.netplayUid = nextUid();

		return {
			ball: ball,
			walls: walls,
			players: players,
			middleLine: middleLine,
		};
	}
}
