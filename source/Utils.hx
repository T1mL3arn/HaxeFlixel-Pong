package;

using Reflect;

/**
	Merge all fields from `source` into `target`.
	This method is only guaranteed to work on anonymous structures.
**/
function merge<A, B, AB:A & B>(target:A, source:B):AB {
	for (fieldName in source.fields())
		target.setField(fieldName, source.field(fieldName));
	return cast target;
}
