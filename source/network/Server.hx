package network;

import haxe.io.Bytes;
import anette.BaseHandler;
import anette.Connection;

class Server implements ISocket extends BaseHandler {

	/**
		For server it is alwasy `false`
	**/
	@:isVar public var connected(get, null):Bool;

	@:noCompletion
	public function get_connected():Bool {
		return false;
	}

	public var connections:Map<sys.net.Socket, Connection> = new Map();

	var serverSocket:sys.net.Socket;
	var sockets:Array<sys.net.Socket>;
	var buffer:Bytes = Bytes.alloc(8192);

	public function new(address:String, port:Int) {
		super();
		serverSocket = new sys.net.Socket();
		serverSocket.bind(new sys.net.Host(address), port);
		serverSocket.input.bigEndian = true;
		serverSocket.listen(1);
		serverSocket.setBlocking(false);
		serverSocket.setFastSend(false);
		sockets = [serverSocket];
		trace("server " + address + " / " + port);
	}

	public function connect(ip:String, port:Int) {
		throw("Anette : You can't connect as a server");
	}

	public function pump() {
		var inputSockets = sys.net.Socket.select(sockets, null, null, 0);
		// trace("inputSockets " + sockets.length);
		for (socket in inputSockets.read) {
			if (socket == serverSocket) {
				var newSocket = socket.accept();
				newSocket.setBlocking(false);
				newSocket.setFastSend(false);
				newSocket.output.bigEndian = true;
				newSocket.input.bigEndian = true;
				sockets.push(newSocket);

				var connection = new Connection(this, newSocket);
				connections.set(newSocket, connection);

				this.onConnection(connection);
			}
			else {
				try {
					var conn = connections.get(socket);

					// MattTuttle paste
					var bytesReceived = socket.input.readBytes(buffer, 0, buffer.length);
					// check that buffer was filled
					if (bytesReceived > 0) {
						conn.buffer.addBytes(buffer, 0, bytesReceived);
						conn.readDatas();
					}
				}
				catch (ex:Dynamic) {
					trace("SOCKET ERROR : EXCEPTION CALLSTACK");
					trace(ex);
					trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
					trace("END EXCEPTION CALLSTACK");
					disconnectSocket(socket, connections.get(socket));
				}
			}
		}
	}

	@:allow(anette.Connection)
	override function disconnectSocket(connectionSocket:sys.net.Socket, connection:Connection) {
		// connectionSocket.shutdown(true, true);
		trace("Anette : disconnectSocket");
		connectionSocket.close();

		// CLEAN UP
		sockets.remove(connectionSocket);
		connections.remove(connectionSocket);
		onDisconnection(connection);
	}

	// CALLED BY CONNECTION

	@:allow(anette.Connection)
	override function send(connectionSocket:sys.net.Socket, bytes:haxe.io.Bytes, offset:Int, length:Int) {
		try {
			connectionSocket.output.writeBytes(bytes, offset, length);
		}
		catch (error:Dynamic) {
			trace("Anette : Send error " + error);
			disconnectSocket(connectionSocket, connections.get(connectionSocket));
		}
	}

	public function flush() {
		for (socket in connections.keys()) {
			var conn = connections.get(socket);
			conn.flush();
		}
	}

	/**
		Disconnect and close all associated sockets.
		Also closes this server's socket.
	**/
	public function disconnect() {
		for (socket => connection in connections) {
			try {
				socket.close();
				sockets.remove(socket);
				connections.remove(socket);
				connection.disconnect();
			}
			catch (e) {
				trace('Server.disconnect() callstack START ---');
				trace('error (caught):');
				trace(e);
				trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
				trace('Server.disconnect() callstack END -----');
			}
		}
		serverSocket.close();
	}
}
