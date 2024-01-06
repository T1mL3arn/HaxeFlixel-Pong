package network_wrtc;

import haxe.Json;
import flixel.util.FlxSignal.FlxTypedSignal;
import peer.Peer;

var network:Network = null;

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

#if html5
class Network {

	public var initiator(default, null):Bool = false;
	public var peer:Peer;
	public var onMessage:NetworkMessageSignal;

	public function new(peer:Peer) {
		this.peer = peer;
		initiator = untyped peer.initiator;
		onMessage = new NetworkMessageSignal();
		peer.on('data', onData);
	}

	function onData(data:Any) {
		var parsed:NetworkMessage = Json.parse(data);
		onMessage.dispatch(parsed);
	}

	public function send(msgType:NetworkMessageType, ?data:Any = null) {
		var msg = {
			type: msgType,
			data: data
		};
		peer.send(Json.stringify(msg));
		onMessage.dispatch(msg);
	}

	public function destroy() {
		peer.destroy();
		onMessage.destroy();
		peer = null;
		onMessage = null;
	}
}
#end
