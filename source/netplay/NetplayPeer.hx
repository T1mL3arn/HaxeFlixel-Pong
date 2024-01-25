package netplay;

import haxe.Json;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSignal;

interface INetplayPeer<T> {
	@:deprecated("Use `isServer` instead")
	public var initiator(default, null):Bool;
	public var isServer(default, null):Bool;
	public var peerType(get, never):String;

	public var onMessage:FlxTypedSignal<({type:T, data:Any})->Void>;
	public var onConnect:FlxSignal;
	public var onDisconnect:FlxSignal;
	public var onError:FlxTypedSignal<Dynamic->Void>;

	public function onData(data:Any):Void;
	public function send(msgType:T, ?data:Any = null):Void;
	public function destroy():Void;

	/** to implement event loop (if applicable) **/
	public function loop():Void;

	public function create(?host:String, ?port:Int):Void;
	public function join(?host:String, ?port:Int):Void;
}

class NetplayPeerBase<T> implements INetplayPeer<T> {

	@:deprecated("Use `isServer` instead")
	public var initiator(default, null):Bool = false;
	public var isServer(default, null):Bool = false;

	public var peerType(get, never):String;

	function get_peerType():String {
		return isServer ? 'SERVER' : 'CLIENT';
	}

	public var onMessage:FlxTypedSignal<({type:T, data:Any})->Void> = new FlxTypedSignal();
	public var onConnect:FlxSignal = new FlxSignal();
	public var onDisconnect:FlxSignal = new FlxSignal();
	public var onError:FlxTypedSignal<Dynamic->Void> = new FlxTypedSignal();

	public function new() {}

	public function destroy() {
		loop();

		onMessage.destroy();
		onMessage = null;
		onConnect.destroy();
		onConnect = null;
		onDisconnect.destroy();
		onDisconnect = null;
		onError.destroy();
		onError = null;

		#if flixel
		flixel.FlxG.plugins.get(mod.Updater)?.remove(this.loop, this);
		#end
	}

	public function send(msgType:T, ?data:Any) {}

	public function onData(data:Any) {
		var parsed:{type:T, data:Any} = Json.parse(data);
		// trace('$peerType: get raw', data);
		onMessage.dispatch(parsed);
	}

	overload extern inline function packMessage(type:T, data:Any):String {
		return Json.stringify(getMessage(type, data));
	}

	overload extern inline function packMessage(msg:Any):String {
		return Json.stringify(msg);
	}

	inline function getMessage(type:T, data:Any) {
		return {
			type: type,
			data: data
		};
	}

	public function loop() {}

	public function create(?host:String, ?port:Int) {}

	public function join(?host:String, ?port:Int) {}
}
