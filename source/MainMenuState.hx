package;

import flixel.util.FlxTimer;
import flixel.util.FlxSave;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import ui.AtlasMenuItem;
import ui.MenuTypedList;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:MainMenuList;

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.17;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.x = bg.scrollFactor.x;
		magenta.scrollFactor.y = bg.scrollFactor.y;
		magenta.setGraphicSize(Std.int(bg.width));
		magenta.updateHitbox();
		magenta.x = bg.x;
		magenta.y = bg.y;
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFFD719B;
		if (ClientPrefs.flashingMenu) add(magenta);

		menuItems = new MainMenuList();
		add(menuItems);
		menuItems.onChange = onMenuItemChange;
		menuItems.onAcceptPress = function(b)
		{
			FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
		}
		
		var gsave:FlxSave = new FlxSave();
		gsave.bind('gamedata', 'newgrounds');

		menuItems.createItem(0, 0, "story mode", function()
		{
			startExitState(new StoryMenuState());
		});
		menuItems.createItem(0, 0, "freeplay", function()
		{
			startExitState(new FreeplayState());
		});
		if (gsave.data.seenTrailer == true)
		{
			menuItems.createItem(0, 0, "kickstarter", selectDonate, true);
		}
		else
		{
			menuItems.createItem(0, 0, "donate", selectDonate, true);
		}
		menuItems.createItem(0, 0, "options", function()
		{
			startExitState(new OptionsState());
		});

		// sorry for this looking so shitty, literally reverse engineering this and I have no var names
		var curItem, daWeirdVar = (FlxG.height - 160 * (menuItems.length - 1)) / 2;
		for (i in 0...menuItems.length)
		{
			curItem = menuItems.members[i];
			curItem.x = FlxG.width / 2;
			curItem.y = daWeirdVar + 160 * i;
		}
		// end of the shittiness...for now

		FlxG.camera.follow(camFollow, null, 0.06);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, "v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		versionShit.text += "(Newgrounds exclusive preview)";

		super.create();
	}

	override function update(elapsed:Float)
	{
		FlxG.camera.followLerp = CoolUtil.camLerpShit(0.06);

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		if (_exiting) menuItems.enabled = false;
		if (controls.BACK && menuItems.enabled && !menuItems.busy)
		{
			FlxG.switchState(new TitleState());
		}

		super.update(elapsed);
	}

	function startExitState(whereWeGoing:Dynamic)
	{
		menuItems.enabled = false;
		menuItems.forEach(function(item)
		{
			if (menuItems.selectedIndex != item.ID)
			{
				FlxTween.tween(item, { alpha: 0 }, 0.4, { ease: FlxEase.quadOut });
			}
			else
			{
				item.visible = false;
			}
		});
		new FlxTimer().start(0.4, function(tmr:FlxTimer)
		{
			FlxG.switchState(whereWeGoing);
		});
	}

	function onMenuItemChange(item:MainMenuItem)
	{
		camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y);
	}

	function selectDonate()
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', ["https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game", "&"]);
		#else
		FlxG.openURL('https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game');
		#end
	}
}

class MainMenuItem extends AtlasMenuItem
{
	public function new(X:Float = 0, Y:Float = 0, name:String, atlas:FlxAtlasFrames, callback:Dynamic)
	{
		super(X, Y, name, atlas, callback);
		this.scrollFactor.set();
		fireInstantly = false;
	}

	public override function changeAnim(anim:String)
	{
		super.changeAnim(anim);
		origin.set(0.5 * frameWidth, 0.5 * frameHeight);
		offset.x = origin.x;
		offset.y = origin.y;
		origin.putWeak();
	}
}

class MainMenuList extends MenuTypedList
{
	var atlas:FlxAtlasFrames;

	public function new()
	{
		atlas = Paths.getSparrowAtlas('main_menu');
		super(Vertical);
	}

	public function createItem(X:Float = 0, Y:Float = 0, name:String, callback:Dynamic = null, fireInstantly:Bool = false)
	{
		var a = new MainMenuItem(X, Y, name, this.atlas, callback);
		a.fireInstantly = fireInstantly;
		a.ID = this.length;
		return this.addItem(name, a);
	}
}