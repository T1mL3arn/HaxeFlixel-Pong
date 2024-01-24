package ui;

import flixel.FlxSprite;
import flixel.addons.text.FlxTextInput;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using Math;

@:build(utils.BuildMacro.addField_GAME())
class HostInput extends FlxTypedSpriteGroup<FlxSprite> {

	public var address(default, null):FlxTextInput;
	public var port(default, null):FlxTextInput;

	public function new() {
		super();

		final gap = 2;
		final labelColor = 0xFF8000;

		var label = styleText(new FlxText('IP:'));
		label.textField.backgroundColor = labelColor;
		add(label);

		address = styleText(new FlxTextInput());
		address.multiline = false;
		address.maxChars = 15; // 255.255.255.255
		address.text = GAME.host.address;
		address.x = x + width + gap;
		address.fieldWidth = 200;
		address.fieldHeight = address.height;
		add(address);

		label = styleText(new FlxText('port:'));
		label.textField.backgroundColor = labelColor;
		label.x = x + width + gap;
		add(label);

		port = styleText(new FlxTextInput());
		port.multiline = false;
		port.maxChars = 5;
		port.text = '${GAME.host.port}';
		port.fieldWidth = 100;
		port.fieldHeight = address.fieldHeight;
		port.x = x + width + gap;
		add(port);

		address.onChange.add(() -> updateLastHost(address, 'address'));
		address.onInput.add(() -> updateLastHost(address, 'address'));
		port.onChange.add(() -> updateLastHost(port, 'port'));
		port.onInput.add(() -> updateLastHost(port, 'port'));
	}

	function updateLastHost(field:FlxText, propName:String) {
		field.text = StringTools.trim(field.text);
		Reflect.setField(GAME.host, propName, field.text);
	}

	function styleText<T:FlxText>(text:T):T {
		var margin = 6;
		var fontSize = 18;
		text.size = fontSize;
		text.color = 0x111111;
		text.alignment = LEFT;
		text.textField.background = true;
		text.textField.backgroundColor = 0xEEEEEE;
		@:privateAccess
		var format = text._defaultFormat;
		format.leftMargin = format.rightMargin = margin;
		// trace(format.leftMargin, format.rightMargin);
		@:privateAccess text.updateDefaultFormat();
		return text;
	}

	public function setPos(x:Float, y:Float):HostInput {
		// flixel dont return from setPosition :(
		// return this.setPosition(x, y);

		// hashlink has some trouble with generics and type parameters
		// setPosition(x, y);

		utils.FlxSpriteGroupUtil.setPosition(this, x, y);

		// trace('---------');
		// trace(x, y);
		// trace(members.map(m -> '${m.x.round()} ${m.y.round()}'));

		return this;
	}
}
