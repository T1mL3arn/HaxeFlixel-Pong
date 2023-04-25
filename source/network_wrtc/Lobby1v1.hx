package network_wrtc;

import Utils.merge;
import djFlixel.ui.FlxMenu;
import flixel.FlxState;
import haxe.Json;
import lime.system.Clipboard as LimeClipboard;
import menu.MainMenu;
import menu.MenuStyle.setDefaultMenuStyle;
import openfl.desktop.Clipboard;
import peer.PeerOptions;
#if html5
import js.Browser;
import js.html.Console;
import peer.Peer;
#end

class Lobby1v1 extends FlxState {

	var signalData:String;
	var menu:FlxMenu;

	#if html5
	var localPeer:Peer;
	var remotePeer:Peer;

	override function create() {
		super.create();

		if (!Peer.WEBRTC_SUPPORT) {
			var msg = 'WebRTC is not supported!';
			trace(msg);
			Flixel.log.warn(msg);
			Flixel.switchState(new MainMenu());
			return;
		}

		menu = new FlxMenu(0, 0, -1, 5);
		menu.createPage('main')
			.add('
				-| create  | link | create_lobby
				-| connect | link | connect_to_lobby
				-| __________ | label | 3 | U
				-| main menu | link | open_main_menu
				')
			.par({
				pos: 'screen,l,c'
			});

		setDefaultMenuStyle(menu);

		menu.createPage('accept connection')
			.add('
				-| create lobby | link | create_lobby | D | U |
				-| accept connection | link | accept_connection
				-| __________ | label | 3 | U
				-| main menu | link | open_main_menu
				')
			.par({
				pos: 'screen,l,c'
			});

		menu.createPage('connecting')
			.add('
				-| create lobby | link | create_lobby | D | U |
				-| connecting | link | wait_connection | D | U |
				-| __________ | label | 3 | U
				-| main menu | link | open_main_menu
				')
			.par({
				pos: 'screen,l,c'
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
						localPeer = connect(untyped merge(peerOptions, {initiator: true}));
					}

					menu.goto('accept connection');

				case [it_fire, 'connect_to_lobby']:
					if (localPeer == null) {
						localPeer = connect(untyped merge(peerOptions, {initiator: false}));
					}

					var pastedData = Browser.window.prompt('Paste room id');
					if (pastedData == signalData) {
						Browser.window.alert('You are pasting the same data, try again!');
					}
					else {
						try {
							var parsedData = Json.parse(pastedData);
							localPeer.signal(parsedData);
						}
						catch (err) {
							Console.error(err);
						}
					}

					menu.goto('connecting');

				case [it_fire, 'accept_connection']:
					var pastedData = Browser.window.prompt('Paste room id');
					if (pastedData == signalData) {
						Browser.window.alert('You are pasting the same data, try again!');
					}
					else {
						try {
							var parsedData = Json.parse(pastedData);
							localPeer.signal(parsedData);
						}
						catch (err) {
							Console.error(err);
						}
					}

				case [it_fire, 'open_main_menu']:
					if (localPeer != null)
						localPeer.destroy();
					Flixel.switchState(new MainMenu());

				default:
					0;
			}
		}
	}

	function connect(?options:PeerOptions) {
		var peer = new Peer(options);

		peer.on('error', err -> {
			trace('error');
			Console.error(err.code, err);
		});

		peer.on('signal', data -> {
			data = Json.stringify(data);
			trace('SIGNAL\n$data');
			signalData = data;
			Clipboard.generalClipboard.setData(TEXT_FORMAT, data);
			LimeClipboard.text = data;
			trace('Data is copied into clipboard');
		});

		peer.on('connect', () -> {
			trace('Connected!');
			peer.send('Hello from ${untyped peer.initiator ? 'initiator' : 'peer'}');
		});

		peer.on('data', data -> {
			trace('Recieved data: ${data}');
		});

		peer.on('close', () -> trace('connection is CLOSED'));

		return peer;
	}
	#end

	override function update(elapsed:Float) {
		super.update(elapsed);
	}
}
