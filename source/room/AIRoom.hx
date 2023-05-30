package room;

import ai.AIFactory.setAIPlayer;

abstract AIRoom(TwoPlayersRoom) to TwoPlayersRoom {

	public inline function new(left:String = 'easy', right:String = 'easy') {
		this = new TwoPlayersRoom(setAIPlayer({position: LEFT}, left), setAIPlayer({position: RIGHT}, right));
		Pong.params.scoreToWin = 2;
		Pong.params.ballSpeed *= 2;

		var oldCloseCallback = this.closeCallback;
		this.closeCallback = () -> {
			if (oldCloseCallback != null)
				oldCloseCallback();
			// restore default game params;
			Pong.params = Reflect.copy(Pong.defaultParams);
		}
	}
}
