package menu;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;
import menu.BaseMenu.MenuCommand;
import text.FlxText;

using menu.MenuUtils;

enum abstract CongratScreenType(Bool) to Bool {
	var FOR_WINNER = true;
	var FOR_LOOSER = false;
}

class CongratScreen extends FlxSubState {

	var winnerName:String = 'Unknown';
	var winnerLabel:FlxText;
	var screenType:Bool = true;
	var winnerSprite:WinnerSprite;
	var looserSprite:WinnerSprite;
	var playAgainMenuAction:CongratScreen->Void;

	public function new(?playAgainMenuAction) {
		super(0xEE000000);
		this.playAgainMenuAction = playAgainMenuAction;
	}

	public function setWinner(name:String, screenType:CongratScreenType = FOR_WINNER):CongratScreen {
		winnerName = name;
		this.screenType = screenType;
		return this;
	}

	override function destroy() {
		super.destroy();

		if (winnerSprite.exists)
			winnerSprite.destroy();
		if (looserSprite.exists)
			looserSprite.destroy();
	}

	override function create() {
		super.create();

		winnerSprite = new WinnerSprite();
		looserSprite = new WinnerSprite(false);

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
				case [it_fire, 'again']:
					if (playAgainMenuAction != null) playAgainMenuAction(this);
				default:
			}
		});

		openCallback = () -> {
			remove(winnerSprite);
			remove(looserSprite);

			var sprite = switch (screenType) {
				case FOR_WINNER: winnerSprite;
				case FOR_LOOSER: looserSprite;
			}
			sprite.setWinnerName(winnerName);
			add(sprite);
			trace('winner screen is open');
		}

		openCallback();
	}
}

class WinnerSprite extends FlxSpriteGroup {

	var winnerLabel:FlxText;
	var isWinner:Bool;

	@:access(FlxTypedSpriteGroup)
	public function new(isWinner:Bool = true) {
		super();
		this.isWinner = isWinner;

		var congratText = isWinner ? 'Congratulations!' : 'GAME OVER';
		var congrats = new FlxText(congratText);
		congrats.size = 32;
		congrats.screenCenter(X);
		add((cast congrats : FlxSprite));

		var nextY = congrats.height + congrats.y;

		if (isWinner) {
			var cup = new FlxSprite();
			cup.loadGraphic(AssetPaths.cup__png);
			cup.scale.set(2, 2);
			cup.updateHitbox();
			cup.screenCenter();
			cup.y = nextY + 20;
			add(cup);
			nextY = cup.y + cup.height;
		}

		winnerLabel = new FlxText('winner: unknown');
		winnerLabel.size = 24;
		winnerLabel.screenCenter(X);
		winnerLabel.y = nextY + 20;
		add(winnerLabel);
		nextY = winnerLabel.y + winnerLabel.height;

		var line = new FlxSprite();
		var w = Math.floor(Flixel.width * 0.75);
		line.makeGraphic(w, 4);
		FlxSpriteUtil.drawRect(line, 0, 0, w, 4, FlxColor.WHITE);
		line.screenCenter(X);
		line.y = nextY + 25;
		add(line);

		// Since the items are place in screen center
		// I need to fix sprite group position.
		var dx = -findMinX();
		var dy = -findMinY();
		// due to this shit https://github.com/HaxeFoundation/haxe/issues/10635
		// I cant call multiTransformChildren()
		// multiTransformChildren([xTransform, yTransform], [dx, dy]);
		// TODO ask on Haxe gitbug about it?
		transformChildren(xTransform, dx);
		transformChildren(yTransform, dy);

		screenCenter(X);
		y = Flixel.height * (isWinner ? 0.075 : 0.15);
	}

	public function setWinnerName(name:String) {
		// TODO make `maxlen` into top-level const
		var maxlen = 15;
		winnerLabel.text = 'winner: ${name.substr(0, maxlen)}';
		winnerLabel.screenCenter(X);
	}
}
