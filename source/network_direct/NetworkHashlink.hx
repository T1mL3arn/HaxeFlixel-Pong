package network_direct;

import anette.Client;
import anette.Connection;
import anette.Protocol.Line;
import anette.Protocol.Prefixed;
import anette.Server;
import flixel.util.FlxTimer;

class NetworkHashlink {

	var isServer:Bool;

	public function new(isServer:Bool) {

		this.isServer = isServer;

		if (isServer) {
			//
			var server = new PongServer('localhost', 12345);

			new FlxTimer().start(Flixel.updateFramerate, _ -> {
				server.pump();
				server.flush();
			}, 0);

			var timer = new haxe.Timer(Std.int(1000 / 100));
			timer.run = () -> {
				server.pump();
				server.flush();
			}
		}
		else {
			var client = new anette.Client();
			client.protocol = new Line();
			client.timeout = 0;
			client.onData = onData;

			client.onConnection = connection -> {
				trace('CLIENT: client connected to the server');
				trace(connection);
			}

			new FlxTimer().start(Flixel.updateFramerate, _ -> {
				if (client.connected) {
					client.pump();
					client.flush();
				}
			}, 0);

			var timer = new haxe.Timer(Std.int(1000 / 100));
			timer.run = () -> {
				if (client.connected) {
					client.pump();
					client.flush();
				}
			}

			client.connect('localhost', 12345);
		}
	}

	function onData(connection:Connection) {
		// var len = connection.input.readInt16();
		trace(connection.input.readLine());
		// trace(connection.input.readUTF());
	}
}

class PongServer extends anette.Server {

	var connection:Connection;

	public function new(address, port) {
		super(address, port);
		protocol = new Line();
		timeout = 0;
	}

	override function onDataDefault(connection:Connection) {
		var msg = connection.input.readLine();
		trace('message: $msg');
		// TODO: this should use Network and send data to it
		// to decode them into game logic
	}

	override function onConnectionDefault(connection:Connection) {
		trace('client connected');
		// store connection and use it to send msg to the client
		this.connection = connection;
	}

	public function sendMessage(msg:String) {
		// TODO existed NETWORK class must somehow use
		// this method to send messages
		connection.output.writeString(msg);
	}
}
