package flixel.system;
import flixel.graphics.views.FlxBGTileView;

#if FLX_RENDER_TILE
import flixel.FlxSprite;

class FlxBGSprite extends FlxSprite
{
	public function new()
	{
		super();
		graphic = new FlxBGTileView(this);
	}
}
#end