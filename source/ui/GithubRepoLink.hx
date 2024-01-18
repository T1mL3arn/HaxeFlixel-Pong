package ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import lime.system.System;
import math.MathUtils.p;
import mouse.SpriteAsMouse;

using Math;

class GithubRepoLink extends FlxTypedButton<FlxSprite> {

	public var labelGroup:FlxSpriteGroup;

	public function new() {
		var url = 'https://github.com/T1mL3arn/HaxeFlixel-Pong';

		super(0, 0, ()->System.openURL(url));

		labelGroup = new FlxSpriteGroup();

		var octocat = new FlxSprite();
		octocat.loadGraphic(AssetPaths.gh_icon_final__png, false, 128, 128);
		octocat.scale.set(0.25, 0.25);
		octocat.updateHitbox();

		var text = new FlxText();
		text.size = 16;
		text.text = 'open repo';
		text.color = FlxColor.GRAY;
		text.x = 0;
		text.y = 0;

		var padding = 10;
		octocat.x = text.width + padding;
		octocat.y = text.height * 0.5 - octocat.height * 0.5;

		labelGroup.add(text);
		labelGroup.add(octocat);
		labelGroup.forEach(s -> s.y -= octocat.y);

		// trace(text.x, text.y, text.width, text.height);
		// trace(octocat.x, octocat.y, octocat.width, octocat.height);

		label = labelGroup;
		labelOffsets = [p(), p(), p()];
		labelAlphas = [0.7, 1.0, 0.5];
		makeGraphic(labelGroup.width.floor(), labelGroup.height.floor(), FlxColor.TRANSPARENT);
		updateHitbox();
		status = FlxButton.NORMAL;

		var mouse = Flixel.plugins.get(SpriteAsMouse);
		onOver.callback = ()->mouse.setCursor(mouse.pointerCursor, -5);
		onOut.callback = ()->mouse.setCursor(mouse.arrowCursor, 0, 0);
	}
}
