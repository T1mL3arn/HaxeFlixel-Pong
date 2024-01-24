package network;

import sys.net.Socket;
import anette.Connection;

interface ISocket {
	private var buffer:haxe.io.Bytes;

	function connect(ip:String, port:Int):Void;
	function disconnectSocket(socket:Socket, connection:Connection):Void;
	function pump():Void;
	function flush():Void;
	function send(connectionSocket:Socket, bytes:haxe.io.Bytes, offset:Int, length:Int):Void;
	var connected(default, null):Bool;
	function disconnect():Void;
}
