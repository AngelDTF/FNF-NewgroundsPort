package;

import flixel.FlxSprite;
import flixel.system.FlxSound;

class TankCutscene extends FlxSprite
{
	public var startSyncAudio:FlxSound;

	var startedPlayingSound:Bool;

	override public function new(x:Float = 0, y:Float = 0)
	{
		startedPlayingSound = false;
		super(x, y);
	}

	override public function update(elapsed:Float)
	{
		if (animation.curAnim.curFrame <= 1 && !startedPlayingSound)
		{
			startSyncAudio.play();
			startedPlayingSound = true;
		}

		super.update(elapsed);
	}
}
