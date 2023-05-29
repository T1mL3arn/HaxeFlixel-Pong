package network_wrtc;

import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Json;
import peer.Peer;

var network:Network = null;

enum abstract NetworkMessageType(String) {
	var PaddleAction;
	var PaddleData;
	var BallData;
	var ScoreData;
	var CongratScreenData;
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

	public function send(msgType:NetworkMessageType, data:Any) {
		var msg = {
			type: msgType,
			data: data
		};
		peer.send(Json.stringify(msg));
		onMessage.dispatch(msg);
	}
}
#end
