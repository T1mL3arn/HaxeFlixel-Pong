package ai;

import Player.PlayerOptions;

function setAIPlayer(opts:PlayerOptions, aiType:String) {
	switch (aiType) {
		case 'medium':
			opts.name = 'medium AI';
			opts.getController = racket -> new SimpleAI(racket);
		case 'hard':
			opts.name = 'medium AI';
			opts.getController = racket -> new SimpleAI(racket);
		default:
			opts.name = 'easy AI';
			opts.getController = racket -> new NotSoSimpleAI(racket);
	}
	return opts;
}
