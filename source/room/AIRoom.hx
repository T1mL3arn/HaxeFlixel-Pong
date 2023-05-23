package room;

import ai.AIFactory.setAIPlayer;

abstract AIRoom(TwoPlayersRoom) to TwoPlayersRoom {

	public function new(left:String = 'easy', right:String = 'easy') {
		this = new TwoPlayersRoom(setAIPlayer({position: LEFT}, left), setAIPlayer({position: RIGHT}, right));
	}
}
