package mod;

import haxe.ds.ObjectMap;
import flixel.FlxBasic;

class Updater extends FlxBasic {

	var funcs:Array<Void->Void> = [];
	var objectMap:ObjectMap<{}, haxe.Constraints.Function>;

	public function new() {
		super();
		objectMap = new ObjectMap();
	}

	public function add(func:Void->Void, ?obj:Any) {
		funcs.push(func);
		if (obj != null)
			objectMap.set(obj, func);
		return this;
	}

	public function remove(func:Void->Void, ?obj:Any) {
		// if (func == null)
		// 	return;
		var ind = Lambda.findIndex(funcs, f -> Reflect.compareMethods(f, func));
		if (ind != -1)
			funcs.splice(ind, 1);
		if (obj != null)
			objectMap.remove(obj);
	}

	public function clear() {
		funcs = [];
		objectMap = new ObjectMap();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		for (func in funcs) {
			func();
		}
	}

	override function destroy() {
		super.destroy();
		funcs = null;
	}
}
