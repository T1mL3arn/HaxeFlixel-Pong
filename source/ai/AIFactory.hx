package ai;

import Player.PlayerOptions;
import ai.SmartAI.SmartAIFactory;

final ais = ['easy', 'medium', 'hard', 'hardest'];

/**
	Returns random AI type
**/
inline function getRandomAI(?list:Array<String>) {
	return Flixel.random.getObject(list ?? ais);
}

function setAIPlayer(opts:PlayerOptions, aiType:String) {
	switch (aiType.toLowerCase()) {
		case 'medium' | 'normal':
			opts.name = 'medium AI (${opts.position})';
			opts.getController = racket -> SmartAIFactory.buildMediumAI(racket, opts.name);
		case 'hard':
			opts.name = 'hard AI (${opts.position})';
			opts.getController = racket -> SmartAIFactory.buildHardAI(racket, opts.name);
		case 'hardest':
			opts.name = 'hardest AI (${opts.position})';
			opts.getController = racket -> SmartAIFactory.buildHardestAI(racket, opts.name);
		default:
			opts.name = 'easy AI (${opts.position})';
			opts.getController = racket -> new SimpleAI(racket, opts.name);
	}
	return opts;
}
