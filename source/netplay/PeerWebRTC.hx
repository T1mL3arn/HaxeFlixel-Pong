package netplay;

import haxe.Json;
import js.Browser;
import js.html.Console;
import js.lib.Error;
import flixel.input.mouse.FlxMouseEvent;
import menu.BaseMenu;
import peer.Peer;
import peer.PeerEvent;
import netplay.Lobby1v1.ConnectionState;
import netplay.Lobby1v1.LobbyMenuPage;
import netplay.Netplay.NetplayMessage;
import netplay.Netplay.NetplayMessageKind;
import netplay.NetplayPeer.NetplayPeerBase;

@:access(netplay.Lobby1v1)
class PeerWebRTC extends NetplayPeerBase<NetplayMessageKind> {

	var peer:Peer;
	var signalData:String;
	var lobby:Lobby1v1;

	public function new() {
		super();

		// NOTE: it is safe since peer is called directly from Lobby1v1 class
		lobby = cast Flixel.state;
	}

	var peerOptions = {
		initiator: false,
		trickle: false,
		stream: false,
		// TODO: document this field (and others too)
		iceCompleteTimeout: 2 * 60 * 1000,
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

	override function create(?host:String, ?port:Int) {
		isServer = true;

		lobby.infobox.text = 'Creating lobby...';
		lobby.connectionState = CreatingLobby;
		lobby.menu.goto(cast LobbyMenuPage.CreatingLobby);

		if (!lobby.menu.pages.exists(LobbyMenuPage.AcceptConnection)) {
			// create special page for SERVER
			lobby.menu.createPage(LobbyMenuPage.AcceptConnection)
				.add('
					-| create | link | create_lobby | D | U |
					-| accept connection | link | accept_connection
					-| __________ | label | 3 | U
					-| main menu | link | ${SWITCH_TO_MAIN_MENU}
					')
				.par({
					pos: 'screen,c,c'
				});

			lobby.menu.menuEvent.add((e, id) -> {
				switch ([e, id]) {
					case [it_fire, 'accept_connection']:
						//
						promptLobbyKey();

					default:
				}
			});
		}

		createPeer();
	}

	override function join(?host:String, ?port:Int) {
		isServer = false;

		lobby.connectionState = ConnectingToLobby;
		lobby.infobox.text = 'Connecting to lobby...';

		createPeer();

		// 1-frame delay between befor prompting
		haxe.Timer.delay(promptLobbyKey, Math.ceil(1000 / 60));
		// promptLobbyKey();
	}

	/**
		Creates underlying simple-peer's Peer object.
	**/
	function createPeer() {
		peerOptions.initiator = isServer;

		peer?.destroy();
		peer = new Peer(peerOptions);
		peer.on(PeerEvent.ERROR, (err:Error) -> {
			Console.error(err);
			onError.dispatch(err);
		});

		// simple-peer: SIGNAL event is fired when THIS peer
		// wants to send signaling data to the remote peer
		peer.on(PeerEvent.SIGNAL, data -> {
			signalData = Json.stringify(data);
			trace('\nsignal data:\n$signalData');

			// copy data to clipboard when it is necessary
			switch ([lobby.connectionState, isServer]) {
				case [CreatingLobby, true] | [ConnectingToLobby, false]:
					//
					// either server is is creating lobby or client tries to connect to server
					copyToClipboard(signalData);
					FlxMouseEvent.add(lobby.infobox, _ -> copyToClipboard(signalData));

				default:
			}

			switch ([lobby.connectionState, isServer]) {
				case [CreatingLobby, true]:
					//
					// server get signaling data and ready to wait a client to connect
					lobby.infobox.text = 'Connection ID is copied into clipboard. Share it with another player, then press "accept connection" and paste the player\'s response. Click here to copy ID again.';
					lobby.connectionState = LobbyCreated;
					lobby.menu.goto(cast LobbyMenuPage.AcceptConnection);

				case [ConnectingToLobby, false]:
					//
					lobby.infobox.text = 'Connection ID is copied into clipboard. Share it with another player and wait a little. Click here to copy ID again.';

				default:
			}
		});

		peer.on(PeerEvent.CONNECT, () -> {
			trace('Connected!');

			// peer is an instance of EventEmitter
			// but the extern does not provide its methods,
			// so I use `untyped`
			untyped peer.removeAllListeners(PeerEvent.SIGNAL);
			untyped peer.removeAllListeners(PeerEvent.CONNECT);
			// let's don't remove listeners below
			// untyped peer.removeAllListeners(PeerEvent.CLOSE);
			// untyped peer.removeAllListeners(PeerEvent.ERROR);

			onConnect.dispatch();
		});

		peer.on(PeerEvent.CLOSE, onDisconnect.dispatch);
		peer.on(PeerEvent.DATA, onData);
	}

	function copyToClipboard(text:String) {
		openfl.desktop.Clipboard.generalClipboard.setData(TEXT_FORMAT, text);
		lime.system.Clipboard.text = text;
	}

	function promptLobbyKey() {
		var pastedData = Browser.window.prompt('Paste lobby key');
		switch (pastedData) {
			case null:
				// user pressed CANCEL
				var msg = 'Canceled';
				// Browser.window.alert(msg);
				lobby.connectionState = ConnectionState.Initial;
				lobby.infobox.text = msg;

			case '':
				// user pressed OK with empty data
				var msg = 'You paste nothing, try again.';
				Browser.window.alert(msg);
				lobby.connectionState = ConnectionState.Initial;
				lobby.infobox.text = msg;

			default:
				// user pressed OK with some data

				pastedData = StringTools.trim(pastedData);

				// the data is the same as previous signal data (valid only for server)
				if (pastedData == signalData) {
					var msg = 'You are pasting the same data, try again.';
					Browser.window.alert(msg);
					lobby.connectionState = ConnectionState.Initial;
					lobby.infobox.text = msg;

					return;
				}

				var parsedData:String = null;

				try {
					parsedData = Json.parse(pastedData);
				}
				catch (e:Dynamic) {
					trace('Error parsing signaling data as JSON');
					Browser.console.error(e);
					onError.dispatch(e);
					return;
				}

				// finally, the data is valid, can connect

				if (isServer) {
					lobby.infobox.text = 'Accepting connection...';
					lobby.menu.goto(cast LobbyMenuPage.JoiningToLobby);

					// lobby inst now is in LobbyCreated state, don't change it
					// lobby.connectionState = ConnectingToLobby;
				}
				else {
					lobby.connectionState = ConnectingToLobby;
					lobby.infobox.text = 'Connecting to lobby...';
					lobby.menu.goto(cast LobbyMenuPage.JoiningToLobby);
				}

				peer.signal(parsedData);
		}
	}

	override public function send(msgType:NetplayMessageKind, ?data:Any = null) {
		var msg = getMessage(msgType, data);
		peer.send(packMessage(msg));
		onMessage.dispatch(msg);
	}

	override public function destroy() {
		super.destroy();
		// NOTE: underlying peer instance can be null
		untyped peer?.removeAllListeners(PeerEvent.SIGNAL);
		untyped peer?.removeAllListeners(PeerEvent.CONNECT);
		untyped peer?.removeAllListeners(PeerEvent.CLOSE);
		untyped peer?.removeAllListeners(PeerEvent.ERROR);
		untyped peer?.removeAllListeners(PeerEvent.DATA);
		peer?.destroy();
		peer = null;
	}
}
