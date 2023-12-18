package room;

import ai.AIFactory.setAIPlayer;
import menu.CongratScreen.CongratScreenType;
import menu.CongratScreen;

class AIRoom extends TwoPlayersRoom {

	var endless:Bool;

	public function new(left:String = null, right:String = null, endless:Bool = false) {

		left = left ?? getRandomAi();
		right = right ?? getRandomAi();

		super(setAIPlayer({position: LEFT}, left), setAIPlayer({position: RIGHT}, right));

		this.endless = endless;
	}

	inline function getRandomAi() {
		return Flixel.random.getObject(['easy', 'medium', 'hard']);
	}

	override function create() {
		super.create();

		Flixel.watch.addQuick('left', leftOptions.name);
		Flixel.watch.addQuick('right', rightOptions.name);

		setGameParams();
		// re-init speedup to use new Pong.params
		ballSpeedup.init();
	}

	function setGameParams() {
		Pong.resetParams();
		Pong.params.scoreToWin = 3;
		Pong.params.ballSpeed *= 1.15;
	}

	override function showCongratScreen(player:Player, screenType:CongratScreenType) {
		if (endless) {
			// re-enable AI players
			for (player in players) {
				player.active = true;
				player.score = 0;
			}
			setGameParams();
			ballSpeedup.init();
			return;
		}

		var playAgainAction = _ -> Flixel.switchState(new AIRoom(getRandomAi(), getRandomAi()));
		openSubState(new CongratScreen(playAgainAction).setWinner(player.name, screenType));
	}
}
