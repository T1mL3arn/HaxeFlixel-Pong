package menu;

import djFlixel.ui.FlxMenu;
import network_wrtc.Lobby1v1;
import state.BaseState;
import menu.BaseMenu;
import menu.MenuUtils.wrapMenuPage;

using menu.MenuUtils;

@:forward
abstract NetplayErrorMenu(menu.BaseMenu) to FlxMenu {

	//
	public inline function new(title:String) {
		this = new BaseMenu(0, 0, 0, 10);

		this.createPage('main')
			.add(wrapMenuPage(title, '
			-| go to menu | link | go_to_menu
			', ''))
			.addExitGameItem()
			.par({
				pos: 'screen,c,c'
			});

		this.goto('main');
	}
}

class NetplayDisconnectedScreen extends BaseState {

	var reason:String;
	var details:String;

	public function new(reason:String, ?details:String) {
		super();
		this.reason = reason;
		this.details = details;

		openCallback = () -> {
			_parentState.persistentUpdate = false;
		}
	}

	override function create() {
		super.create();

		bgColor = 0xBB000000;

		var menu = new NetplayErrorMenu(reason);
		menu.itemEvent.add((e, data) -> {
			switch ([e, data.ID]) {
				case [fire, 'go_to_menu']:
					Flixel.switchState(new Lobby1v1());
				case _:
			}
		});

		uiObjects.add(menu);
	}
}
