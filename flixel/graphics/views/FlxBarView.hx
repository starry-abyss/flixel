package flixel.graphics.views;

import flixel.ui.FlxBar;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * ...
 * @author Zaphod
 */
class FlxBarView extends FlxImage
{
	public var frontGraphic(default, set):FlxImage;
	
	public function new(Parent:FlxBar, BackGraphic:FlxGraphicAsset, FrontGraphic:FlxGraphicAsset) 
	{
		super(Parent, BackGraphic);
	}
	
	override function set_parent(Value:FlxBaseSprite<Dynamic>):FlxBaseSprite<Dynamic> 
	{
		super.set_parent(Value);
		
		if (frontGraphic != null)
			frontGraphic.parent = parent;
		
		return parent;
	}
	
	private function set_frontGraphic(Value:FlxImage):FlxImage
	{
		frontGraphic = Value;
		Value.parent = parent;
		return Value;
	}
	
	override public function draw():Void 
	{
		super.draw();
		frontGraphic.draw();
	}
}