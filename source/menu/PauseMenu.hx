package menu;

import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import lime.app.Application;
import menu.BaseMenu.MenuCommand;

using menu.MenuUtils;

@:build(utils.BuildMacro.addField_GAME())
class PauseMenu extends FlxSubState {

	var stateJustOpenned:Bool = false;

	public function new() {
		super(0xBB000000);
	}

	override function create() {

		var menu = new BaseMenu(0, 0, 0);

		menu.createPage('main')
			.add('
			-| resume | link | resume
			-| main menu | link | $SWITCH_TO_MAIN_MENU
		')
			.addExitGameItem()
			.par({
				pos: 'screen,c,c'
			});

		menu.goto('main');

		menu.menuEvent.add((e, id) -> {
			switch ([e, id]) {
				case [it_fire, 'resume']:
					this.close();

				case [it_fire, SWITCH_TO_MAIN_MENU]:
					Flixel.switchState(new MainMenu());

				default:
					0;
			}
		});

		add(menu);

		openCallback = () -> {
			stateJustOpenned = true;
			GAME.aiTweens.active = false;
		};
		closeCallback = () -> GAME.aiTweens.active = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!stateJustOpenned && Flixel.keys.anyJustPressed([ESCAPE, P]))
			this.close();

		stateJustOpenned = false;
	}
}
