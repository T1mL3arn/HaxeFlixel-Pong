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
import openfl.desktop.Clipboard;
import state.BaseState;
import ui.HostInput;
import network_wrtc.Network.INetplayPeer;
import network_wrtc.TwoPlayerNew.TwoPlayerRoomNew;
#if html5
import peer.Peer;
import network_wrtc.PeerWebRTC;
#end
#if (hl || neko)
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
	var peer:INetplayPeer<Any>;

	var timer:haxe.Timer;
	var hostInput:HostInput;

	public function new() {
		super();
	}

	override function create() {

		GAME.peer?.destroy();
		GAME.peer = null;

		super.create();

		canPause = false;

		uiObjects.add(infobox = buildInfoBox());

		uiObjects.add(hostInput = new HostInput().setPos(infobox.x, infobox.y));
		#if !desktop
		hostInput.visible = false;
		hostInput.active = false;
		#end

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
					hostInput.active = false;

					peer = getPeer();
					peer.create(GAME.host.address, Std.parseInt(GAME.host.port));

				case [it_fire, 'connect_to_lobby']:
					//
					hostInput.active = false;

					peer = getPeer();
					peer.join(GAME.host.address, Std.parseInt(GAME.host.port));

				case [it_fire, SWITCH_TO_MAIN_MENU]:
					Flixel.switchState(new MainMenu());

				default:
			}
		});

		// placing host input at the right coords
		var menuTop = menu.mpActive.findMinY();
		hostInput.screenCenter(X);
		hostInput.y = menuTop - hostInput.height - 10;

		#if (debug && desktop)
		new FlxTimer().start(0.1, t -> {
			var isClient = Sys.args().contains('--client');
			if (isClient) {
				peer = getPeer();
				peer.join(GAME.host.address, Std.parseInt(GAME.host.port));
			}
			else {
				// peer = getPeer();
				// peer.create(GAME.host.address, Std.parseInt(GAME.host.port));
			}
		});
		#end
	}

	function getPeer():INetplayPeer<Any> {
		peer?.destroy();
		peer = null;

		#if (hl || neko)
		peer = new PeerIP();
		#elseif html5
		peer = new PeerWebRTC();
		#end

		peer.onConnect.addOnce(onPeerConnected);
		peer.onError.addOnce(onPeerError);
		peer.onDisconnect.addOnce(onPeerDisconnect);

		// set it to GAME just when it is created
		GAME.peer = peer;

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

		styleText(infobox);

		return infobox;
	}

	function styleText<T:FlxText>(text:T):T {
		var margin = 12;
		var fontSize = 18;
		text.size = fontSize;
		text.color = 0x111111;
		text.alignment = LEFT;
		text.textField.background = true;
		text.textField.backgroundColor = 0xEEEEEE;
		@:privateAccess
		var format = text._defaultFormat;
		format.leftMargin = format.rightMargin = margin;
		@:privateAccess text.updateDefaultFormat();
		return text;
	}

	function onPeerError(e:Dynamic) {

		var msg:Any = '';
		try {
			msg = e.message ?? e;
		}
		catch (_) {
			trace('error getting another error message ~_~');
			trace(_);
			msg = e;
		}

		connectionState = Initial;
		infobox.text = 'Error: ${msg}';
		menu.goto(cast LobbyMenuPage.Initial);
		hostInput.active = true;
	}

	function onPeerDisconnect() {
		connectionState = Initial;
		infobox.text = 'Disconnected';
		menu.goto(cast LobbyMenuPage.Initial);
		hostInput.active = true;
	}

	function onPeerConnected() {
		#if desktop
		hostInput.alpha = 0.5;
		#end
		connectionState = Connected;
		infobox.alignment = CENTER;
		infobox.text = "Connected!";

		var leftName = 'left';
		var leftUid = '$leftName#${FlxDirection.LEFT}';
		var leftController = peer.isServer ? racket -> new NetplayRacketController(racket, leftUid) : r -> null;
		var rightName = 'right';
		var rightUid = '$rightName#${FlxDirection.RIGHT}';
		var rightController = peer.isServer ? r -> null : racket -> new NetplayRacketController(racket, rightUid);

		#if debug
		// allows AI to play network game (for tests)
		// NOTE: due to how netplay is done (very badly)
		// client-ai don't get all neccesary info (server-ai is fine)
		// thus in netplay it sometimes behaves not adequately.
		var leftController = if (peer.isServer) {
			racket -> new NetplayAIRacketController(SmartAIFactory.buildHardestAI(racket, leftUid));
		}
		else {
			r -> null;
		}

		var rightController = if (peer.isServer) {
			r -> null;
		}
		else {
			racket -> new NetplayAIRacketController(SmartAIFactory.buildMediumAI(racket, rightUid));
		}
		// -----
		#end

		// TODO: delay before game starts
		// tweenManager.tween(this, {}, 1.0).then()

		Flixel.switchState(new TwoPlayerRoomNew({
			name: leftName,
			uid: leftUid,
			position: LEFT,
			getController: leftController
		}, {
			name: rightName,
			uid: rightUid,
			position: RIGHT,
			getController: rightController,
		}));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function destroy() {
		FlxMouseEvent.remove(infobox);

		super.destroy();
		// since peer can be used in other state
		// I cannot destroy it here but have to remove listenrs
		peer?.onConnect.removeAll();
		peer?.onError.removeAll();
		peer?.onDisconnect.removeAll();
		timer?.stop();
	}
}
