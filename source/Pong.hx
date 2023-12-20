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

	/**
		Current room
	**/
	public var room:{ball:Null<Ball>};

	/**
		Manages all ai tweens with object.
		When game is paused such tweens are also paused.
	**/
	public var aiTweens(default, null):FlxTweenManager;

	public var signals:{
		keyPress:FlxSignal
	};

	public function new() {
		// Until https://github.com/HaxeFlixel/flixel/pull/2819 is fixed
		// I have to skip splash.
		super(0, 0, null, true);

		aiTweens = Flixel.plugins.addPlugin(new FlxTweenManager());
		signals.keyPress = Flixel.signals.postUpdate;

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

		Flixel.signals.postGameReset.add(() -> aiTweens.active = true);

		// disable/enable camera filters
		signals.keyPress.add(() -> {
			if (Flixel.keys.justPressed.T)
				Flixel.camera.filtersEnabled = !Flixel.camera.filtersEnabled;
		});
	}
}
