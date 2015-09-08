package flixel.graphics.views;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxRect;
import flixel.ui.FlxBar;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * ...
 * @author Zaphod
 */
class FlxBarView extends FlxImage
{
	#if FLX_RENDER_TILE
	public var frontGraphic(default, null):FlxImage;
	/**
	 * Rectangle used for cropping filled part of bar
	 */
	private var _filledFlxRect:FlxRect;
	#else
	private var _emptyBar:BitmapData;
	private var _emptyBarRect:Rectangle;
	
	private var _filledBar:BitmapData;
	
	private var _zeroOffset:Point;
	#end
	
	private var _filledBarRect:Rectangle;
	private var _filledBarPoint:Point;
	
	public var barWidth(default, null):Int;
	public var barHeight(default, null):Int;
	
	/**
	 * The direction from which the health bar will fill-up. Default is from left to right. Change takes effect immediately.
	 */
	public var fillDirection(default, set):FlxBarFillDirection;	
	private var _fillHorizontal:Bool;
	
	/**
	 * BarFrames which will be used for filled bar rendering.
	 * It is recommended to use this property in tile render mode
	 * (altrough it will work in blit render mode also).
	 */
	public var frontFrames(get, set):FlxImageFrame;
	
	public var backFrames(get, set):FlxImageFrame;
	
	/**
	 * How many pixels = 1% of the bar (barWidth (or barHeight) / 100)
	 */
	public var pxPerPercent(default, null):Float;
	
	private var _parentBar:FlxBar;
	
	public function new(Parent:FlxBar, ?direction:FlxBarFillDirection, width:Int = 100, height:Int = 10, showBorder:Bool = false) 
	{
		super(Parent);
		
		barWidth = width;
		barHeight = height;
		
		_filledBarPoint = new Point();
		_filledBarRect = new Rectangle();
		#if FLX_RENDER_BLIT
		_zeroOffset = new Point();
		_emptyBarRect = new Rectangle();
		makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		#else
		frontGraphic = new FlxImage(Parent);
		_filledFlxRect = FlxRect.get();
		#end
		
		fillDirection = (direction == null) ? FlxBarFillDirection.LEFT_TO_RIGHT : direction;
		createFilledBar(0xff005100, 0xff00F400, showBorder);
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		#if FLX_RENDER_TILE
		frontGraphic = FlxDestroyUtil.destroy(frontGraphic);
		_filledFlxRect = FlxDestroyUtil.put(_filledFlxRect);
		#else
		_emptyBarRect = null;
		_zeroOffset = null;
		_emptyBar = FlxDestroyUtil.dispose(_emptyBar);
		_filledBar = FlxDestroyUtil.dispose(_filledBar);
		#end
		_filledBarRect = null;
		_filledBarPoint = null;
	}
	
	/**
	 * Creates a solid-colour filled health bar in the given colours, with optional 1px thick border.
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * 
	 * @param	empty		The color of the bar when empty in 0xAARRGGBB format (the background colour)
	 * @param	fill		The color of the bar when full in 0xAARRGGBB format (the foreground colour)
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return	This FlxBar object with generated images for front and backround.
	 */
	public function createFilledBar(empty:Int, fill:Int, showBorder:Bool = false, border:Int = 0xffffffff):FlxBarView
	{
		createColoredEmptyBar(empty, showBorder, border);
		createColoredFilledBar(fill, showBorder, border);
		return this;
	}
	
	/**
	 * Creates a solid-colour filled background for health bar in the given colour, with optional 1px thick border.
	 * 
	 * @param	empty			The color of the bar when empty in 0xAARRGGBB format (the background colour)
	 * @param	showBorder		Should the bar be outlined with a 1px solid border?
	 * @param	border			The border colour in 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for rendering health bar backround.
	 */
	public function createColoredEmptyBar(empty:Int, showBorder:Bool = false, border:Int = 0xffffffff):FlxBarView
	{
	#if FLX_RENDER_TILE
		var emptyA:Int = (empty >> 24) & 255;
		var emptyRGB:Int = empty & 0x00ffffff;
		var borderA:Int = (border >> 24) & 255;
		var borderRGB:Int = border & 0x00ffffff;
		var emptyKey:String = "empty: " + barWidth + "x" + barHeight + ":" + emptyA + "." + emptyRGB;
		
		if (showBorder)
		{
			emptyKey += ",border: " + borderA + "." + borderRGB;
		}
		
		if (FlxG.bitmap.checkCache(emptyKey) == false)
		{
			var emptyBar:BitmapData = null;
			
			if (showBorder)
			{
				emptyBar = new BitmapData(barWidth, barHeight, true, border);
				emptyBar.fillRect(new Rectangle(1, 1, barWidth - 2, barHeight - 2), empty);
			}
			else
			{
				emptyBar = new BitmapData(barWidth, barHeight, true, empty);
			}
			
			FlxG.bitmap.add(emptyBar, false, emptyKey);
		}
		
		frames = FlxG.bitmap.get(emptyKey).imageFrame;
	#else
		if (showBorder)
		{
			_emptyBar = new BitmapData(barWidth, barHeight, true, border);
			_emptyBar.fillRect(new Rectangle(1, 1, barWidth - 2, barHeight - 2), empty);
		}
		else
		{
			_emptyBar = new BitmapData(barWidth, barHeight, true, empty);
		}
		
		_emptyBarRect.setTo(0, 0, barWidth, barHeight);
		updateEmptyBar();
	#end
		
		return this;
	}
	
	/**
	 * Creates a solid-colour filled foreground for health bar in the given colour, with optional 1px thick border.
	 * @param	fill		The color of the bar when full in 0xAARRGGBB format (the foreground colour)
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for rendering actual values.
	 */
	public function createColoredFilledBar(fill:Int, showBorder:Bool = false, border:Int = 0xffffffff):FlxBarView
	{
	#if FLX_RENDER_TILE
		var fillA:Int = (fill >> 24) & 255;
		var fillRGB:Int = fill & 0x00ffffff;
		var borderA:Int = (border >> 24) & 255;
		var borderRGB:Int = border & 0x00ffffff;
		
		var filledKey:String = "filled: " + barWidth + "x" + barHeight + ":" + fillA + "." + fillRGB;
		if (showBorder)
		{
			filledKey += ",border: " + borderA + "." + borderRGB;
		}
		
		if (FlxG.bitmap.checkCache(filledKey) == false)
		{
			var filledBar:BitmapData = null;
			
			if (showBorder)
			{
				filledBar = new BitmapData(barWidth, barHeight, true, border);
				filledBar.fillRect(new Rectangle(1, 1, barWidth - 2, barHeight - 2), fill);
			}
			else
			{
				filledBar = new BitmapData(barWidth, barHeight, true, fill);
			}
			
			FlxG.bitmap.add(filledBar, false, filledKey);
		}
		
		frontFrames = FlxG.bitmap.get(filledKey).imageFrame;
	#else
		if (showBorder)
		{
			_filledBar = new BitmapData(barWidth, barHeight, true, border);
			_filledBar.fillRect(new Rectangle(1, 1, barWidth - 2, barHeight - 2), fill);
		}
		else
		{
			_filledBar = new BitmapData(barWidth, barHeight, true, fill);
		}
		
		_filledBarRect.setTo(0, 0, barWidth, barHeight);
		updateFilledBar();
	#end
		
		return this;
	}
	
	/**
	 * Creates a gradient filled health bar using the given colour ranges, with optional 1px thick border.
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * 
	 * @param	empty		Array of colour values used to create the gradient of the health bar when empty, each colour must be in 0xAARRGGBB format (the background colour)
	 * @param	fill		Array of colour values used to create the gradient of the health bar when full, each colour must be in 0xAARRGGBB format (the foreground colour)
	 * @param	chunkSize	If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation	Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return 	This FlxBar object with generated images for front and backround.
	 */
	public function createGradientBar(empty:Array<Int>, fill:Array<Int>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false, border:Int = 0xffffffff):FlxBarView
	{
		createGradientEmptyBar(empty, chunkSize, rotation, showBorder, border);
		createGradientFilledBar(fill, chunkSize, rotation, showBorder, border);
		return this;
	}
	
	/**
	 * Creates a gradient filled background for health bar using the given colour range, with optional 1px thick border.
	 * 
	 * @param	empty			Array of colour values used to create the gradient of the health bar when empty, each colour must be in 0xAARRGGBB format (the background colour)
	 * @param	chunkSize		If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation		Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder		Should the bar be outlined with a 1px solid border?
	 * @param	border			The border colour in 0xAARRGGBB format
	 * @return 	This FlxBar object with generated image for backround rendering.
	 */
	public function createGradientEmptyBar(empty:Array<Int>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false, border:Int = 0xffffffff):FlxBarView
	{
	#if FLX_RENDER_TILE
		var colA:Int;
		var colRGB:Int;
		
		var emptyKey:String = "Gradient:" + barWidth + "x" + barHeight + ",colors:[";
		for (col in empty)
		{
			colA = (col >> 24) & 255;
			colRGB = col & 0x00ffffff;
			
			emptyKey = emptyKey + colA + "." + colRGB + ",";
		}
		emptyKey = emptyKey + "],chunkSize: " + chunkSize + ",rotation: " + rotation;
		
		if (showBorder)
		{
			var borderA:Int = (border >> 24) & 255;
			var borderRGB:Int = border & 0x00ffffff;
			
			emptyKey = emptyKey + ",border: " + borderA + "." + borderRGB;
		}
		
		if (FlxG.bitmap.checkCache(emptyKey) == false)
		{
			var emptyBar:BitmapData = null;
			
			if (showBorder)
			{
				emptyBar = new BitmapData(barWidth, barHeight, true, border);
				FlxGradient.overlayGradientOnBitmapData(emptyBar, barWidth - 2, barHeight - 2, empty, 1, 1, chunkSize, rotation);
			}
			else
			{
				emptyBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, empty, chunkSize, rotation);
			}
			
			FlxG.bitmap.add(emptyBar, false, emptyKey);
		}
		
		frames = FlxG.bitmap.get(emptyKey).imageFrame;
	#else
		if (showBorder)
		{
			_emptyBar = new BitmapData(barWidth, barHeight, true, border);
			FlxGradient.overlayGradientOnBitmapData(_emptyBar, barWidth - 2, barHeight - 2, empty, 1, 1, chunkSize, rotation);
		}
		else
		{
			_emptyBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, empty, chunkSize, rotation);
		}
		
		_emptyBarRect.setTo(0, 0, barWidth, barHeight);
		updateEmptyBar();
	#end
		
		return this;
	}
	
	/**
	 * Creates a gradient filled foreground for health bar using the given colour range, with optional 1px thick border.
	 * 
	 * @param	fill		Array of colour values used to create the gradient of the health bar when full, each colour must be in 0xAARRGGBB format (the foreground colour)
	 * @param	chunkSize	If you want a more old-skool looking chunky gradient, increase this value!
	 * @param	rotation	Angle of the gradient in degrees. 90 = top to bottom, 180 = left to right. Any angle is valid
	 * @param	showBorder	Should the bar be outlined with a 1px solid border?
	 * @param	border		The border colour in 0xAARRGGBB format
	 * @return 	This FlxBar object with generated image for rendering actual values.
	 */
	public function createGradientFilledBar(fill:Array<Int>, chunkSize:Int = 1, rotation:Int = 180, showBorder:Bool = false, border:Int = 0xffffffff):FlxBarView
	{
		#if FLX_RENDER_TILE
		var colA:Int;
		var colRGB:Int;
		
		var filledKey:String = "Gradient:" + barWidth + "x" + barHeight + ",colors:[";
		for (col in fill)
		{
			colA = (col >> 24) & 255;
			colRGB = col & 0x00ffffff;
			
			filledKey = filledKey + colA + "_" + colRGB + ",";
		}
		filledKey = filledKey + "],chunkSize: " + chunkSize + ",rotation: " + rotation;
		
		if (showBorder)
		{
			var borderA:Int = (border >> 24) & 255;
			var borderRGB:Int = border & 0x00ffffff;
			
			filledKey += ",border: " + borderA + "." + borderRGB;
		}
		
		if (FlxG.bitmap.checkCache(filledKey) == false)
		{
			var filledBar:BitmapData = null;
			
			if (showBorder)
			{
				filledBar = new BitmapData(barWidth, barHeight, true, border);
				FlxGradient.overlayGradientOnBitmapData(filledBar, barWidth - 2, barHeight - 2, fill, 1, 1, chunkSize, rotation);
			}
			else
			{
				filledBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, fill, chunkSize, rotation);
			}
			
			FlxG.bitmap.add(filledBar, false, filledKey);
		}
		
		frontFrames = FlxG.bitmap.get(filledKey).imageFrame;
		#else
		if (showBorder)
		{
			_filledBar = new BitmapData(barWidth, barHeight, true, border);
			FlxGradient.overlayGradientOnBitmapData(_filledBar, barWidth - 2, barHeight - 2, fill, 1, 1, chunkSize, rotation);	
		}
		else
		{
			_filledBar = FlxGradient.createGradientBitmapData(barWidth, barHeight, fill, chunkSize, rotation);
		}
		
		_filledBarRect.setTo(0, 0, barWidth, barHeight);
		updateFilledBar();
		#end
		
		return this;
	}
	
	/**
	 * Creates a health bar filled using the given bitmap images.
	 * You can provide "empty" (background) and "fill" (foreground) images. either one or both images (empty / fill), and use the optional empty/fill colour values 
	 * All colour values are in 0xAARRGGBB format, so if you want a slightly transparent health bar give it lower AA values.
	 * NOTE: This method doesn't check if the empty image doesn't have the same size as fill image.
	 * 
	 * @param	empty				Bitmap image used as the background (empty part) of the health bar, if null the emptyBackground colour is used
	 * @param	fill				Bitmap image used as the foreground (filled part) of the health bar, if null the fillBackground colour is used
	 * @param	emptyBackground		If no background (empty) image is given, use this colour value instead. 0xAARRGGBB format
	 * @param	fillBackground		If no foreground (fill) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated images for front and backround.
	 */
	public function createImageBar(?empty:FlxGraphicAsset, ?fill:FlxGraphicAsset, emptyBackground:Int = 0xff000000, fillBackground:Int = 0xff00ff00):FlxBarView
	{
		createImageEmptyBar(empty, emptyBackground);
		createImageFilledBar(fill, fillBackground);
		return this;
	}
	
	/**
	 * Loads given bitmap image for health bar background.
	 * 
	 * @param	empty				Bitmap image used as the background (empty part) of the health bar, if null the emptyBackground colour is used
	 * @param	emptyBackground		If no background (empty) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for backround rendering.
	 */
	public function createImageEmptyBar(?empty:FlxGraphicAsset, emptyBackground:Int = 0xff000000):FlxBarView
	{
		if (empty != null)
		{
			var emptyGraphic:FlxTexture = FlxG.bitmap.add(empty);
		
			#if FLX_RENDER_TILE
			frames = emptyGraphic.imageFrame;
			#else
			_emptyBar = emptyGraphic.bitmap.clone();
			
			barWidth = _emptyBar.width;
			barHeight = _emptyBar.height;
			
			_emptyBarRect.setTo(0, 0, barWidth, barHeight);
			
			if (texture == null || (frame.sourceSize.x != barWidth || frame.sourceSize.y != barHeight))
			{
				makeGraphic(barWidth, barHeight, FlxColor.TRANSPARENT, true);
			}
			
			updateEmptyBar();
			#end
		}
		else
		{
			createColoredEmptyBar(emptyBackground);
		}
		
		return this;
	}
	
	/**
	 * Loads given bitmap image for health bar foreground.
	 * 
	 * @param	fill				Bitmap image used as the foreground (filled part) of the health bar, if null the fillBackground colour is used
	 * @param	fillBackground		If no foreground (fill) image is given, use this colour value instead. 0xAARRGGBB format
	 * @return	This FlxBar object with generated image for rendering actual values.
	 */
	public function createImageFilledBar(?fill:FlxGraphicAsset, fillBackground:Int = 0xff00ff00):FlxBarView
	{
		if (fill != null)
		{
			var filledGraphic:FlxTexture = FlxG.bitmap.add(fill);
		
			#if FLX_RENDER_TILE
			frontFrames = filledGraphic.imageFrame;
			#else
			_filledBar = filledGraphic.bitmap.clone();
			
			_filledBarRect.setTo(0, 0, barWidth, barHeight);
			
			if (texture == null || (frame.sourceSize.x != barWidth || frame.sourceSize.y != barHeight))
			{
				makeGraphic(barWidth, barHeight, FlxColor.TRANSPARENT, true);
			}
			
			pxPerPercent = (_fillHorizontal) ? (barWidth / 100) : (barHeight / 100);
			updateFilledBar();
			#end
		}
		else
		{
			createColoredFilledBar(fillBackground);
		}
		
		return this;
	}
	
	/**
	 * Stamps health bar background on its pixels
	 */
	public function updateEmptyBar():Void
	{
		#if FLX_RENDER_BLIT
		pixels.copyPixels(_emptyBar, _emptyBarRect, _zeroOffset);
		dirty = true;
		#end
	}
	
	/**
	 * Stamps health bar foreground on its pixels
	 */
	public function updateFilledBar():Void
	{
		_filledBarRect.width = barWidth;
		_filledBarRect.height = barHeight;
		
		var percent:Float = _parentBar.percent;
		
		if (_fillHorizontal)
		{
			_filledBarRect.width = Std.int(percent * pxPerPercent);
		}
		else
		{
			_filledBarRect.height = Std.int(percent * pxPerPercent);
		}
		
		if (percent > 0)
		{
			switch (fillDirection)
			{
				case LEFT_TO_RIGHT, TOP_TO_BOTTOM:
					//	Already handled above
				
				case BOTTOM_TO_TOP:
					_filledBarRect.y = barHeight - _filledBarRect.height;
					_filledBarPoint.y = barHeight - _filledBarRect.height;
					
				case RIGHT_TO_LEFT:
					_filledBarRect.x = barWidth - _filledBarRect.width;
					_filledBarPoint.x = barWidth - _filledBarRect.width;
					
				case HORIZONTAL_INSIDE_OUT:
					_filledBarRect.x = Std.int((barWidth / 2) - (_filledBarRect.width / 2));
					_filledBarPoint.x = Std.int((barWidth / 2) - (_filledBarRect.width / 2));
				
				case HORIZONTAL_OUTSIDE_IN:
					_filledBarRect.width = Std.int(100 - percent * pxPerPercent);
					_filledBarPoint.x = Std.int((barWidth - _filledBarRect.width) / 2);
				
				case VERTICAL_INSIDE_OUT:
					_filledBarRect.y = Std.int((barHeight / 2) - (_filledBarRect.height / 2));
					_filledBarPoint.y = Std.int((barHeight / 2) - (_filledBarRect.height / 2));
					
				case VERTICAL_OUTSIDE_IN:
					_filledBarRect.height = Std.int(100 - percent * pxPerPercent);
					_filledBarPoint.y = Std.int((barHeight - _filledBarRect.height) / 2);
			}
			
			#if FLX_RENDER_BLIT
			pixels.copyPixels(_filledBar, _filledBarRect, _filledBarPoint, null, null, true);
			#else
			if (frontFrames != null)
			{
				var prct:Int = Std.int(percent);
				_filledFlxRect.copyFromFlash(_filledBarRect).round();
				frontGraphic.clipRect = _filledFlxRect;
			}
			#end
		}
		
		#if FLX_RENDER_BLIT
		dirty = true;
		#end
	}
	
	/**
	 * Updates health bar view according its current value.
	 * Called when the health bar detects a change in the health of the parent.
	 */
	public function updateBar():Void
	{
		updateEmptyBar();
		updateFilledBar();
	}
	
	#if FLX_RENDER_TILE
	override public function draw():Void 
	{
		super.draw();
		
		if (_parentBar.percent <= 0)
			return;
		
		updateFrontGraphic();
		frontGraphic.draw();
	}
	
	override private function set_pixels(Pixels:BitmapData):BitmapData
	{
		return Pixels; // hack
	}
	
	private inline function updateFrontGraphic():Void
	{
		frontGraphic.scale.copyFrom(scale);
		frontGraphic.origin.copyFrom(origin);
		frontGraphic.offset.copyFrom(offset);
	}
	
	override function set_parent(Value:FlxBaseSprite<Dynamic>):FlxBaseSprite<Dynamic> 
	{
		super.set_parent(Value);
		_parentBar = cast Value;
		frontGraphic.parent = Value;
		return Value;
	}
	
	override function set_angle(Value:Float):Float 
	{
		super.set_angle(Value);
		frontGraphic.angle = Value;
		return Value;
	}
	
	override function set_color(Color:FlxColor):Int 
	{
		super.set_color(Color);
		frontGraphic.color = Color;
		return Color;
	}
	
	override function set_alpha(Alpha:Float):Float 
	{
		super.set_alpha(Alpha);
		frontGraphic.alpha = Alpha;
		return Alpha;
	}
	
	override function set_camera(Value:FlxCamera):FlxCamera 
	{
		super.set_camera(Value);
		frontGraphic.camera = Value;
		return Value;
	}
	
	override function set_cameras(Value:Array<FlxCamera>):Array<FlxCamera> 
	{
		super.set_cameras(Value);
		frontGraphic.cameras = Value;
		return Value;
	}
	#end
	
	private function set_fillDirection(direction:FlxBarFillDirection):FlxBarFillDirection
	{
		fillDirection = direction;
		
		switch (direction)
		{
			case LEFT_TO_RIGHT, RIGHT_TO_LEFT, HORIZONTAL_INSIDE_OUT, HORIZONTAL_OUTSIDE_IN:
				_fillHorizontal = true;
				
			case TOP_TO_BOTTOM, BOTTOM_TO_TOP, VERTICAL_INSIDE_OUT, VERTICAL_OUTSIDE_IN:
				_fillHorizontal = false;
		}
		
		pxPerPercent = (_fillHorizontal) ? (barWidth / 100) : (barHeight / 100);
		return fillDirection;
	}
	
	private function get_frontFrames():FlxImageFrame
	{
		#if FLX_RENDER_TILE
		return cast frontGraphic.frames;
		#end
		return null;
	}
	
	private function set_frontFrames(value:FlxImageFrame):FlxImageFrame
	{
		#if FLX_RENDER_TILE
		frontGraphic.frames = value;
		#else
		createImageFilledBar(value.frame.paint());
		#end
	//	updateFilledBar();
		return value;
	}
	
	private function get_backFrames():FlxImageFrame
	{
		#if FLX_RENDER_TILE
		return cast(frames, FlxImageFrame);
		#end
		return null;
	}
	
	private function set_backFrames(value:FlxImageFrame):FlxImageFrame
	{
		#if FLX_RENDER_TILE
		frames = value;
		#else
		createImageEmptyBar(value.frame.paint());
		#end
		return value;
	}
}