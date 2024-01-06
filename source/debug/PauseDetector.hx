package debug;

#if debug
import flixel.FlxBasic;
import flixel.util.FlxSignal;

class PauseDetector extends FlxBasic {

	public var prevPaused(default, null):Bool;

	var signal:FlxTypedSignal<Bool->Void>;

	public function new(signal:FlxTypedSignal<Bool->Void>) {
		super();

		prevPaused = Flixel.vcr.paused;

		this.signal = signal;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Flixel.vcr.paused != prevPaused) {
			prevPaused = Flixel.vcr.paused;
			trace('PAUSE change DETECTED');
			signal.dispatch(Flixel.vcr.paused);
		}
	}
}
#end
