package network_wrtc;

import Utils.merge;
import djFlixel.ui.FlxMenu;
import flixel.FlxState;
import haxe.Exception;
import haxe.Json;
import js.lib.Error;
import lime.system.Clipboard as LimeClipboard;
import menu.MainMenu;
import menu.MenuUtils.setDefaultMenuStyle;
import openfl.desktop.Clipboard;
import text.FlxText;
#if html5
import js.Browser;
import js.html.Console;
import peer.Peer;
import peer.PeerOptions;
#end

enum abstract ConnectionState(String) {
	var Initial;
	var CreatingLobby;
	var LobbyCreated;
	var ConnectingToLobby;
	var Connected;
}

class Lobby1v1 extends FlxState {

	var signalData:String;
	var menu:FlxMenu;
	var infobox:FlxText;
	var connectionState:ConnectionState = Initial;
	var timer:haxe.Timer;
	var switchToMainDelay:Int = 4000;

	#if html5
	var localPeer:Peer;

	override function create() {
		super.create();

		add(infobox = buildInfoBox());

		if (!Peer.WEBRTC_SUPPORT) {
			var msg = 'WebRTC is not supported!';
			trace(msg);
			infobox.alignment = CENTER;
			infobox.text = '$msg\nGoing back to Main menu...';
			haxe.Timer.delay(() -> Flixel.switchState(new MainMenu()), switchToMainDelay);
			return;
		}

		menu = new FlxMenu(0, 0, 0, 5);
		menu.createPage('main')
			.add('
				-| create  | link | create_lobby
				-| connect | link | connect_to_lobby
				-| __________ | label | 3 | U
				-| main menu | link | open_main_menu
				')
			.par({
				pos: 'screen,c,c'
			});

		setDefaultMenuStyle(menu);

		menu.createPage('accept connection')
			.add('
				-| create | link | create_lobby | D | U |
				-| accept connection | link | accept_connection
				-| __________ | label | 3 | U
				-| main menu | link | open_main_menu
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage('connecting')
			.add('
				-| create | link | create_lobby | D | U |
				-| connecting | link | wait_connection | D | U |
				-| __________ | label | 3 | U
				-| main menu | link | open_main_menu
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.goto('main');
		add(menu);

		var iceCompleteTimeout = 2 * 60 * 1000;

		var peerOptions = {
			initiator: false,
			trickle: false,
			stream: false,
			iceCompleteTimeout: iceCompleteTimeout,
			// config: {
			// 	// NOTE: iceServers from PeerJS library
			// 	// https://github.com/peers/peerjs/blob/f52cb0c661d1cbaac78a64a5253b3eef03d4dd81/lib/util.ts#L36
			// 	iceServers: untyped [
			// 		{urls: ["stun:stun.l.google.com:19302", "stun:global.stun.twilio.com:3478"]},
			// 		{
			// 			urls: ["turn:eu-0.turn.peerjs.com:3478", "turn:us-0.turn.peerjs.com:3478"],
			// 			username: "peerjs",
			// 			credential: "peerjsp",
			// 		},
			// 	],
			// },
		};

		menu.onMenuEvent = (e, id) -> {
			switch ([e, id]) {
				case [it_fire, 'create_lobby']:
					if (localPeer == null) {
						infobox.text = 'Creating lobby...';
						connectionState = CreatingLobby;
						localPeer = connect(cast merge(peerOptions, {initiator: true}));
					}

					menu.goto('accept connection');

				case [it_fire, 'connect_to_lobby']:
					if (localPeer == null) {
						connectionState = ConnectingToLobby;
						infobox.text = 'Trying to connect...';
						localPeer = connect(cast merge(peerOptions, {initiator: false}));
					}

					promptLobbyKey('connecting');

				case [it_fire, 'accept_connection']:
					promptLobbyKey();

				case [it_fire, 'open_main_menu']:
					if (localPeer != null)
						localPeer.destroy();
					Flixel.switchState(new MainMenu());

				default:
					0;
			}
		}
	}

	function buildInfoBox() {
		var margin = 12;
		var w = Flixel.width * 0.875;
		var h = Flixel.height * 0.25;
		var x = Flixel.width * 0.5 - w * 0.5;
		var y = Flixel.height - h - margin;
		var text = 'Create a lobby or connect to one!';
		var infobox = new text.FlxText(x, y, w, h, text, 18);
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

	function connect(?options:PeerOptions) {
		var peer = new Peer(options);

		peer.on('error', (err:Error) -> {
			Console.error(err);

			localPeer?.destroy();
			infobox.text = 'Error: ${err.message}\nGoing back to Main menu...';
			timer = haxe.Timer.delay(() -> Flixel.switchState(new MainMenu()), switchToMainDelay);
		});

		peer.on('signal', data -> {
			signalData = Json.stringify(data);
			trace('\nsignal data:\n$signalData');
			Clipboard.generalClipboard.setData(TEXT_FORMAT, signalData);
			LimeClipboard.text = signalData;

			switch ([connectionState, options.initiator]) {
				case [CreatingLobby, true]:
					infobox.text = 'Connection ID is copied into clipboard. Share it with another player, then press "accept connection" and paste the player\'s response';
					connectionState = LobbyCreated;

				case [ConnectingToLobby, false]:
					infobox.text = 'Connection ID is copied into clipboard. Share it with another player and wait a little.';

				default:
			}
		});

		peer.on('connect', () -> {
			trace('Connected!');
			connectionState = Connected;
			infobox.alignment = CENTER;
			infobox.text = "Connected!";
		});

		peer.on('close', () -> trace('connection is CLOSED'));

		return peer;
	}

	function promptLobbyKey(?menuPage:String) {
		var pastedData = Browser.window.prompt('Paste lobby key');
		if (pastedData == signalData) {
			Browser.window.alert('You are pasting the same data, try again!');
		}
		else {
			try {
				var parsedData = Json.parse(pastedData);
				localPeer.signal(parsedData);
				if (menuPage != null)
					menu.goto(menuPage);
			}
			catch (err:String) {
				infobox.text = 'Error: $err';
				Console.error(err);
			}
			catch (err:Exception) {
				infobox.text = 'Error: ${err.message}';
				Console.error(err.message);
			}
		}
	}
	#end

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function destroy() {
		super.destroy();

		timer?.stop();
	}
}
