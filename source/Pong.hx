package;

import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.sound.FlxSoundGroup;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.util.FlxSignal;
import mouse.MouseHider;
import mouse.SpriteAsMouse;
import openfl.display.StageQuality;
import openfl.events.MouseEvent;
import openfl.filters.ShaderFilter;
import room.RoomModel;
import shader.BloomShader;
import shader.CrtShader;
import shader.PixelateShader;
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
		ballServeDelay: 2.0,
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

	public var signals = {
		keyPress: Flixel.signals.postUpdate,
		ballServed: new FlxSignal(),
		substateOpened: new FlxTypedSignal<(FlxSubState, FlxState)->Void>(),
		substateClosed: new FlxTypedSignal<(FlxSubState, FlxState)->Void>(),
		ballCollision: new FlxTypedSignal<(FlxObject, Ball)->Void>(),
		pauseChange: new FlxTypedSignal<Bool->Void>(),
		/**
			Dispatched when on goal but before
			any goal related actions (like score update etc.).
			Sends `Player` that scored the goal.
		**/
		goal: new FlxTypedSignal<Player->Void>(),
	};

	public var gameSoundGroup(default, null):FlxSoundGroup;

	public function new() {
		// Until https://github.com/HaxeFlixel/flixel/pull/2819 is fixed
		// I have to skip splash.
		super(0, 0, null, true);

		// filtersEnabled = #if debug false #else true #end;
		filtersEnabled = #if debug true #else true #end;

		gameSoundGroup = new FlxSoundGroup();

		var crtShader = new CrtShader();
		var pixelateShader = new PixelateShader();
		var filters = [
			new ShaderFilter(pixelateShader),
			new ShaderFilter(new BloomShader()),
			new ShaderFilter(crtShader),
		];
		Flixel.signals.preUpdate.add(() -> {
			crtShader.update(Flixel.elapsed);
			pixelateShader.update(Flixel.elapsed);
		});
		Flixel.signals.postStateSwitch.add(() -> {
			Flixel.camera.filters = cast filters;
			Flixel.camera.filtersEnabled = filtersEnabled;
		});

		Flixel.signals.gameResized.add((_, _) -> {

			// NOTE: shader distortion problem
			// https://github.com/HaxeFlixel/flixel/issues/2181#issuecomment-447118529
			// https://github.com/HaxeFlixel/flixel/issues/2258
			// https://discord.com/channels/162395145352904705/165234904815239168/1044303305108639834
			// https://dixonary.co.uk/blog/shadertoy#a-couple-of-gotchas

			Flixel.cameras.reset();
			Flixel.camera.filters = cast filters;
			Flixel.camera.filtersEnabled = filtersEnabled;
		});

		// disable/enable camera filters
		signals.keyPress.add(() -> {
			if (Flixel.keys.justPressed.T) {
				filtersEnabled = !filtersEnabled;
				Flixel.camera.filtersEnabled = filtersEnabled;
			}
		});

		FLixel.signals.preGameStart.add(() -> {
			#if html5
			Flixel.game.stage.quality = StageQuality.LOW;
			#end

			Flixel.mouse.useSystemCursor = false;
			Flixel.mouse.visible = false;

			Flixel.plugins.add(new SpriteAsMouse());
			Flixel.plugins.add(new FlxDragManager());
			Flixel.plugins.add(new MouseHider());

			#if debug
			Flixel.debugger.visible = true;
			#end
		});

		// Crutch to redispatch substate-opened events.
		// Flixel thiks I dont need such event in global scope,
		// and it is wrong.
		Flixel.signals.postStateSwitch.add(() -> {
			Flixel.state.subStateOpened.add(sub -> {
				// trace('re-dispatch SUBSTATE-OPEN event to global scope');
				signals.substateOpened.dispatch(sub, @:privateAccess sub._parentState);
			});
			Flixel.state.subStateClosed.add(sub -> {
				signals.substateClosed.dispatch(sub, Flixel.state);
			});
		});

		Flixel.signals.preStateCreate.add(_ -> {
			gameSoundGroup.sounds = [];
			gameSoundGroup.volume = 1;
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
}
