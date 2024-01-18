package network_wrtc;

import haxe.Json;
import Utils.merge;
import ai.SmartAI;
import flixel.FlxBasic;
import flixel.FlxState;
import flixel.input.mouse.FlxMouseEvent;
import flixel.text.FlxText;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxDirection;
import flixel.util.FlxTimer;
import lime.system.Clipboard as LimeClipboard;
import menu.BaseMenu;
import menu.MainMenu;
import mod.Updater;
import openfl.desktop.Clipboard;
import state.BaseState;
import network_wrtc.Network.INetplayPeer;
#if html5
import peer.Peer;
import network_wrtc.PeerWebRTC;
#end
#if hl
import network_direct.PeerIP;
#end

typedef Error = #if html5 js.lib.Error #else haxe.Exception #end;

enum abstract ConnectionState(String) {
	var Initial;
	var CreatingLobby;
	var LobbyCreated;
	var ConnectingToLobby;
	var ConnectingToPeer;
	var Connected;
}

enum abstract LobbyMenuPage(String) to String {
	var Initial;
	var CreatingLobby;
	var JoiningToLobby;
	var AcceptConnection;
	var Connecting;
}

class Lobby1v1 extends BaseState {

	var connectionState:ConnectionState = Initial;
	var menu:BaseMenu;
	var infobox:FlxText;
	var peer:INetplayPeer;

	var timer:haxe.Timer;

	override function create() {
		super.create();

		canPause = false;

		var updatable = new Updater();
		plugins.add(updatable);

		uiObjects.add(infobox = buildInfoBox());

		#if html5
		// To test it in Firefox set `media.peerconnection.enabled=false`
		// on about:config page
		if (!Peer.WEBRTC_SUPPORT) {
			var msg = 'WebRTC is not supported!';
			trace(msg);
			infobox.alignment = CENTER;
			infobox.text = '$msg\nGoing back to Main menu...';
			final switchToMainDelay:Int = 4000;
			timer = haxe.Timer.delay(() -> Flixel.switchState(new MainMenu()), switchToMainDelay);
			return;
		}
		#end

		menu = new BaseMenu(0, 0, 0, 5);
		menu.createPage(LobbyMenuPage.Initial)
			.add('
				-| create  | link | create_lobby
				-| join | link | connect_to_lobby
				-| __________ | label | 3 | U
				-| main menu | link | $SWITCH_TO_MAIN_MENU
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage(LobbyMenuPage.Connecting)
			.add('
				-| create | link | create_lobby | D | U |
				-| connecting | link | wait_connection | D | U |
				-| __________ | label | 3 | U
				-| main menu | link | $SWITCH_TO_MAIN_MENU
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage(LobbyMenuPage.CreatingLobby)
			.add('
				-| creating | link | create_lobby | D | U |
				-| join | link | wait_connection | D | U |
				-| __________ | label | 3 | U
				-| main menu | link | $SWITCH_TO_MAIN_MENU
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage(LobbyMenuPage.JoiningToLobby)
			.add('
				-| create | link | create_lobby | D | U |
				-| joining | link | wait_connection | D | U |
				-| __________ | label | 3 | U
				-| main menu | link | $SWITCH_TO_MAIN_MENU
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.goto(cast LobbyMenuPage.Initial);
		uiObjects.add(menu);

		menu.menuEvent.add((e, id) -> {
			switch ([e, id]) {
				case [it_fire, 'create_lobby']:
					//
					updatable.clear();

					peer = getPeer();
					peer.create();

					updatable.add(peer.loop);

				case [it_fire, 'connect_to_lobby']:
					//
					updatable.clear();

					peer = getPeer();
					// NOTE: temporary pass bullshit to join
					peer.join('', 0);

					updatable.add(peer.loop);

				case [it_fire, SWITCH_TO_MAIN_MENU]:
					peer?.destroy();
					Flixel.switchState(new MainMenu());

				default:
			}
		});
	}

	function getPeer():INetplayPeer {
		peer?.destroy();
		peer = null;

		#if hl
		peer = new PeerIP();
		#elseif html5
		peer = new PeerWebRTC();
		#end

		peer.onConnect.addOnce(onPeerConnected);
		peer.onError.addOnce(onPeerError);
		peer.onDisconnect.addOnce(onPeerDisconnect);

		return peer;
	}

	function buildInfoBox() {
		var margin = 12;
		var w = Flixel.width * 0.875;
		var h = Flixel.height * 0.25;
		var x = Flixel.width * 0.5 - w * 0.5;
		var y = Flixel.height - h - margin;
		var text = 'Create a lobby or join to one!';
		var infobox = new FlxText(x, y, w, text, 18);
		infobox.fieldHeight = h;
		infobox.color = 0x111111;
		infobox.alignment = LEFT;
		infobox.textField.background = true;
		infobox.textField.backgroundColor = 0xEEEEEE;

		@:privateAccess
		var format = infobox._defaultFormat;
		format.leftMargin = format.rightMargin = margin;
		@:privateAccess infobox.updateDefaultFormat();

		return infobox;
	}

	function onPeerError(e:Dynamic) {
		peer.destroy();

		connectionState = Initial;
		infobox.text = 'Error: ${e.message ?? e}';
		menu.goto(cast LobbyMenuPage.Initial);
	}

	function onPeerDisconnect() {
		connectionState = Initial;
		infobox.text = 'Disconnected';
		menu.goto(cast LobbyMenuPage.Initial);
	}

	function onPeerConnected() {
		connectionState = Connected;
		infobox.alignment = CENTER;
		infobox.text = "Connected!";

		// TODO: delay before game starts
		// tweenManager.tween(this, {}, 1.0).then()

		var leftName = 'left';
		var leftUid = '$leftName#${FlxDirection.LEFT}';
		var leftController = peer.isServer ? racket -> new NetplayRacketController(racket, leftUid) : r -> null;
		var rightName = 'right';
		var rightUid = '$rightName#${FlxDirection.RIGHT}';
		var rightController = peer.isServer ? r -> null : racket -> new NetplayRacketController(racket, rightUid);

		#if debug
		// allows AI to play network game (for tests)
		//
		var leftController = if (peer.isServer) {
			racket -> new NetplayAIRacketController(SmartAI.buildHardAI(racket, leftUid));
		}
		else {
			r -> null;
		}

		var rightController = if (peer.isServer) {
			r -> null;
		}
		else {
			racket -> new NetplayAIRacketController(SmartAI.buildHardAI(racket, rightUid));
		}
		// -----
		#end

		Network.network = peer;

		Flixel.switchState(new network_wrtc.TwoPlayersRoom({
			name: leftName,
			uid: leftUid,
			position: LEFT,
			getController: leftController
		}, {
			name: rightName,
			uid: rightUid,
			position: RIGHT,
			getController: rightController,
		}, // ---
			// NOTE at this moment `server` is LEFT player.
			peer.isServer ? leftUid : rightUid));
		//
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function destroy() {
		FlxMouseEvent.remove(infobox);

		super.destroy();
		timer?.stop();
	}
}
