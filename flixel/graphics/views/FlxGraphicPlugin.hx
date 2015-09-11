package flixel.graphics.views;

import flixel.FlxAtomic;

/**
 * ...
 * @author Zaphod
 */
class FlxGraphicPlugin extends FlxAtomic
{
	public var graphic:FlxGraphic;
	
	public function new(graphic:FlxGraphic) 
	{
		super();
		this.graphic = graphic;
	}
	
	override public function destroy():Void
	{
		graphic = null;
	}
	
	override public function update(elapsed:Float):Void
	{
		
	}
	
	override public function draw():Void
	{
		
	}
}