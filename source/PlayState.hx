package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;

class PlayState extends FlxState {

	var player:Racket;
	var ball:FlxSprite;

	var walls:FlxGroup;

	override public function create() {
		super.create();

		bgColor = FlxColor.GRAY;

		walls = new FlxGroup();

		player = new Racket(100, 15, FlxDirection.RIGHT);
		player.centerOrigin();
		player.screenCenter();
		player.x = player.width * 2;
		player.immovable = true;
		player.elasticity = 1;
		walls.add(player);
		add(player);

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
			Lets do some pong:

			- top and bottom walls to collide the ball
			- movement boundaries for racket
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

	function setSpritePosition(obj:FlxSprite, ?x:Float, ?y:Float) {
		if (x != null)
			obj.x = x - obj.origin.x;
		if (y != null)
			obj.y = y - obj.origin.y;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (ball.velocity.lengthSquared == 0)
			if (Flixel.keys.justPressed.ANY) {
				ball.velocity.setPolarDegrees(300, 135 + Flixel.random.int(0, 105));
			}

		moveRacketByKeyboard(player);
		Flixel.collide(walls, ball, racketBallCollisionon);

		// ball resets its position when its is outside world's boundaries
		var rect = FlxRect.get();
		if (!Flixel.worldBounds.overlaps(ball.getScreenBounds(rect))) {
			ball.velocity.set(0, 0);
			ball.screenCenter();
		}
		rect.put();
	}

	function moveRacketByKeyboard(racket:Racket) {
		racket.velocity.set(0, 0);

		var pressed = Flixel.keys.pressed;
		if (pressed.UP) {
			racket.velocity.setPolarDegrees(200, -90);
		}
		else if (pressed.DOWN) {
			racket.velocity.setPolarDegrees(200, 90);
		}
	}

	function racketBallCollisionon(racket:Racket, ball:FlxSprite) {
		// TODO some sound
	}
}
