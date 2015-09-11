package flixel.graphics.views;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

// TODO: make most basic class which will be superclass of FlxBasic, and then extend it...

/**
 * ...
 * @author Zaphod
 */
class FlxGraphicPlugin implements IFlxDestroyable
{
	public var graphic:FlxGraphic;
	
	public function new(graphic:FlxGraphic) 
	{
		this.graphic = graphic;
	}
	
	public function destroy():Void
	{
		graphic = null;
	}
	
	public function update(elapsed:Float):Void
	{
		
	}
	
	public function draw():Void
	{
		
	}
}