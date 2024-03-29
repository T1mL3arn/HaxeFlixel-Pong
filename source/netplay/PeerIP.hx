package netplay;

import haxe.Json;
import haxe.Timer;
import anette.BaseHandler;
import anette.Connection;
import anette.Protocol.Line;
import network.Client;
import network.ISocket;
import network.Server;
import netplay.Lobby1v1;
import netplay.Netplay.NetplayMessage;
import netplay.Netplay.NetplayMessageKind;
import netplay.NetplayPeer.NetplayPeerBase;

@:access(netplay.Lobby1v1)
class PeerIP extends NetplayPeerBase<NetplayMessageKind> {

	var connection:Connection;
	var socket:ISocket;
	var peer:BaseHandler;
	var timer:Timer;

	public function new(isServer:Bool = false) {
		super();

		this.isServer = isServer;

		// setting up loop indepently from flixel
		timer = new Timer(Math.floor(1000 / 61));
		timer.run = loop;
	}

	override function create(?host:String, ?port:Int) {
		if (peer != null)
			onError.dispatch('Error: Already created');

		host = host ?? 'localhost';
		port = port ?? 12345;

		isServer = true;

		var lobby:Lobby1v1 = cast Flixel.state;

		lobby.connectionState = CreatingLobby;
		lobby.infobox.text = 'Creating lobby...';
		lobby.menu.goto(cast LobbyMenuPage.CreatingLobby);

		// 1 frame delay to redraw
		haxe.Timer.delay(() -> {
			try {
				createPeer().connect(host, port);
				// server is binded to the host/port
				lobby.connectionState = LobbyCreated;
				lobby.infobox.text = 'Game is ready. Waiting for second player';
			}
			catch (err) {
				onError.dispatch(err);
			}
		}, Std.int(1000 / Flixel.drawFramerate));
	}

	override function join(?host:String, ?port:Int) {
		if (peer != null)
			onError.dispatch('Error: Already joined');

		host = host ?? 'localhost';
		port = port ?? 12345;

		isServer = false;

		var lobby:Lobby1v1 = cast Flixel.state;

		lobby.connectionState = ConnectingToLobby;
		lobby.infobox.text = 'Connecting to lobby...';
		lobby.menu.goto(cast LobbyMenuPage.JoiningToLobby);

		// 1 frame delay to redraw
		haxe.Timer.delay(() -> {
			try {
				createPeer().connect(host, port);
			}
			catch (err) {
				onError.dispatch(err);
			}
		}, Std.int(1000 / Flixel.drawFramerate));
	}

	function createPeer():ISocket {
		var peer:BaseHandler = null;
		if (isServer) {
			peer = new Server();
		}
		else {
			peer = new Client();
		}
		peer.protocol = new Line();
		peer.timeout = 0;
		addHandlers(peer);

		socket = cast peer;
		this.peer = peer;
		return cast peer;
	}

	function addHandlers(peer:BaseHandler) {
		peer.onConnection = c -> {
			// final target = !isServer ? 'SERVER' : 'CLIENT';
			// trace('$peerType: connected to $target');
			connection = c;
			onConnect.dispatch();
		}
		peer.onData = c -> {
			connection = c;
			var msg:String;
			var list:Array<String> = [];
			while (true) {
				try {
					msg = c.input.readLine();
				}
				catch (eof) {
					// trace(eof);
					break;
				}
				list.push(msg);
			}
			for (msg in list) {
				this.onData(msg);
			}
		}
		peer.onDisconnection = c -> {
			// trace('$peerType: disconnect');
			onDisconnect.dispatch();
		}
		peer.onConnectionError = e -> {
			// trace('$peerType: error');
			onError.dispatch(e);
		}
	}

	override function onData(data:Any) {
		// data that read from connection is already a string
		var str:String = data;
		var message:NetplayMessage = Json.parse(str);
		onMessage.dispatch(message);
	}

	override function send(msgType:NetplayMessageKind, ?data:Any) {
		// trace('$peerType: sending $msgType');
		var msg = {
			type: msgType,
			data: data,
		}
		// NOTE: '\n' is mandatory, so on the other end
		// it could be read with `readLine()`
		var str = Json.stringify(msg) + '\n';
		// trace('$peerType: send raw: $str');
		connection.output.writeString(str);
		onMessage.dispatch(msg);
	}

	override function loop() {
		if (socket != null && socket.connected) {
			pumpFlush();
		}
	}

	inline function pumpFlush() {
		socket.pump();
		socket.flush();
	}

	override function destroy() {
		super.destroy();

		timer.stop();
		timer = null;

		if (peer != null) {
			peer.onConnection = _ -> {};
			peer.onConnectionError = _ -> {};
			peer.onDisconnection = _ -> {};
			peer.onData = _ -> {};
		}

		try {
			socket?.disconnect();
		}
		catch (e) {
			// wtf ?
			trace('disconnected with error:');
			trace(e);
		}

		peer = null;
		connection = null;
		socket = null;
	}
}
