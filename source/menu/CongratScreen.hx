package menu;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;
import menu.BaseMenu.MenuCommand;
import text.FlxText;

using menu.MenuUtils;

class CongratScreen extends FlxSubState {

	var winnerName:String = 'Unknown';
	var winnerLabel:FlxText;
	var forWinner:Bool = true;

	public function setWinner(name:String, forWinner:Bool = true):CongratScreen {
		winnerName = name;
		this.forWinner = forWinner;
		return this;
	}

	override function create() {
		super.create();

		var congrats = new FlxText('Congratulations!');
		congrats.size = 32;
		congrats.screenCenter(X);
		congrats.y = Flixel.height * 0.075;
		add(congrats);

		var cup = new FlxSprite();
		cup.loadGraphic(AssetPaths.cup__png);
		cup.scale.set(2, 2);
		cup.updateHitbox();
		cup.screenCenter();
		cup.y = congrats.height + congrats.y + 20;
		add(cup);

		winnerLabel = new FlxText();
		winnerLabel.size = 24;
		winnerLabel.screenCenter(X);
		winnerLabel.y = cup.y + cup.height + 20;
		add(winnerLabel);

		var line = new FlxSprite();
		var w = Math.floor(Flixel.width * 0.75);
		line.makeGraphic(w, 4);
		FlxSpriteUtil.drawRect(line, 0, 0, w, 4, FlxColor.WHITE);
		line.screenCenter(X);
		line.y = winnerLabel.y + winnerLabel.height + 25;
		add(line);

		var bottomPadding = -Flixel.height * #if !html5 0.05 #else 0.1 #end;
		var menu = new BaseMenu(0, 0, 0, 4);
		menu.createPage('main')
			.add('
			-| play again | link | again
			-| main menu | link | $SWITCH_TO_MAIN_MENU
		')
			.addExitGameItem()
			.par({
				pos: 'screen,c,b',
				y: bottomPadding,
			});

		menu.goto('main');
		add(menu);

		menu.menuEvent.add((e, pageId) -> {
			switch ([e, pageId]) {
				case [it_fire, SWITCH_TO_MAIN_MENU]:
					Flixel.switchState(new MainMenu());
				default:
			}
		});

		openCallback = () -> {
			// TODO make `maxlen` into top-level const
			var maxlen = 15;
			winnerLabel.text = 'winner: ${winnerName.substr(0, maxlen)}';
			winnerLabel.screenCenter(X);
		}

		// TODO state has params controlling how "play again" works
		// TODO this screen works differently for winner and looser
	}

	function getWinnerScreen() {
		//
	}

	function getLooserScreen() {
		//
	}
}
