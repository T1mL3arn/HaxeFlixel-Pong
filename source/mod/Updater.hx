package mod;

import flixel.FlxBasic;

class Updater extends FlxBasic {

	var funcs:Array<Void->Void> = [];

	public function new() {
		super();
	}

	public function add(func:Void->Void) {
		funcs.push(func);
		return this;
	}

	public function remove(func:Void->Void) {
		throw 'not implemented';
		// if (func == null)
		// 	return;
		// funcs.remove(f -> Reflect.compareMethods(f, func));
	}

	public function clear() {
		funcs = [];
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
