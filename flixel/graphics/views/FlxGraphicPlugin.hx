package flixel.graphics.views;

import flixel.FlxAtomic;
import flixel.FlxBaseSprite;
import flixel.FlxObject;
import flixel.FlxObjectPlugin;

/**
 * ...
 * @author Zaphod
 */
class FlxGraphicPlugin extends FlxObjectPlugin
{
	public var graphic:FlxGraphic;
	
	public function new(sprite:FlxBaseSprite) 
	{
		super(sprite);
		this.graphic = sprite.graphic;
	}
	
	override public function destroy():Void
	{
		super.destroy();
		graphic = null;
	}
}