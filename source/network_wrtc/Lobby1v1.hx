package network_wrtc;

import djFlixel.ui.FlxMenu;
import haxe.Json;
import lime.system.Clipboard as LimeClipboard;
import menu.MainMenu;
import menu.MenuStyle;
import openfl.desktop.Clipboard;
import peer.PeerOptions;
#if html5
import js.Browser;
import js.html.Console;
import peer.Peer;
#end

class Lobby1v1 extends BaseState {

	var signalData:String;

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
		var menu = new FlxMenu(0, 0, 300, 5);
		menu.createPage('main')
			.add('
		-| create lobby | link | create_lobby
		-| connect | link | connect_to_lobby
		-| __________ | label | 3 | U
		-| main menu | link | open_main_menu
		')
			.par({
				pos: 'screen,c,c'
			});

		MenuStyle.setDefaultStyle(menu);
		menu.goto('main');
		add(menu);

		var iceCompleteTimeout = 60 * 2 * 1000;

		menu.onMenuEvent = (e, id) -> {
			switch ([e, id]) {
				case [it_fire, 'create_lobby']:
					if (localPeer == null) {
						localPeer = connect(untyped {
							initiator: true,
							trickle: false,
							stream: false,
							iceCompleteTimeout: iceCompleteTimeout,
							// config: {
							// 	// NOTE: iceServers from PeerJS library
							// 	// https://github.com/peers/peerjs/blob/f52cb0c661d1cbaac78a64a5253b3eef03d4dd81/lib/util.ts#L36
							// 	iceServers: untyped [
							// 		{urls: "stun:stun.l.google.com:19302"},
							// 		{
							// 			urls: ["turn:eu-0.turn.peerjs.com:3478", "turn:us-0.turn.peerjs.com:3478"],
							// 			username: "peerjs",
							// 			credential: "peerjsp",
							// 		},
							// 	],
							// },
						});
					}

					menu.close(true);
					menu.pages.remove('main');
					menu.createPage('main')
						.add('
							-| create lobby | link | create_lobby | D | U |
							-| accept connection | link | accept_connection
							-| __________ | label | 3 | U
							-| main menu | link | open_main_menu
							')
						.par({
							pos: 'screen,c,c'
						});
					menu.goto('main');

				// menu.item_update('main', 'connect_to_lobby', item -> {
				// 	item.ID = 'accept_connection';
				// 	item.label = 'accept connection';
				// 	item.disabled = false;
				// 	item.selectable = true;
				// });

				// menu.item_update('main', 'create_loby', item -> {
				// 	item.selectable = false;
				// 	item.disabled = true;
				// });

				case [it_fire, 'connect_to_lobby']:
					if (localPeer == null) {
						localPeer = connect(untyped {
							initiator: false,
							trickle: false,
							stream: false,
							iceCompleteTimeout: iceCompleteTimeout,
						});
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

						menu.close(true);
						menu.pages.remove('main');
						menu.createPage('main')
							.add('
							-| create lobby | link | create_lobby | D | U |
							-| connecting | link | wait_connection | D | U |
							-| __________ | label | 3 | U
							-| main menu | link | open_main_menu
							')
							.par({
								pos: 'screen,c,c'
							});
						menu.goto('main');

						// menu.item_update('main', 'connect_to_lobby', item -> {
						// 	item.ID = 'wait_connection';
						// 	item.label = 'connecting';
						// 	item.disabled = true;
						// 	item.selectable = false;
						// });
					}

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

		return peer;
	}
	#else
	override function create() {
		super.create();

		var input = new FlxInputText(0, 0, 150, 'hello', 12, FlxColor.WHITE, FlxColor.BLACK);
		input.screenCenter();
		add(input);

		trace('--------------');
		trace(Clipboard.generalClipboard.formats);
		trace(Clipboard.generalClipboard.hasFormat(TEXT_FORMAT));
		trace(LimeClipboard.text);
		trace(Clipboard.generalClipboard.getData(TEXT_FORMAT));
	}
	#end

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.keys.pressed.CONTROL && Flixel.keys.pressed.V) {
			trace('ctrl + v is pressed');
			trace(Clipboard.generalClipboard.getData(TEXT_FORMAT));
			trace(LimeClipboard.text);

			var text:String = Clipboard.generalClipboard.getData(TEXT_FORMAT);

			if (text != null && text != '' && text != signalData) {
				#if html5
				localPeer.signal(Json.parse(text));
				#end
			}
			else if (text == null || text == '')
				trace('clipboard data is empty: "$text"');
		}
	}
}
