package room;

import ai.AIFactory.ais;
import ai.AIFactory.getRandomAI;
import ai.AIFactory.setAIPlayer;
import menu.CongratScreen.CongratScreenType;
import menu.CongratScreen;

/**
	Room with two AI playing.
**/
class AIRoom extends TwoPlayersRoom {

	var endless:Bool;

	/**
		NOTE: If either ai is null, then random ai is chosen
		in a whay where no duplicates is possible.
		@param left 
		@param right 
		@param endless reset the score and re-enable AI so they can play forever
	**/
	public function new(left:String = null, right:String = null, endless:Bool = false) {

		if (left == null || right == null) {
			left = left ?? getRandomAI();

			var aiList = ais.copy();
			aiList.remove(left);
			right = getRandomAI(aiList);
		}

		super(setAIPlayer({position: LEFT}, left), setAIPlayer({position: RIGHT}, right));

		this.endless = endless;
	}

	override function create() {
		super.create();

		setGameParams();
		// re-init speedup to use new Pong.params
		ballSpeedup.init();
	}

	/**
		Set game params. Used to override game basics
		like ball speed or scores to win.
	**/
	function setGameParams() {
		// return;
		Pong.resetParams();
		Pong.params.scoreToWin = 3;
		Pong.params.ballSpeed *= 1.15;

		Flixel.watch.addQuick('P ${players[0].options.position}', players[0].options.name);
		Flixel.watch.addQuick('P ${players[1].options.position}', players[1].options.name);
	}

	override function showCongratScreen(player:Player, screenType:CongratScreenType) {
		if (endless) {
			// manually reset AI room state
			// so the AI could play enldessly

			for (player in players) {
				player.active = true;
				player.score = 0;
			}

			var leftAI = getRandomAI();
			tryReplaceAI(players[0], leftAI);

			// disallow the same ai twice
			var aiList = ais.copy();
			aiList.remove(leftAI);
			var rightAI = getRandomAI(aiList);
			tryReplaceAI(players[1], rightAI);

			setGameParams();
			ballSpeedup.init();
			return;
		}

		var playAgainAction = _ -> Flixel.switchState(new AIRoom(getRandomAI(), getRandomAI()));
		openSubState(new CongratScreen(playAgainAction).setWinner(player.name, screenType));
	}

	function tryReplaceAI(player:Player, aiType:String) {
		if (player.name.indexOf(aiType) == -1) {

			// if new AI is really new - dispose old
			var c = player.racketController;
			player.racketController = null;
			c.destroy();

			// use new
			// trace('new ai: $aiType ${player.racket.position}');
			player.racketController = setAIPlayer(player.options, aiType).getController(player.racket);
		}
	}
}
