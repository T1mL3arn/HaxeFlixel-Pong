package netplay;

import menu.BaseMenu.MenuCommand;
import menu.CongratScreen;
import netplay.NetplayPeer.INetplayPeer;

/**
	This congrat screen disables "play again" menu item
	for non-server player, so the only server can choose 
	to "play again".
**/
class NetplayCongratScreen extends CongratScreen {

	public var isServer:Bool = false;
	public var network:INetplayPeer<Any>;

	override function create() {
		super.create();

		// disable "play again" for non-server
		if (!isServer) {
			var itemData = menu.pages['main'].get('again');
			itemData.disabled = true;
			itemData.selectable = false;
			menu.mpActive.item_update(itemData);
			menu.mpActive.item_focus(MenuCommand.SWITCH_TO_MAIN_MENU);
		}

		// TODO review how simple-peer CLOSE event relates to anette lib

		errorHandler = _ -> onDisconnect('error');
		disconnectHandler = () -> onDisconnect('disconnected');
		network.onError.addOnce(errorHandler);
		network.onDisconnect.addOnce(disconnectHandler);
	}

	var disconnectHandler:()->Void;
	var errorHandler:Any->Void;

	function onDisconnect(?reason = 'disconnected') {

		network.onError.remove(errorHandler);
		network.onDisconnect.remove(disconnectHandler);

		// disable "play again" if second user disconnected during CongratScreen
		// show "user disconnected" info if user disconnects during CongratScreen
		var itemData = menu.pages['main'].get('again');
		itemData.disabled = true;
		itemData.selectable = false;
		itemData.label = reason;
		menu.mpActive.item_update(itemData);
		menu.mpActive.item_focus(MenuCommand.SWITCH_TO_MAIN_MENU);
		// re-align menu items
		menu.mpActive.setDataSource(menu.mpActive.page.items);
	}

	override function destroy() {
		super.destroy();

		network.onError.remove(errorHandler);
		network.onDisconnect.remove(disconnectHandler);
		network = null;
	}
}
