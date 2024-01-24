package ui;

import flixel.FlxSprite;
import flixel.addons.text.FlxTextInput;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using Math;

class HostInput extends FlxTypedSpriteGroup<FlxSprite> {

	public var address(default, null):FlxTextInput;
	public var port(default, null):FlxTextInput;

	public var lastHost(default, null) = {
		address: 'localhost',
		port: '12345',
	}

	public function new() {
		super();

		var gap = 2;

		var label = styleText(new FlxText('IP:'));
		label.textField.backgroundColor = 0xDADADA;
		add(label);

		address = styleText(new FlxTextInput());
		address.multiline = false;
		address.maxChars = 15; // 255.255.255.255
		address.text = lastHost.address;
		address.x = x + width + gap;
		address.fieldWidth = 200;
		address.fieldHeight = address.height;
		add(address);

		label = styleText(new FlxText('port:'));
		label.textField.backgroundColor = 0xDADADA;
		label.x = x + width + gap;
		add(label);

		port = styleText(new FlxTextInput());
		port.multiline = false;
		port.maxChars = 5;
		port.text = '${lastHost.port}';
		port.fieldWidth = 100;
		port.fieldHeight = address.fieldHeight;
		port.x = x + width + gap;
		add(port);

		address.onChange.add(() -> updateLastHost(address, 'address'));
		address.onInput.add(() -> updateLastHost(address, 'address'));
		// address.onEnter.add(()->hostChanged(lastHost.address, lastHost.port));
		port.onChange.add(() -> updateLastHost(port, 'port'));
		port.onInput.add(() -> updateLastHost(port, 'port'));
		// port.onEnter.add(()->hostChanged(lastHost.address, lastHost.port));
	}

	// public dynamic function hostChanged(address:String, port:String) {
	// 	trace('do it yourself');
	// }

	function updateLastHost(field:FlxText, propName:String) {
		field.text = StringTools.trim(field.text);
		Reflect.setField(lastHost, propName, field.text);
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
