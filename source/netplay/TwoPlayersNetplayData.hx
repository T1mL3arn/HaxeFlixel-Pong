package netplay;

import flixel.FlxObject;

class TwoPlayersNetplayData {}

enum abstract NetworkMessageType(String) {
	var PaddleAction;
	var PaddleData;
	var BallData;
	var BallSpeedup;
	var BallCollision;
	var Goal;
	var ScoreData;
	var CongratScreenData;
	var ResetRoom;
	var BallPreServe;
	var DebugPause;
	var DebugPauseRequest;
	var ShowCongratScreen;
	var FullSync;
}

typedef NetworkMessage = {
	type:NetworkMessageType,
	data:Any,
}

typedef ObjectMotionData = {
	?uid:String,
	x:Float,
	y:Float,
	vx:Float,
	vy:Float,
}

typedef BallCollisionData = {
	wallUid:Int,
	ball:{
		uid:Int, x:Float, y:Float, vx:Float, vy:Float,
	}
};

var ballCollisionData(default, null) = {
	wallUid: -1,
	ball: {
		uid: -1,
		x: 0.0,
		y: 0.0,
		vx: 0.0,
		vy: 0.0,
	}
}

@:access(room.TwoPlayersRoom)
function getBallCollisionData(wall:FlxObject, ball:Ball) {
	ballCollisionData.wallUid = wall?.netplayUid ?? -1;
	ballCollisionData.ball.uid = ball.netplayUid;
	ballCollisionData.ball.x = ball.x;
	ballCollisionData.ball.y = ball.y;
	ballCollisionData.ball.vx = ball.velocity.x;
	ballCollisionData.ball.vy = ball.velocity.y;
	return ballCollisionData;
}
