package;

import flixel.FlxGame;
import flixel.FlxObject;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.util.FlxSignal;
import openfl.display.DisplayObject;
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

	/**
		Current game params.
	**/
	public static var params:PongParams = Reflect.copy(defaultParams);

	/**
		Resets `params` to its default value, using `defaultParams`
	**/
	public static inline function resetParams() {
		params = Reflect.copy(defaultParams);
	}

	public var ballCollision:FlxTypedSignal<(FlxObject, Ball)->Void> = new FlxTypedSignal();

	inline function get_state()
		return cast Flixel.state;

	/**
		Current room
	**/
	public var room:{ball:Null<Ball>};

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

		var crtShader = new CrtShader();
		var filters = [new ShaderFilter(crtShader)];
		Flixel.signals.preUpdate.add(()->crtShader.update(Flixel.elapsed));
		Flixel.signals.postStateSwitch.add(() -> Flixel.camera.filters = cast filters);
		Flixel.signals.gameResized.add((_, _) -> {

			// NOTE: shader distortion problem
			// https://github.com/HaxeFlixel/flixel/issues/2181#issuecomment-447118529
			// https://github.com/HaxeFlixel/flixel/issues/2258
			// https://discord.com/channels/162395145352904705/165234904815239168/1044303305108639834
			// https://dixonary.co.uk/blog/shadertoy#a-couple-of-gotchas

			Flixel.cameras.reset();
			Flixel.camera.filters = cast filters;
		});
	}
}

/**
	Crutch to allow the same type of plugin to be used twice 
	in PluginFrontEnd
**/
class GameTweenManager extends FlxTweenManager {}
