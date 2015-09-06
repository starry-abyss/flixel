package flixel.text;

import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flixel.FlxBaseSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.atlas.FlxNode;
import flixel.graphics.FlxTexture;
import flixel.graphics.views.FlxTextBuffer;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText.FlxTextFormat;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxRange;
import openfl.Assets;
using StringTools;

// TODO: think about filters and text

/**
 * Extends FlxSprite to support rendering text. Can tint, fade, rotate and scale just like a sprite. Doesn't really animate 
 * though, as far as I know. Also does nice pixel-perfect centering on pixel fonts as long as they are only one liners.
 */
class FlxText extends FlxBaseSprite<FlxTextBuffer>
{
	/**
	 * The text being displayed.
	 */
	public var text(get, set):String;
	
	/**
	 * The size of the text being displayed in pixels.
	 */
	public var size(get, set):Int;
	
	/**
	 * The font used for this text (assuming that it's using embedded font).
	 */
	public var font(get, set):String;
	
	/**
	 * Whether this text field uses an embedded font (by default) or not. 
	 * Read-only - use systemFont to specify a system font to use, which then automatically sets this to false.
	 */
	public var embedded(get, never):Bool;
	
	/**
	 * The system font for this text (not embedded). Setting this sets embedded to false.
	 * Passing an invalid font name (like "" or null) causes a default font to be used. 
	 */
	public var systemFont(get, set):String;
	
	/**
	 * Whether to use bold text or not (false by default).
	 */
	public var bold(get, set):Bool;
	
	/**
	 * Whether to use italic text or not (false by default). It only works in Flash.
	 */
	public var italic(get, set):Bool;
	
	/**
	 * Whether to use word wrapping and multiline or not (true by default).
	 */
	public var wordWrap(get, set):Bool;
	
	/**
	 * The alignment of the font (LEFT, RIGHT, CENTER or JUSTIFY).
	 * Note: 'autoSize' must be set to false or alignment won't show any visual differences.
	 */
	public var alignment(get, set):FlxTextAlign;
	
	/**
	 * Use a border style
	 */	
	public var borderStyle(get, set):FlxTextBorderStyle;
	
	/**
	 * The color of the border in 0xAARRGGBB format
	 */	
	public var borderColor(get, set):FlxColor;
	
	/**
	 * The size of the border, in pixels.
	 */
	public var borderSize(get, set):Float;
	
	/**
	 * How many iterations do use when drawing the border. 0: only 1 iteration, 1: one iteration for every pixel in borderSize
	 * A value of 1 will have the best quality for large border sizes, but might reduce performance when changing text. 
	 * NOTE: If the borderSize is 1, borderQuality of 0 or 1 will have the exact same effect (and performance).
	 */
	public var borderQuality(get, set):Float;
	
	/**
	 * Internal reference to a Flash TextField object.
	 */
	public var textField(get, null):TextField;
	
	/**
	 * The width of the TextField object used for bitmap generation for this FlxText object.
	 * Use it when you want to change the visible width of text. Enables autoSize if <= 0.
	 */
	public var fieldWidth(get, set):Float;
	
	/**
	 * Whether the fieldWidth should be determined automatically. Requires wordWrap to be false.
	 */
	public var autoSize(get, set):Bool;
	
	public var color(get, set):FlxColor;
	
	public var alpha(get, set):Float;
	
	/**
	 * Creates a new FlxText object at the specified position.
	 * 
	 * @param   X              The X position of the text.
	 * @param   Y              The Y position of the text.
	 * @param   FieldWidth     The width of the text object. Enables autoSize if <= 0.
	 *                         (height is determined automatically).
	 * @param   Text           The actual text you would like to display initially.
	 * @param   Size           The font size for this text object.
	 * @param   EmbeddedFont   Whether this text field uses embedded fonts or not.
	 */
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y);
		graphic = new FlxTextBuffer(this, FieldWidth, Text, Size, EmbeddedFont);
		allowCollisions = FlxObject.NONE;
		moves = false;
	}
	
	/**
	 * Stamps text onto specified atlas object and loads graphic from this atlas.
	 * WARNING: Changing text after stamping it on the atlas will break the atlas, 
	 * so do it only for static texts and only after making all the text customizing (like size, align, color, etc.)
	 * 
	 * @param	atlas	atlas to stamp graphic to.
	 * @return	true - if text's graphic is stamped on atlas successfully, false - in other case.
	 */
	public function stampOnAtlas(atlas:FlxAtlas):Bool
	{
		return graphic.stampOnAtlas(atlas);
	}
	
	/**
	 * Applies formats to text between marker strings, then removes those markers.
	 * NOTE: This will clear all FlxTextFormats and return to the default format.
	 * 
	 * Usage: 
	 * 
	 *    t.applyMarkup("show $green text$ between dollar-signs", [new FlxTextFormatMarkerPair(greenFormat, "$")]);
	 * 
	 * Even works for complex nested formats like this:
	 * 
	 *    yellow = new FlxTextFormatMarkerPair(yellowFormat, "@");
	 *    green = new FlxTextFormatMarkerPair(greenFormat, "$");
	 *    t.applyMarkup("HEY_BUDDY_@WHAT@_$IS_$_GOING@ON$?$@", [yellow, green]);
	 * 
	 * @param   input   The text you want to format
	 * @param   rules   FlxTextFormats to selectively apply, paired with marker strings such as "@" or "$"
	 */
	public function applyMarkup(input:String, rules:Array<FlxTextFormatMarkerPair>):Void
	{
		graphic.applyMarkup(input, rules);
	}
	
	/**
	 * Adds another format to this FlxText
	 * 
	 * @param	Format	The format to be added.
	 * @param	Start	(Default = -1) The start index of the string where the format will be applied.
	 * @param	End		(Default = -1) The end index of the string where the format will be applied.
	 */
	public function addFormat(Format:FlxTextFormat, Start:Int = -1, End:Int = -1):Void
	{
		graphic.addFormat(Format, Start, End);
	}
	
	/**
	 * Removes a specific FlxTextFormat from this text.
	 * If a range is specified, this only removes the format when it touches that range.
	 */
	public function removeFormat(Format:FlxTextFormat, ?Start:Int, ?End:Int):Void
	{
		graphic.removeFormat(Format, Start, End);
	}
	
	/**
	 * Clears all the formats applied.
	 */
	public function clearFormats():Void
	{
		graphic.clearFormats();
	}
	
	/**
	 * You can use this if you have a lot of text parameters
	 * to set instead of the individual properties.
	 * 
	 * @param	Font			The name of the font face for the text display.
	 * @param	Size			The size of the font (in pixels essentially).
	 * @param	Color			The color of the text in traditional flash 0xRRGGBB format.
	 * @param	Alignment		The desired alignment
	 * @param	BorderStyle		NONE, SHADOW, OUTLINE, or OUTLINE_FAST (use setBorderFormat)
	 * @param	BorderColor 	Int, color for the border, 0xAARRGGBB format
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 * @return	This FlxText instance (nice for chaining stuff together, if you're into that).
	 */
	public function setFormat(?Font:String, Size:Int = 8, Color:FlxColor = FlxColor.WHITE, ?Alignment:FlxTextAlign, 
		?BorderStyle:FlxTextBorderStyle, BorderColor:FlxColor = FlxColor.TRANSPARENT, Embedded:Bool = true):FlxText
	{
		graphic.setFormat(Font, Size, Color, Alignment, BorderStyle, BorderColor, Embedded);
		return this;
	}
	
	/**
	 * Set border's style (shadow, outline, etc), color, and size all in one go!
	 * 
	 * @param	Style outline style
	 * @param	Color outline color in 0xAARRGGBB format
	 * @param	Size outline size in pixels
	 * @param	Quality outline quality - # of iterations to use when drawing. 0:just 1, 1:equal number to BorderSize
	 */
	public function setBorderStyle(Style:FlxTextBorderStyle, Color:FlxColor = 0, Size:Float = 1, Quality:Float = 1):Void 
	{
		graphic.setBorderStyle(Style, Color, Size, Quality);
	}
	
	public function drawFrame(Force:Bool = false):Void
	{
		graphic.drawFrame(Force);
	}
	
	private function set_fieldWidth(value:Float):Float
	{
		return graphic.fieldWidth = value;
	}
	
	private function get_fieldWidth():Float
	{
		return graphic.fieldWidth;
	}
	
	private function set_autoSize(value:Bool):Bool
	{
		return graphic.autoSize = value;
	}
	
	private function get_autoSize():Bool
	{
		return graphic.autoSize;
	}
	
	private function get_text():String
	{
		return graphic.text;
	}
	
	private function set_text(Text:String):String
	{
		return graphic.text = Text;
	}
	
	private function get_size():Int
	{
		return graphic.size;
	}
	
	private function set_size(Size:Int):Int
	{
		return graphic.size = Size;
	}
	
	private function get_font():String
	{
		return graphic.font;
	}
	
	private function set_font(Font:String):String
	{
		return graphic.font = Font;
	}
	
	private function get_embedded():Bool
	{
		return graphic.embedded;
	}
	
	private function get_systemFont():String
	{
		return graphic.systemFont;
	}
	
	private function set_systemFont(Font:String):String
	{
		return graphic.systemFont = Font;
	}
	
	private function get_bold():Bool 
	{ 
		return graphic.bold; 
	}
	
	private function set_bold(value:Bool):Bool
	{
		return graphic.bold = value;
	}
	
	private function get_italic():Bool 
	{ 
		return graphic.italic; 
	}
	
	private function set_italic(value:Bool):Bool
	{
		return graphic.italic = value;
	}
	
	private function get_wordWrap():Bool 
	{ 
		return graphic.wordWrap; 
	}
	
	private function set_wordWrap(value:Bool):Bool
	{
		return graphic.wordWrap = value;
	}
	
	private function get_alignment():FlxTextAlign
	{
		return graphic.alignment;
	}
	
	private function set_alignment(Alignment:FlxTextAlign):FlxTextAlign
	{
		return graphic.alignment = Alignment;
	}
	
	private function get_borderStyle():FlxTextBorderStyle
	{		
		return graphic.borderStyle;
	}
	
	private function set_borderStyle(style:FlxTextBorderStyle):FlxTextBorderStyle
	{		
		return graphic.borderStyle = style;
	}
	
	private function get_borderColor():FlxColor
	{
		return graphic.borderColor;
	}
	
	private function set_borderColor(Color:FlxColor):FlxColor
	{
		return graphic.borderColor = Color;
	}
	
	private function get_borderSize():Float
	{
		return graphic.borderSize;
	}
	
	private function set_borderSize(Value:Float):Float
	{
		return graphic.borderSize = Value;
	}
	
	private function get_borderQuality():Float
	{
		return graphic.borderQuality;
	}
	
	private function set_borderQuality(Value:Float):Float
	{
		return graphic.borderQuality = Value;
	}
	
	override private function get_width():Float 
	{
		graphic.regenGraphics();
		return super.get_width();
	}
	
	override private function get_height():Float 
	{
		graphic.regenGraphics();
		return super.get_height();
	}
	
	private function get_textField():TextField
	{
		return graphic.textField;
	}
	
	private function get_color():FlxColor
	{
		return graphic.color;
	}
	
	private function set_color(Value:FlxColor):FlxColor
	{
		return graphic.color = Value;
	}
	
	private function get_alpha():Float
	{
		return graphic.alpha;
	}
	
	private function set_alpha(Value:Float):Float
	{
		return graphic.alpha = Value;
	}
}

@:allow(flixel)
class FlxTextFormat
{
	/**
	 * The border color if FlxText has a shadow or a border
	 */
	private var borderColor:FlxColor;
	private var format(default, null):TextFormat;
	
	/**
	 * @param   FontColor     Set the font color. By default, inherits from the default format.
	 * @param   Bold          Set the font to bold. The font must support bold. By default, false. 
	 * @param   Italic        Set the font to italics. The font must support italics. Only works in Flash. By default, false.  
	 * @param   BorderColor   Set the border color. By default, no border (null / transparent).
	 */
	public function new(?FontColor:FlxColor, ?Bold:Bool, ?Italic:Bool, ?BorderColor:FlxColor)
	{
		format = new TextFormat(null, null, FontColor, Bold, Italic);
		borderColor = BorderColor == null ? FlxColor.TRANSPARENT : BorderColor;
	}
}

@:allow(flixel)
class FlxTextFormatRange
{
	public var range(default, null):FlxRange<Int>;
	public var format(default, null):FlxTextFormat;
	
	public function new(format:FlxTextFormat, start:Int, end:Int)
	{
		range = new FlxRange<Int>(start, end);
		this.format = format;
	}
}

class FlxTextFormatMarkerPair
{
	public var format:FlxTextFormat;
	public var marker:String;
	
	public function new(format:FlxTextFormat, marker:String)
	{
		this.format = format;
		this.marker = marker;
	}
}

enum FlxTextBorderStyle
{
	NONE;
	/**
	 * A simple shadow to the lower-right
	 */
	SHADOW;
	/**
	 * Outline on all 8 sides
	 */
	OUTLINE;
	/**
	 * Outline, optimized using only 4 draw calls. (Might not work for narrow and/or 1-pixel fonts)
	 */
	OUTLINE_FAST;
}

@:enum
abstract FlxTextAlign(String) from String
{
	var LEFT = "left";
	var CENTER = "center";
	var RIGHT = "right";
	var JUSTIFY = "justify";
	
	public static function fromOpenFL(align:AlignType):FlxTextAlign
	{
		return switch (align)
		{
			case TextFormatAlign.LEFT: LEFT;
			case TextFormatAlign.CENTER: CENTER;
			case TextFormatAlign.RIGHT: RIGHT;
			case TextFormatAlign.JUSTIFY: JUSTIFY;
			default: LEFT;
		}
	}
	
	public static function toOpenFL(align:FlxTextAlign):AlignType
	{
		return switch (align)
		{
			case LEFT: TextFormatAlign.LEFT;
			case CENTER: TextFormatAlign.CENTER;
			case RIGHT: TextFormatAlign.RIGHT;
			case JUSTIFY: TextFormatAlign.JUSTIFY;
			default: TextFormatAlign.LEFT;
		}
	}
}

private typedef AlignType = #if openfl_legacy String #else TextFormatAlign #end
