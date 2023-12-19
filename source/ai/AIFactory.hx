package ai;

import Player.PlayerOptions;

final ais = ['easy', 'medium', 'hard'];

/**
	Returns random AI type
**/
inline function getRandomAI() {
	return Flixel.random.getObject(ais);
}

function setAIPlayer(opts:PlayerOptions, aiType:String) {
	switch (aiType) {
		case 'medium':
			opts.name = 'medium AI (${opts.position})';
			opts.getController = racket -> NotSoSimpleAI.buildMediumAI(racket, opts.name);
		case 'hard':
			opts.name = 'hard AI (${opts.position})';
			opts.getController = racket -> new SimpleAI(racket);
		default:
			opts.name = 'easy AI (${opts.position})';
			opts.getController = racket -> NotSoSimpleAI.buildEasyAI(racket, opts.name);
	}
	return opts;
}
