package;

import flixel.FlxGame;
import flixel.FlxObject;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.util.FlxSignal;
import openfl.filters.ShaderFilter;
import shader.CrtShader;

typedef PongParams = {
	ballSize:Int,
	ballSpeed:Float,
	racketLength:Int,
	racketThickness:Int,
	racketSpeed:Float,
	racketPadding:Float,
	scoreToWin:Int,
};

class Pong extends FlxGame {

	public static var inst(get, never):Pong;

	static inline function get_inst():Pong
		return cast Flixel.game;

	public static final defaultParams:PongParams = {
		ballSize: 12,
		ballSpeed: 310,
		racketLength: 80,
		racketThickness: 12,
		racketSpeed: 225.0,
		racketPadding: 12.0,
		scoreToWin: 11,
	};

	public static var params:PongParams = Reflect.copy(defaultParams);

	public var ballCollision:FlxTypedSignal<(FlxObject, Ball)->Void> = new FlxTypedSignal();
	public var state(get, never):{ball:Null<Ball>};

	inline function get_state()
		return cast Flixel.state;

	/**
		Manages all tweens with gameplay object.
		When game is paused such tweens are also paused.
	**/
	public var gameTweens(default, null):FlxTweenManager;

	public function new() {
		// Until https://github.com/HaxeFlixel/flixel/pull/2819 is fixed
		// I have to skip splash.
		super(0, 0, null, true);

		gameTweens = Flixel.plugins.add(new GameTweenManager());

		// try to use this to fix your crt shader:
		Flixel.camera.screen.frame.uv;
		// also check this post
		// https://github.com/HaxeFlixel/flixel/issues/2181#issuecomment-447118529
		// and this issue https://github.com/HaxeFlixel/flixel/issues/2258

		var crtShader = new CrtShader();
		var filter = new ShaderFilter(crtShader);
		Flixel.signals.preUpdate.add(()->crtShader.update(Flixel.elapsed));
		Flixel.signals.postStateSwitch.add(() -> Flixel.camera.filters = [filter]);
		Flixel.signals.gameResized.add((_, _) -> {

			// Flixel.camera.flashSprite.invalidate();
			trace('resize');
			haxe.Timer.delay(() -> Flixel.camera.filters = [filter], 1);
			// Flixel.camera.flashSprite.cacheAsBitmap
			// this.__cacheBitmap = null;
			// this.__cacheBitmapData = null;
			// this.__cacheBitmapData2 = null;
			// this.__cacheBitmapData3 = null;
			// this.__cacheBitmapColorTransform = null;
		});

		// NOTE: set filters does not work in debug mode
		// see https://discord.com/channels/162395145352904705/165234904815239168/1183246310858571847
		// Flixel.game.setFilters([filter]);
	}
}

/**
	Crutch to allow the same type of plugin to be used twice 
	in PluginFrontEnd
**/
class GameTweenManager extends FlxTweenManager {}
