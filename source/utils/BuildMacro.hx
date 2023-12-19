package utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
	Adds `GAME` field to the class.
	The field returns current `FlxG.game` as `Pong` instance.
	@return Array<Field>
**/
function addField_GAME():Array<Field> {
	var fields = Context.getBuildFields();

	var fieldName = 'GAME';

	// body for GAME getter
	var fieldGetterBody:Function = {
		args: [],
		// get_GAME() just returns flixel.FlxG.game
		expr: macro return cast flixel.FlxG.game,
		// return type is Pong
		ret: TPath({pack: [], name: "Pong"}),
	};

	// property with accessor
	// i.e. `public var GAME(get, never):Pong`
	fields.push({
		name: fieldName,
		doc: 'Pong game class, subclass of `flixel.FlxGame`',
		access: [Access.APublic],
		// declare that prop has getter, has no setter at all
		// and has type Pong
		kind: FieldType.FProp('get', 'never', macro :Pong),
		pos: Context.currentPos(),
	});

	fields.push({
		name: 'get_${fieldName}',
		// getter is inline and private
		access: [Access.APrivate, Access.AInline],
		// set it to be previously created function
		kind: FieldType.FFun(fieldGetterBody),
		pos: Context.currentPos(),
	});

	// Return the updated class fields
	return fields;
}
#end
