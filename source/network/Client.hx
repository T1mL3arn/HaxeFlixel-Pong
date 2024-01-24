package network;

import haxe.io.Bytes;
import anette.BaseHandler;
import anette.Connection;

class Client implements ISocket extends BaseHandler {

	public var connected(default, null):Bool = false;
	public var connection:Connection;

	var socket:sys.net.Socket;
	var buffer:Bytes = Bytes.alloc(8192);

	public function new() {
		super();
	}

	public function connect(ip:String, port:Int) {
		socket = new sys.net.Socket();

		try {
			socket.connect(new sys.net.Host(ip), port);
			this.connected = true;
		}
		catch (error:Dynamic) {
			this.onConnectionError(error);
			this.connected = false;
		}

		if (connected) {
			socket.output.bigEndian = true;
			socket.input.bigEndian = true;
			socket.setBlocking(false);
			socket.setFastSend(false);
			this.connection = new Connection(this, socket);
			this.onConnection(connection);
		}
	}

	public function pump() {
		// Todo : handle "Uncaught exception - std@socket_select"
		var sockets = sys.net.Socket.select([this.socket], null, null, 0);
		if (sockets.read.length > 0) {
			try {
				// MattTuttle paste
				var bytesReceived = socket.input.readBytes(buffer, 0, buffer.length);
				// check that buffer was filled
				if (bytesReceived > 0) {
					connection.buffer.addBytes(buffer, 0, bytesReceived);
					connection.readDatas();
				}
			}
			catch (ex:haxe.io.Eof) {
				disconnectSocket(socket, connection);
			}
			catch (ex:haxe.io.Error) {
				if (ex == haxe.io.Error.Blocked)
					trace("Blockedlol");
				if (ex == haxe.io.Error.Overflow)
					trace("OVERFLOW");
				if (ex == haxe.io.Error.OutsideBounds)
					trace("OUTSIDE BOUNDS");
			}
		}
		connection.readDatas();
	}

	public function flush() {
		connection.flush();
	}

	public function disconnect() {
		disconnectSocket(socket, connection);
	}

	@:allow(anette.Connection)
	override function disconnectSocket(_socket:sys.net.Socket, connection:Connection) {
		_socket.shutdown(true, true);
		_socket.close();
		connected = false;
		this.onDisconnection(connection);
	}

	@:allow(anette.Connection)
	override function send(_socket:sys.net.Socket, bytes:haxe.io.Bytes, offset:Int, length:Int) {
		try {
			_socket.output.writeBytes(bytes, offset, length);
		}
		catch (error:Dynamic) {
			trace("Anette : Send error " + error);
			disconnect();
		}
	}
}
