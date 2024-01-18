package network_wrtc;

import haxe.Json;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSignal;

var network:INetplayPeer = null;

enum abstract NetworkMessageType(String) {
	var PaddleAction;
	var PaddleData;
	var BallData;
	var ScoreData;
	var CongratScreenData;
	var ResetRoom;
	var BallPreServe;
	var DebugPause;
}

typedef NetworkMessage = {
	type:NetworkMessageType,
	data:Any,
};

typedef NetworkMessageSignal = FlxTypedSignal<NetworkMessage->Void>;

interface INetplayPeer {
	@:deprecated("Use `isServer` instead")
	public var initiator(default, null):Bool;
	public var isServer(default, null):Bool;
	public var peerType(get, never):String;

	public var onMessage:NetworkMessageSignal;
	public var onConnect:FlxSignal;
	public var onDisconnect:FlxSignal;
	public var onError:FlxTypedSignal<Dynamic->Void>;

	public function onData(data:Any):Void;
	public function send(msgType:NetworkMessageType, ?data:Any = null):Void;
	public function destroy():Void;

	/** to implement event loop (if applicable) **/
	public function loop():Void;

	public function create():Void;
	public function join(host:String, port:Int):Void;
}

class NetplayPeerBase implements INetplayPeer {

	@:deprecated("Use `isServer` instead")
	public var initiator(default, null):Bool = false;
	public var isServer(default, null):Bool = false;

	public var peerType(get, never):String;

	function get_peerType():String {
		return isServer ? 'SERVER' : 'CLIENT';
	}

	public var onMessage:NetworkMessageSignal = new NetworkMessageSignal();
	public var onConnect:FlxSignal = new FlxSignal();
	public var onDisconnect:FlxSignal = new FlxSignal();
	public var onError:FlxTypedSignal<Dynamic->Void> = new FlxTypedSignal();

	public function new() {}

	public function destroy() {
		onMessage.destroy();
		onMessage = null;
		onConnect.destroy();
		onConnect = null;
		onDisconnect.destroy();
		onDisconnect = null;
		onError.destroy();
		onError = null;
	}

	public function send(msgType:NetworkMessageType, ?data:Any) {}

	public function onData(data:Any) {
		var parsed:NetworkMessage = Json.parse(data);
		trace('$peerType: get raw', data);
		onMessage.dispatch(parsed);
	}

	overload extern inline function packMessage(type:NetworkMessageType, data:Any):String {
		return Json.stringify(getMessage(type, data));
	}

	overload extern inline function packMessage(msg:Any):String {
		return Json.stringify(msg);
	}

	inline function getMessage(type:NetworkMessageType, data:Any) {
		return {
			type: type,
			data: data
		};
	}

	public function loop() {}

	public function create() {}

	public function join(host:String, port:Int) {}
}
