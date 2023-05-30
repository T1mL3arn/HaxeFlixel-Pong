package menu;

import djFlixel.ui.FlxMenu;
import djFlixel.ui.IListItem.ListItemEvent;
import djFlixel.ui.menu.MItemData;
import flixel.util.FlxSignal;
import lime.app.Application;
import menu.MenuUtils.setDefaultMenuStyle;

enum abstract MenuCommand(String) to String {
	var EXIT_GAME;
	var SWITCH_TO_MAIN_MENU;
}

typedef MenuEventHandler = (MenuEvent, String)->Void;
typedef MenuItemEventHandler = (ListItemEvent, MItemData)->Void;

@:forward
abstract BaseMenu(BaseMenuImpl) to BaseMenuImpl {

	@:deprecated('Add menu listeners to `menuEvent` property instead')
	public var onMenuEvent(get, set):MenuEventHandler;

	inline function get_onMenuEvent():MenuEventHandler
		throw '';

	inline function set_onMenuEvent(v):MenuEventHandler
		throw '';

	@:deprecated('Add item listeners to `itemEvent` property instead')
	public var onItemEvent(get, set):MenuItemEventHandler;

	inline function get_onItemEvent():MenuItemEventHandler
		throw '';

	inline function set_onItemEvent(v):MenuItemEventHandler
		throw '';

	public inline function new(x = 0, y = 0, width = 0, slots = 6) {
		this = new BaseMenuImpl(x, y, width, slots);
	}
}

private class BaseMenuImpl extends FlxMenu {

	public var menuEvent(default, null):FlxTypedSignal<MenuEventHandler>;
	public var itemEvent(default, null):FlxTypedSignal<MenuItemEventHandler>;

	public function new(x = 0, y = 0, width = 0, slots = 6) {
		super(x, y, width, slots);
		PAR.start_button_fire = true;
		setDefaultMenuStyle(this);
		menuEvent = new FlxTypedSignal();
		onMenuEvent = (e, pageId) -> menuEvent.dispatch(e, pageId);
		itemEvent = new FlxTypedSignal();
		onItemEvent = (e, data) -> itemEvent.dispatch(e, data);

		#if !html5
		menuEvent.add((e, pageId) -> {
			if (e == it_fire && pageId == EXIT_GAME)
				Application.current.window.close();
		});
		#end
	}

	override function destroy() {
		super.destroy();

		menuEvent.removeAll();
		itemEvent.removeAll();
	}
}
