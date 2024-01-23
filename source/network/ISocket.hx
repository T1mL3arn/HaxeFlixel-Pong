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
	@:isVar var connected(get, null):Bool;
	function get_connected():Bool;
	function disconnect():Void;
}