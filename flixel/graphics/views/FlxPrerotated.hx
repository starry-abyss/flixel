package flixel.graphics.views;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxBitmapDataUtil;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * ...
 * @author Zaphod
 */
class FlxPrerotated extends FlxImage
{
	/**
	 * The minimum angle (out of 360°) for which a new baked rotation exists. Example: 90 means there 
	 * are 4 baked rotations in the spritesheet. 0 if this sprite does not have any baked rotations.
	 */
	public var bakedRotationAngle(default, null):Float = 0;
	
	private var rotations = 1;
	
	public function new(?Parent:FlxBaseSprite<Dynamic>, ?Graphic:FlxGraphicAsset) 
	{
		super(Parent, Graphic);
	}
	
	/**
	 * Create a pre-rotated sprite sheet from a simple sprite.
	 * This can make a huge difference in graphical performance!
	 * 
	 * @param	Graphic			The image you want to rotate and stamp.
	 * @param	Rotations		The number of rotation frames the final sprite should have.  For small sprites this can be quite a large number (360 even) without any problems.
	 * @param	Frame			If the Graphic has a single row of square animation frames on it, you can specify which of the frames you want to use here.  Default is -1, or "use whole graphic."
	 * @param	AntiAliasing	Whether to use high quality rotations when creating the graphic.  Default is false.
	 * @param	AutoBuffer		Whether to automatically increase the image size to accomodate rotated corners.  Default is false.  Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @param	Key				Optional, set this parameter if you're loading BitmapData.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadRotatedGraphic(Graphic:FlxGraphicAsset, Rotations:Int = 16, Frame:Int = -1, AntiAliasing:Bool = false, AutoBuffer:Bool = false, ?Key:String):FlxPrerotated
	{
		var brushGraphic:FlxTexture = FlxG.bitmap.add(Graphic, false, Key);
		if (brushGraphic == null)
		{
			return this;
		}
		
		var brush:BitmapData = brushGraphic.bitmap;
		var key:String = brushGraphic.key;
		
		if (Frame >= 0)
		{
			// we assume that source graphic has one row frame animation with equal width and height
			var brushSize:Int = brush.height;
			var framesNum:Int = Std.int(brush.width / brushSize);
			Frame = (framesNum > Frame) ? Frame : (Frame % framesNum);
			key += ":" + Frame;
			
			var full:BitmapData = brush;
			brush = new BitmapData(brushSize, brushSize, true, FlxColor.TRANSPARENT);
			_flashRect.setTo(Frame * brushSize, 0, brushSize, brushSize);
			brush.copyPixels(full, _flashRect, _flashPointZero);
		}
		
		key = key + ":" + Rotations + ":" + AutoBuffer;
		
		//Generate a new sheet if necessary, then fix up the width and height
		var tempGraph:FlxTexture = FlxG.bitmap.get(key);
		if (tempGraph == null)
		{
			var bitmap:BitmapData = FlxBitmapDataUtil.generateRotations(brush, Rotations, AntiAliasing, AutoBuffer);
			tempGraph = FlxTexture.fromBitmapData(bitmap, false, key);
		}
		
		var max:Int = (brush.height > brush.width) ? brush.height : brush.width;
		max = (AutoBuffer) ? Std.int(max * 1.5) : max;
		
		frames = FlxTileFrames.fromGraphic(tempGraph, new FlxPoint(max, max));
		
		if (AutoBuffer)
		{
			parent.width = brush.width;
			parent.height = brush.height;
			centerOffsets();
		}
		
		bakedRotationAngle = 360 / Rotations;
		rotations = Math.round(360 / bakedRotationAngle);
		return this;
	}
	
	/**
	 * Helper method which makes it possible to use FlxFrames as graphic source for sprite's loadRotatedGraphic() method 
	 * (since it accepts only FlxTexture, BitmapData and String types).
	 * 
	 * @param	frame			Frame to load into this sprite.
	 * @param	rotations		The number of rotation frames the final sprite should have. For small sprites this can be quite a large number (360 even) without any problems.
	 * @param	antiAliasing	Whether to use high quality rotations when creating the graphic. Default is false.
	 * @param	autoBuffer		Whether to automatically increase the image size to accomodate rotated corners.  Default is false.  Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @return	this FlxSprite with loaded rotated graphic in it.
	 */
	public function loadRotatedFrame(Frame:FlxFrame, Rotations:Int = 16, AntiAliasing:Bool = false, AutoBuffer:Bool = false):FlxPrerotated
	{
		var key:String = Frame.parent.key;
		if (Frame.name != null)
		{
			key += ":" + Frame.name;
		}
		else
		{
			key += ":" + Frame.frame.toString();
		}
		
		var graphic:FlxTexture = FlxG.bitmap.get(key);
		if (graphic == null)
		{
			graphic = FlxTexture.fromBitmapData(Frame.paint(), false, key);
		}
		
		return loadRotatedGraphic(graphic, Rotations, -1, AntiAliasing, AutoBuffer);
	}
	
	override public function isOnScreen(?Camera:FlxCamera):Bool
	{
		if (parent == null)
			return false;
		
		if (Camera == null)
			Camera = FlxG.camera;
		
		var minX:Float = parent.x - offset.x - Camera.scroll.x * scrollFactor.x;
		var minY:Float = parent.y - offset.y - Camera.scroll.y * scrollFactor.y;
		
		if ((angle == 0 || bakedRotationAngle > 0) && (scale.x == 1) && (scale.y == 1))
		{
			if (minX > Camera.width || minX + frameWidth < 0)
				return false;
			
			if (minY > Camera.height || minY + frameHeight < 0)
				return false;
		}
		else
		{
			var radiusX:Float = _halfSize.x;
			var radiusY:Float = _halfSize.y;
			
			var ox:Float = origin.x;
			if (ox != radiusX)
			{
				var x1:Float = Math.abs(ox);
				var x2:Float = Math.abs(frameWidth - ox);
				radiusX = Math.max(x2, x1);
			}
			
			var oy:Float = origin.y;
			if (oy != radiusY)
			{
				var y1:Float = Math.abs(oy);
				var y2:Float = Math.abs(frameHeight - oy);
				radiusY = Math.max(y2, y1);
			}
			
			radiusX *= Math.abs(scale.x);
			radiusY *= Math.abs(scale.y);
			var radius:Float = Math.max(radiusX, radiusY);
			radius *= FlxMath.SQUARE_ROOT_OF_TWO;
			
			minX += ox;
			var maxX:Float = minX + radius;
			minX -= radius;
			
			if (maxX < 0 || minX > Camera.width)
				return false;
			
			minY += oy;
			var maxY:Float = minY + radius;
			minY -= radius;
			
			if (maxY < 0 || minY > Camera.height)
				return false;
		}
		
		return true;
	}
	
	override public function isSimpleRenderBlit(?camera:FlxCamera):Bool
	{
		var result:Bool = (angle == 0 || bakedRotationAngle > 0)
			&& scale.x == 1 && scale.y == 1 && blend == null;
		result = result && (camera != null ? isPixelPerfectRender(camera) : pixelPerfectRender);
		return result;
	}
	
	override public function draw():Void
	{
		if (_frame == null)
		{
			#if !FLX_NO_DEBUG
			loadGraphic(FlxTexture.fromClass(FlxGraphic.GraphicDefault));
			#else
			return;
			#end
		}
		
		if (alpha == 0 || parent == null || _frame.type == FlxFrameType.EMPTY)
			return;
		
		if (dirty)	//rarely 
			calcFrame();
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
			getScreenPosition(_point, camera).subtractPoint(offset);
			
			var cr:Float = colorTransform.redMultiplier;
			var cg:Float = colorTransform.greenMultiplier;
			var cb:Float = colorTransform.blueMultiplier;
			
			var simple:Bool = isSimpleRender(camera);
			if (simple)
			{
				if (isPixelPerfectRender(camera))
					_point.floor();
				
				_point.copyToFlash(_flashPoint);
				camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, cr, cg, cb, alpha, blend, antialiasing);
			}
			else
			{
				_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, flipX, flipY);
				_matrix.translate( -origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				if (bakedRotationAngle <= 0)
				{
					updateTrig();
					if (angle != 0)
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}
				
				_point.add(origin.x, origin.y);
				if (isPixelPerfectRender(camera))
					_point.floor();
				
				_matrix.translate(_point.x, _point.y);
				camera.drawPixels(_frame, framePixels, _matrix, cr, cg, cb, alpha, blend, antialiasing);
			}
		}
	}
	
	override private function set_frames(Frames:FlxFramesCollection):FlxFramesCollection 
	{
		bakedRotationAngle = 0;
		rotations = 1;
		return super.set_frames(Frames);
	}
	
	override function set_angle(Value:Float):Float 
	{
		var oldIndex:Int = frameIndex;
		var rv = super.set_angle(Value);
		var angleHelper:Int = Math.floor(Value % 360);
		
		while (angleHelper < 0)
			angleHelper += 360;
		
		var newIndex:Int = Math.floor(angleHelper / bakedRotationAngle + 0.5);
		newIndex = Std.int(newIndex % rotations);
		
		if (oldIndex != newIndex)
			frameIndex = newIndex;
		
		return rv;
	}
}