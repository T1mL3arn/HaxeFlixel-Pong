package state;

import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.util.FlxTimer.FlxTimerManager;

@:build(utils.BuildMacro.addField_GAME())
class BaseState extends FlxSubState {

	/** 
		Wether an openned substate (like PauseMenu) actually pauses the game, `true` by default.
		If you want to update your game while pause menu is open set it to `false`.
	**/
	public var canPause(default, set):Bool;

	public var gameObjects(default, null):FlxGroup = new FlxGroup();
	public var uiObjects(default, null):FlxGroup = new FlxGroup();

	/**
		For things that must be on top of anything;
	**/
	public var topLayer(default, null):FlxGroup = new FlxGroup();

	public var plugins(default, null):FlxGroup = new FlxGroup();

	public var timerManager(default, null):FlxTimerManager;
	public var tweenManager(default, null):FlxTweenManager;

	function set_canPause(v:Bool):Bool {
		persistentUpdate = !v;
		return canPause = v;
	}

	public function new() {
		super();
		canPause = true;
	}

	override function create() {
		super.create();

		bgColor = 0xFF222222;

		destroySubStates = false;

		plugins.add(timerManager = new FlxTimerManager());
		plugins.add(tweenManager = new FlxTweenManager());

		add(plugins);
		add(gameObjects);
		add(uiObjects);
		add(topLayer);
	}
}
