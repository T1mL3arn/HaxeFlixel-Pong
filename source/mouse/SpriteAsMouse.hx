package mouse;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import math.MathUtils.p;
import state.BaseState;

/**
	Flugin to immitate cursor with FlxSprite.
	Used in purpose to apply main shader effects to cursor.

	TODO: Let it be a separate object that adds to game in some base state.
	Then it itself manages disabling system cursor, listen substate open/close etc.
	So it does literally the same but written differently
**/
@:build(utils.BuildMacro.addField_GAME())
class SpriteAsMouse extends FlxBasic {

	// var sprite
	public var cursor(default, set):FlxSprite;
	public var offset(default, null):FlxPoint;

	public var arrowCursor:FlxSprite;
	public var pointerCursor:FlxSprite;

	function set_cursor(v:FlxSprite):FlxSprite {
		removeCursor();
		cursor = v;
		addCursor();
		return v;
	}

	public function new() {
		super();

		offset = p(0, 0);

		arrowCursor = new FlxSprite();
		arrowCursor.loadGraphic(AssetPaths.arrow_cursor_16__png);
		arrowCursor.scale.set(2, 2);
		arrowCursor.updateHitbox();
		cursor = arrowCursor;

		pointerCursor = new FlxSprite();
		pointerCursor.loadGraphic(AssetPaths.pointer_cursor_16__png);
		pointerCursor.scale.set(2, 2);
		pointerCursor.updateHitbox();

		Flixel.signals.postStateSwitch.add(addCursor);
		Flixel.signals.preStateSwitch.add(removeCursor);
		// TODO extract callbacks to class fields and remove them in destroy()
		GAME.signals.substateOpened.add((_, _) -> if (Flixel.state.subState is BaseState) addToSubstate(cast Flixel.state.subState));
		GAME.signals.substateClosed.add((_, _) -> if (Flixel.state.subState is BaseState) removeFromSubstate(cast Flixel.state.subState));
	}

	function addToSubstate(state:BaseState) {
		state.topLayer.add(cursor);
	}

	function removeFromSubstate(state:BaseState) {
		// remove from substate
		state.topLayer.remove(cursor);
		// but try to add to its parent state
		addCursor();
	}

	function addCursor() {
		var state = Flixel.state;
		if (state is BaseState) {
			var base:BaseState = cast state;
			base.topLayer.add(cursor);
			// trace('cursor added', cursor.alive, cursor.exists);
		}
	}

	function removeCursor() {
		var substate = Flixel.state.subState;
		if (substate is BaseState) {
			var substate:BaseState = cast substate;
			substate.topLayer.remove(cursor);
		}
		var state = Flixel.state;
		if (state is BaseState) {
			var base:BaseState = cast state;
			base.topLayer.remove(cursor);
			// trace('cursor removed');
		}
	}

	public function setCursor(cursor:FlxSprite, offsetX:Float = 0, offsetY:Float = 0) {
		this.cursor = cursor;
		offset.set(offsetX, offsetY);
		updateCursorPosition();
	}

	inline function updateCursorPosition() {
		if (cursor != null) {
			cursor.x = Flixel.mouse.screenX + offset.x;
			cursor.y = Flixel.mouse.screenY + offset.y;
			// Flixel.watch.addQuick('cx', cursor.x);
			// Flixel.watch.addQuick('cy', cursor.y);
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		updateCursorPosition();
	}

	override function destroy() {
		super.destroy();

		Flixel.signals.postStateSwitch.remove(addCursor);
		Flixel.signals.preStateSwitch.remove(removeCursor);
	}
}
