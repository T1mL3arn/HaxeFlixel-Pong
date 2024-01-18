package network_direct;

import haxe.Json;
import anette.BaseHandler;
import anette.Connection;
import anette.Protocol.Line;
import network.Client;
import network.ISocket;
import network.Server;
import network_wrtc.Lobby1v1;
import network_wrtc.Network.NetplayPeerBase;
import network_wrtc.Network.NetworkMessage;
import network_wrtc.Network.NetworkMessageType;

@:access(network_wrtc.Lobby1v1)
class PeerIP extends NetplayPeerBase {

	var connection:Connection;
	var socket:ISocket;

	public function new(isServer:Bool = false) {
		super();

		this.isServer = isServer;
	}

	override function create() {
		isServer = true;

		// TODO: get real Lobby instance
		var lobby:Lobby1v1 = cast Flixel.state;

		lobby.connectionState = CreatingLobby;
		lobby.infobox.text = 'Creating lobby...';
		lobby.menu.goto(cast LobbyMenuPage.CreatingLobby);

		var peer = new Server('localhost', 12345);
		peer.protocol = new Line();
		peer.timeout = 0;
		addHandlers(peer);

		socket = peer;
	}

	override function join(host:String, port:Int) {
		//
		isServer = false;

		// TODO: get real Lobby instance
		var lobby:Lobby1v1 = cast Flixel.state;

		lobby.connectionState = ConnectingToLobby;
		lobby.infobox.text = 'Connecting to lobby...';
		lobby.menu.goto(cast LobbyMenuPage.JoiningToLobby);

		var peer = new Client();
		peer.protocol = new Line();
		peer.timeout = 0;
		addHandlers(peer);
		socket = peer;
		peer.connect('localhost', 12345);
	}

	function addHandlers(peer:BaseHandler) {
		peer.onConnection = c -> {
			final target = !isServer ? 'SERVER' : 'CLIENT';
			trace('$peerType: connected to $target');
			connection = c;
			dontloop = true;
			onConnect.dispatch();
		}
		peer.onData = c -> {
			trace('$peerType: onData');
			var msg = c.input.readLine();
			connection = c;
			this.onData(msg);
		}
		peer.onDisconnection = c -> {
			trace('$peerType: disconnect');
			onDisconnect.dispatch();
		}
		peer.onConnectionError = e -> {
			trace('$peerType: error');
			onError.dispatch(e);
		}
	}

	override function onData(data:Any) {
		// data that read from connection is already a string
		var str:String = data;
		var message:NetworkMessage = Json.parse(str);
		onMessage.dispatch(message);
	}

	override function send(msgType:NetworkMessageType, ?data:Any) {
		// var msg = getMessage(msgType, data);
		var msg = {
			type: msgType,
			data: data,
		}
		// adding '\n' to be sure our string properly terminates
		var str = Json.stringify(msg) + '\n';
		trace('$peerType: send raw: $str');
		connection.output.writeString(str);
		onMessage.dispatch(msg);
		// pumpFlush();
	}

	var dontloop = false;

	override function loop() {
		if (isServer || socket.connected) {
			pumpFlush();
		}
	}

	inline function pumpFlush() {
		socket.pump();
		socket.flush();
	}

	override function destroy() {
		super.destroy();

		if (isServer) {
			//
			// TODO: disconnect all clients associated with the server
		}
		else {
			socket.disconnect();
		}

		connection = null;
		socket = null;
	}
}
