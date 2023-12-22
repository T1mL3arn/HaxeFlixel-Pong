package room;

import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;

typedef RoomModel = {

	/**
		Solid objects to test collision agains ball.
		This could contain not solid walls but rackets as well
	**/
	public var walls:FlxTypedGroup<FlxObject>;

	/**
		Goals of all players.
		The ball checks overlap with these areas.
	**/
	public var playerGoals:FlxTypedGroup<FlxObject>;

	public var ball:Ball;

	public var players:Array<Player>;
};
