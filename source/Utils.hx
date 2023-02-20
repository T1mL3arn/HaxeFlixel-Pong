package;

using Reflect;

/**
	Merges all fields from `source` into `target`.
	This method is only guaranteed to work on anonymous structures.
**/
function merge<A, B, AB:A & B>(target:A, source:B):AB {
	for (fieldName in source.fields())
		target.setField(fieldName, source.field(fieldName));
	return cast target;
}

inline function invLerp(a:Float, b:Float, v:Float):Float {
	return (v - a) / (b - a);
}

inline function swap<T>(arr:Array<T>, from:Int, to:Int) {
	var tmp = arr[from];
	arr[from] = arr[to];
	arr[to] = tmp;
}
