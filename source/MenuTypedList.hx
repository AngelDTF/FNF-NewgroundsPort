package;

import flixel.effects.FlxFlicker;
import MainMenuState.MainMenuItem;
import flixel.FlxG;
import haxe.ds.StringMap;
import flixel.group.FlxGroup.FlxTypedGroup;

enum Direction
{
	Horizontal;
	Vertical;
	Both;
	None;
}

class MenuTypedList extends FlxTypedGroup<MainMenuItem>
{
	public var busy:Bool;
	public var byName:StringMap<MainMenuItem>;
	public var wrapMode:Direction;
	public var enabled:Bool;
	public var selectedIndex:Int;
	public var navControls:Direction;

	public var onChange:Dynamic;
	public var onAcceptPress:Dynamic;

	private var controls(get, never):Controls;
	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public function new(dir:Direction = null, wrapDir:Direction = null)
	{
		if (dir == null) dir = Vertical;
		busy = false;
		byName = new StringMap<MainMenuItem>();
		wrapMode = Both;
		enabled = true;
		selectedIndex = 0;
		navControls = dir;
		if (wrapDir != null) wrapMode = wrapDir;
		else
		{
			switch (dir)
			{
				case Horizontal:
					dir = Horizontal;
				case Vertical:
					dir = Vertical;
				default:
					dir = Both;
			}
			wrapMode = dir;
		}
		super();
	}

	public function addItem(name:String, item:MainMenuItem)
	{
		if (length == selectedIndex) item.select();
		byName.set(name, item);
		return add(item);
	}

	public function resetItem(name, newName, c)
	{
		if (!byName.exists(name)) throw ("No item named:"+name);
		var item = byName.get(name);
		if (byName.exists(name)) byName.remove(name);
		byName.set(newName, item);
		item.setItem(newName, c);
		return item;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		var b, c, d, e, f, g;
		switch (wrapMode)
		{
			case Horizontal | Both:
				b = true;
			default:
				b = false;
		}
		switch (wrapMode)
		{
			case Vertical | Both:
				c = true;
			default:
				c = false;
		}
		d = navControls;
		switch (d)
		{
			case Horizontal:
				e = controls.UI_LEFT_P;
				f = controls.UI_RIGHT_P;
				g = navAxis(selectedIndex, length, e, f, b);
			case Vertical:
				e = controls.UI_UP_P;
				f = controls.UI_DOWN_P;
				g = navAxis(selectedIndex, length, e, f, c);
			case Both:
				e = controls.UI_LEFT_P || controls.UI_UP_P;
				f = controls.UI_RIGHT_P || controls.UI_DOWN_P;
				g = navAxis(selectedIndex, length, e, f, wrapMode != None);
			case None:
				g = navGrid(3, controls.UI_LEFT_P, controls.UI_RIGHT_P, b, controls.UI_UP_P, controls.UI_DOWN_P, c);
			default:
				g = navGrid(4, controls.UI_UP_P, controls.UI_DOWN_P, c, controls.UI_LEFT_P, controls.UI_RIGHT_P, b);
		}
		if (g != selectedIndex)
		{
			FlxG.sound.play(Paths.sound("scrollMenu"));
			selectItem(g);
		}
		if (controls.ACCEPT) accept();
	}

	function navAxis(a, b, c, d, e)
	{
		if (c == d) return a;
		c ? 0 < a ? --a : if (e) a = b - 1 : a < b - 1 ? ++a : if (e) a = 0;
		return a;
	}

	function navGrid(a, b, c, d, e, f, h)
	{
		var m = Math.ceil(this.length / a),
			n = Math.floor(this.selectedIndex / a),
			k = this.selectedIndex % a;
		k = this.navAxis(k, a, b, c, d);
		n = this.navAxis(n, m, e, f, h);
		return Std.int(Math.min(this.length - 1, n * a + k));
	}

	public function accept()
	{
		var selected = members[selectedIndex];
		if (onAcceptPress != null) onAcceptPress(selected);
		if (selected.fireInstantly)
		{
			selected.callback();
		}
		else
		{
			busy = true;
			FlxG.sound.play(Paths.sound("confirmMenu"));
			FlxFlicker.flicker(selected, 1, 0.06, true, false, function(flicker)
			{
				busy = false;
				selected.callback();
			});
		}
	}

	public function selectItem(index:Int)
	{
		members[selectedIndex].idle();
		selectedIndex = index;
		members[selectedIndex].select();
		if (onChange != null) onChange(members[selectedIndex]);
	}

	public function has(name:String)
	{
		return byName.exists(name);
	}

	public function getItem(name:String)
	{
		return byName.get(name);
	}
}