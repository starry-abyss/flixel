package flixel;
import flixel.graphics.views.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;

/**
 * ...
 * @author Zaphod
 */
class FlxBaseSprite<T:FlxGraphic> extends FlxObject
{
	public var graphic(default, set):T;
	
	/**
	 * Controls how much this object is affected by camera scrolling. 0 = no movement (e.g. a background layer), 
	 * 1 = same movement speed as the foreground. Default value is (1,1), except for UI elements like FlxButton where it's (0,0).
	 */
	public var scrollFactor(get, null):FlxPoint;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?Graphic:T) 
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
	
	private function set_graphic(Value:T):T
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
	
	private function get_scrollFactor():FlxPoint 
	{
		if (graphic != null)
			return graphic.scrollFactor;
			
		return null;
	}
}