package text;

import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
	Fixed `FlxText` text field that allows to control auto height.
	In this `FlxText`, auto height is disabled.
	temporary fix for [HaxeFlixel#2783](https://github.com/HaxeFlixel/flixel/issues/2783)
**/
class FlxText extends flixel.text.FlxText {

	public var fieldHeight(get, set):Float;

	function get_fieldHeight():Float {
		return (textField != null) ? textField.height : 0;
	}

	function set_fieldHeight(v:Float):Float {
		if (textField == null)
			return v;
		if (v <= 0) {
			_autoHeight = true;
		}
		else {
			_autoHeight = false;

			textField.height = v;
		}
		_regen = true;
		return v;
	}

	override function set_fieldWidth(value:Float):Float {
		super.set_fieldWidth(value);

		if (value <= 0)
			_autoHeight = true;

		return value;
	}

	var _autoHeight:Bool = true;

	public function new(x = 0.0, y = 0.0, w = 0.0, h = 0.0, ?text, size = 8) {
		super(x, y, w, text, size);

		fieldHeight = h;
	}

	override function regenGraphic() {
		if (textField == null || !_regen)
			return;

		var oldWidth:Int = 0;
		var oldHeight:Int = flixel.text.FlxText.VERTICAL_GUTTER;

		if (graphic != null) {
			oldWidth = graphic.width;
			oldHeight = graphic.height;
		}

		var newWidth:Int = Math.ceil(textField.width);
		var textfieldHeight = _autoHeight ? textField.textHeight : textField.height;
		var vertGutter = _autoHeight ? flixel.text.FlxText.VERTICAL_GUTTER : 0;
		// Account for gutter
		var newHeight:Int = Math.ceil(textfieldHeight) + vertGutter;

		// prevent text height from shrinking on flash if text == ""
		if (textField.textHeight == 0) {
			newHeight = oldHeight;
		}

		if (oldWidth != newWidth || oldHeight != newHeight) {
			// Need to generate a new buffer to store the text graphic
			var key:String = FlxG.bitmap.getUniqueKey("text");
			makeGraphic(newWidth, newHeight, FlxColor.TRANSPARENT, false, key);

			if (_hasBorderAlpha)
				_borderPixels = graphic.bitmap.clone();

			if (_autoHeight)
				textField.height = newHeight;

			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		}
		else {
			// Else just clear the old buffer before redrawing the text
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha) {
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null && textField.text.length > 0) {
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();

			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}
}
