package;

import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.util.FlxSignal;
import openfl.display.StageQuality;
import openfl.events.MouseEvent;
import openfl.filters.ShaderFilter;
import room.RoomModel;
import shader.CrtShader;
import utils.FlxDragManager;

typedef PongParams = {
	ballSize:Int,
	ballSpeed:Float,

	/** Dealy before ball is served **/
	ballServeDelay:Float,

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
		ballServeDelay: 1.5,
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

	/**
		Current room
	**/
	public var room:RoomModel;

	/**
		Manages all ai tweens with object.
		When game is paused such tweens are also paused.
	**/
	public var aiTweens(default, null):FlxTweenManager;

	public var signals:{
		keyPress:FlxSignal,
		ballServed:FlxSignal,
		substateOpened:FlxTypedSignal<(FlxSubState, FlxState)->Void>,
		ballCollision:FlxTypedSignal<(FlxObject, Ball)->Void>,
	};

	public function new() {
		// Until https://github.com/HaxeFlixel/flixel/pull/2819 is fixed
		// I have to skip splash.
		super(0, 0, null, true);

		aiTweens = Flixel.plugins.addPlugin(new FlxTweenManager());

		signals = {
			keyPress: Flixel.signals.postUpdate,
			ballServed: new FlxTypedSignal(),
			substateOpened: new FlxTypedSignal(),
			ballCollision: new FlxTypedSignal(),
		}

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
		FLixel.signals.preGameStart.add(preGameStart);
		FLixel.signals.preGameStart.add(() -> {
			Flixel.game.stage.quality = StageQuality.LOW;
		});

		// Crutch to redispatch substate-opened events.
		// Flixel thiks I dont need such event in global scope,
		// and it is wrong.
		Flixel.signals.postStateSwitch.add(() -> {
			Flixel.state.subStateOpened.add(sub -> {
				trace('re-dispatch SUBSTATE-OPEN event to global scope');
				signals.substateOpened.dispatch(sub, @:privateAccess sub._parentState);
			});
		});

		#if debug
		Flixel.signals.postGameStart.addOnce(() -> {

			var wasPaused = false;
			var step = Flixel.game.debugger.getChildByName('stepbtn');
			step.addEventListener(MouseEvent.MOUSE_DOWN, e -> {
				//
				if (Flixel.vcr.paused) {
					Flixel.vcr.resume();
					wasPaused = true;
				}
				FLixel.timeScale = 0.2;
			});
			step.addEventListener(MouseEvent.MOUSE_UP, e -> {
				//
				if (!wasPaused)
					Flixel.vcr.resume();
				Flixel.timeScale = 1.0;
			});
		});
		#end
	}

	function preGameStart() {
		Flixel.plugins.add(new FlxDragManager());
	}
}
