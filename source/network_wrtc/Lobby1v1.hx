package network_wrtc;

import haxe.Exception;
import haxe.Json;
import Utils.merge;
import ai.SmartAI;
import flixel.FlxState;
import flixel.input.mouse.FlxMouseEvent;
import flixel.text.FlxText;
import flixel.util.FlxDirection;
import lime.system.Clipboard as LimeClipboard;
import menu.BaseMenu;
import menu.MainMenu;
import openfl.desktop.Clipboard;
#if html5
import js.Browser;
import js.html.Console;
import js.lib.Error;
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
	var menu:BaseMenu;
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

		menu = new BaseMenu(0, 0, 0, 5);
		menu.createPage('main')
			.add('
				-| create  | link | create_lobby
				-| join | link | connect_to_lobby
				-| __________ | label | 3 | U
				-| main menu | link | $SWITCH_TO_MAIN_MENU
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage('accept connection')
			.add('
				-| create | link | create_lobby | D | U |
				-| accept connection | link | accept_connection
				-| __________ | label | 3 | U
				-| main menu | link | $SWITCH_TO_MAIN_MENU
				')
			.par({
				pos: 'screen,c,c'
			});

		menu.createPage('connecting')
			.add('
				-| create | link | create_lobby | D | U |
				-| connecting | link | wait_connection | D | U |
				-| __________ | label | 3 | U
				-| main menu | link | $SWITCH_TO_MAIN_MENU
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

		menu.menuEvent.add((e, id) -> {
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
						infobox.text = 'Trying to join...';
						localPeer = connect(cast merge(peerOptions, {initiator: false}));
					}

					promptLobbyKey('connecting');

				case [it_fire, 'accept_connection']:
					promptLobbyKey();

				case [it_fire, SWITCH_TO_MAIN_MENU]:
					if (localPeer != null)
						localPeer?.destroy();
					Flixel.switchState(new MainMenu());

				default:
					0;
			}
		});
	}

	function buildInfoBox() {
		var margin = 12;
		var w = Flixel.width * 0.875;
		var h = Flixel.height * 0.25;
		var x = Flixel.width * 0.5 - w * 0.5;
		var y = Flixel.height - h - margin;
		var text = 'Create a lobby or join to one!';
		var infobox = new FlxText(x, y, w, text, 18);
		infobox.height = h;
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

	function copyToCLipboard(text:String) {
		Clipboard.generalClipboard.setData(TEXT_FORMAT, text);
		LimeClipboard.text = text;
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

			// copy data to clipboard when it is necessary
			switch ([connectionState, options.initiator]) {
				case [CreatingLobby, true] | [ConnectingToLobby, false]:
					copyToCLipboard(signalData);
					FlxMouseEvent.add(infobox, _ -> copyToCLipboard(signalData));
				case _: 0;
			}

			switch ([connectionState, options.initiator]) {
				case [CreatingLobby, true]:
					infobox.text = 'Connection ID is copied into clipboard. Share it with another player, then press "accept connection" and paste the player\'s response. Click here to copy ID again.';
					connectionState = LobbyCreated;

				case [ConnectingToLobby, false]:
					infobox.text = 'Connection ID is copied into clipboard. Share it with another player and wait a little. Click here to copy ID again.';

				default:
			}
		});

		peer.on('connect', () -> {
			trace('Connected!');
			connectionState = Connected;
			infobox.alignment = CENTER;
			infobox.text = "Connected!";

			// peer is an instance of EventEmitter
			// but the extern does not provide its methods,
			// so I use `untyped`
			untyped peer.removeAllListeners('error');
			untyped peer.removeAllListeners('signal');
			untyped peer.removeAllListeners('connect');
			untyped peer.removeAllListeners('close');

			var leftName = 'left';
			var leftUid = '$leftName#${FlxDirection.LEFT}';
			var leftController = options.initiator ? racket -> new NetplayRacketController(racket, leftUid) : r -> null;
			var rightName = 'right';
			var rightUid = '$rightName#${FlxDirection.RIGHT}';
			var rightController = options.initiator ? r -> null : racket -> new NetplayRacketController(racket, rightUid);

			// allows AI to play network game (for tests)
			//
			var leftController = if (options.initiator) {
				racket -> new NetplayAIRacketController(SmartAI.buildHardAI(racket, leftUid));
			}
			else {
				r -> null;
			}

			var rightController = if (options.initiator) {
				r -> null;
			}
			else {
				racket -> new NetplayAIRacketController(SmartAI.buildHardAI(racket, rightUid));
			}
			// -----

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
			}, Network.network = new Network(peer),
				// NOTE at this moment `server` is LEFT player.
				options.initiator ? leftUid : rightUid));
		});

		#if debug
		peer.on('close', () -> trace('connection is CLOSED'));
		#end

		return peer;
	}

	function promptLobbyKey(?menuPage:String) {
		var pastedData = Browser.window.prompt('Paste lobby key');
		if (pastedData == null || pastedData == '') {
			Browser.window.alert('You paste nothing, try again.');
		}
		else if (pastedData == signalData) {
			Browser.window.alert('You are pasting the same data, try again.');
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
		FlxMouseEvent.remove(infobox);

		super.destroy();
		timer?.stop();
	}
}
