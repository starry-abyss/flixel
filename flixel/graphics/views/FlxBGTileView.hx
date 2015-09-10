package flixel.graphics.views;

#if FLX_RENDER_TILE
import flixel.system.FlxBGSprite;
import flixel.util.FlxColor;

/**
 * ...
 * @author Zaphod
 */
class FlxBGTileView extends FlxImage
{

	public function new(Parent:FlxBGSprite) 
	{
		super(Parent);
		makeGraphic(1, 1, FlxColor.TRANSPARENT, true, FlxG.bitmap.getUniqueKey("bg_graphic_"));
		scrollFactor.set();
	}
	
	override public function draw():Void 
	{
		var cr:Float = colorTransform.redMultiplier;
		var cg:Float = colorTransform.greenMultiplier;
		var cb:Float = colorTransform.blueMultiplier;
		var ca:Float = colorTransform.alphaMultiplier;
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}
			
			_matrix.identity();
			_matrix.scale(camera.width, camera.height);
			camera.drawPixels(frame, _matrix, cr, cg, cb, ca);
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
#end