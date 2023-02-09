package;

import RacketController.KeyboardMovementController;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

class PlayState extends FlxState {

	var player:Racket;
	var ball:FlxSprite;

	var walls:FlxTypedGroup<FlxObject>;

	override public function create() {
		super.create();

		bgColor = FlxColor.GRAY;

		walls = new FlxTypedGroup();

		player = cast walls.add(new Racket(100, 15, FlxDirection.RIGHT));
		player.screenCenter();
		player.x = 50;
		player.immovable = true;
		player.elasticity = 1;
		player.movementBounds = {
			x: player.x,
			right: 0.0,
			y: 40.0,
			bottom: Flixel.height - 40
		};
		add(player);

		add(new KeyboardMovementController(player));

		ball = new FlxSprite();
		ball.makeGraphic(15, 15, FlxColor.WHITE);
		ball.centerOrigin();
		ball.screenCenter();
		ball.velocity.set(0, 0);
		ball.elasticity = 1;
		add(ball);

		addWall(UP);
		addWall(DOWN);
		addWall(RIGHT);

		/*
			TODO:

			- allow a racket to be controlled in dfferent ways:
				- user keyboard control
				- ai control
		 */
	}

	function addWall(pos):FlxSprite {
		final thickness = 5;
		final wallPadding = 10;

		var wall = new FlxSprite();
		wall.elasticity = 1;
		wall.immovable = true;

		switch (pos) {
			case UP, DOWN:
				wall.makeGraphic(Std.int(Flixel.width * 0.95), thickness);
			case LEFT, RIGHT:
				wall.makeGraphic(thickness, Std.int(Flixel.height * 0.95));
		}

		wall.centerOrigin();

		switch (pos) {
			case UP:
				setSpritePosition(wall, Flixel.width / 2, wallPadding);
			case DOWN:
				setSpritePosition(wall, Flixel.width / 2, Flixel.height - wallPadding);
			case RIGHT:
				setSpritePosition(wall, Flixel.width - wallPadding, Flixel.height / 2);
			case LEFT:
				setSpritePosition(wall, wallPadding, Flixel.height / 2);
		}

		walls.add(wall);
		add(wall);

		return wall;
	}

	function setSpritePosition(sprite:FlxSprite, ?x:Float, ?y:Float) {
		if (x != null)
			sprite.x = x - sprite.origin.x;
		if (y != null)
			sprite.y = y - sprite.origin.y;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (ball.velocity.lengthSquared == 0 && Flixel.keys.justPressed.ANY) {
			ball.velocity.setPolarDegrees(300, 135 + Flixel.random.int(0, 105));
		}

		Flixel.collide(walls, ball, ballCollision);

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
