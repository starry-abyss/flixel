package flixel;
import flixel.graphics.views.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;

/**
 * ...
 * @author Zaphod
 */
class FlxImage extends FlxObject
{
	public var graphic(default, set):FlxGraphic;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?Graphic:FlxGraphic) 
	{
		super(X, Y);
		graphic = Graphic;
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		graphic = FlxDestroyUtil.destroy(graphic);
	}
	
	override public function draw():Void 
	{
		if (graphic != null && graphic.visible)
			graphic.draw();
		
		#if !FLX_NO_DEBUG
		super.draw();
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if (graphic != null && graphic.active)
			graphic.update(elapsed);
	}
	
	private function set_graphic(Value:FlxGraphic):FlxGraphic
	{
		graphic = Value;
		
		if (graphic != null)
		{
			graphic.parent = this;
			width = graphic.frameWidth;
			height = graphic.frameHeight;
		}
		
		return graphic;
	}
}