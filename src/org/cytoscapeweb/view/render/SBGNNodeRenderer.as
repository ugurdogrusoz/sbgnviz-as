/*
* This class includes necessary functions for rendering SBGN specific shapes.
* Also includes necessary functions for representing genomic data around macromolecules
* Author: İstemi Bahceci <istemi.bahceci@gmail.com>
*/
package org.cytoscapeweb.view.render
{
	import flare.display.TextSprite;
	import flare.query.If;
	import flare.query.methods.iff;
	import flare.util.Shapes;
	import flare.vis.data.DataSprite;
	import flare.vis.data.NodeSprite;
	
	import flash.display.*;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.setTimeout;
	
	import mx.utils.StringUtil;
	
	import org.alivepdf.display.Display;
	import org.cytoscapeweb.util.CompoundNodes;
	import org.cytoscapeweb.util.Fonts;
	import org.cytoscapeweb.util.GraphUtils;
	import org.cytoscapeweb.util.NodeShapes;
	import org.cytoscapeweb.vis.data.CompoundNodeSprite;
	
	public class SBGNNodeRenderer extends NodeRenderer
	{  
		// SBGN Specific Constants
		protected static const MACROMOLECULE:String = "macromolecule";
		protected static const UNIT_OF_INFORMATION:String = "unit of information";
		protected static const STATE_VARIABLE:String = "state variable";
		protected static const SOURCE_AND_SINK:String = "source and sink";
		protected static const ASSOCIATION:String = "association";
		protected static const DISSOCIATION:String = "dissociation";
		protected static const SIMPLE_CHEMICAL:String = "simple chemical";
		protected static const PROCESS:String = "process";
		protected static const AND:String = "and";
		protected static const PHENOTYPE:String = "phenotype";
		protected static const PERTURBING_AGENT:String = "perturbing agent";
		protected static const TAG:String = "tag";
		protected static const MULTIMER:String = "multimer";
		protected static const NUCLEIC_ACID_FEATURE:String = "nucleic acid feature";
		protected static const UNSPECIFIED_ENTITY:String = "unspecified entity";
		protected static const COMPARTMENT:String = "compartment";
		
		protected static const CLONE_MARKER_COLOR:uint = 0xA4A4A4;
		protected static const PROCESS_NODE_COLOR:uint = 0xE6E6E6;
		
		protected static const MAX_NUMBER_OF_STATE_BOXES:int = 2;
		protected static const MAX_NUMBER_OF_INFO_BOXES:int = 2;
		
		
		// Constant variable for determining the length that indicates hom many letter of state and info glyphs' labels will be rendered
		protected static const MAX_LENGTH_FOR_INFO_GLYPH_LABEL:int = 11;
		
		
		protected static var _instance:SBGNNodeRenderer =
			new SBGNNodeRenderer();
		
		protected var _imgCache:ImageCache = ImageCache.instance;
		
		public static function get instance() : SBGNNodeRenderer
		{
			return _instance;
		}
		
		public function SBGNNodeRenderer(defaultSize:Number=6)
		{
			super(defaultSize);
		}
		
		/** @inheritDoc */
		public override function render(d:DataSprite):void {trace("RENDER NODE: " + d.data.id);
			var lineAlpha:Number = d.lineAlpha;
			var fillAlpha:Number = d.fillAlpha;
			var size:Number = d.size * defaultSize;
			
			var g:Graphics = d.graphics;
			g.clear();
			
			if (lineAlpha > 0 && d.lineWidth > 0) 
			{
				var pixelHinting:Boolean = d.shape === NodeShapes.ROUND_RECTANGLE;
				g.lineStyle(d.lineWidth, d.lineColor, lineAlpha, pixelHinting);
				
			}
			
			if (fillAlpha > 0) 
			{
				// 1. Draw the background color:
				// Using a bit mask to avoid transparent mdes when fillcolor=0xffffffff.
				// See https://sourceforge.net/forum/message.php?msg_id=7393265
				g.beginFill(0xffffff & d.fillColor, 1.0);
				drawSBGNShape(d as CompoundNodeSprite,d.fillColor);
				g.endFill();
				
				// 2. Draw an image on top:
				drawImage(d,0,0);
			}
		}
		
		/* This function determines the shape of the glyphs, according to the class of glyphs.
		* Clone marker, multimer adjustments also takes place in this function 
		* */
		public function drawSBGNShape(cns:CompoundNodeSprite, fillColor:uint):void
		{
			var glyphClass:String = cns.data.glyph_class;
			var rect:Rectangle = cns.bounds;
			var stateAndInfoGlyphs:Array = cns.data.stateAndInfoGlyphs as Array;
			var g:Graphics = cns.graphics;
			var isMultimer = false;
			var isClone:Boolean = cns.data.clone_marker;
			var multimerOffset = 5;		
			
			// if any multimer occurs
			if (glyphClass.indexOf(MULTIMER) > 0)
			{       
				var str = glyphClass.substr(0, glyphClass.indexOf(MULTIMER)-1);
				glyphClass = str;
				isMultimer = true;
			}
			
			if (glyphClass == MACROMOLECULE || glyphClass == SIMPLE_CHEMICAL ) 
			{     
				g.lineStyle(1, 0x000000, 1);
				
				if (isMultimer) 
				{
					drawMolecule(cns,rect, multimerOffset,isClone,glyphClass);
				}
				
				drawMolecule(cns,rect, 0,isClone,glyphClass);
			}
			else if (glyphClass == SOURCE_AND_SINK || glyphClass == AND ) 
			{
				g.drawEllipse(-rect.width/2, -rect.height/2, rect.width, rect.height);
				
				// Draw line intersecting the circle for "source and sink" glyph class
				if (glyphClass == SOURCE_AND_SINK) 
				{
					g.moveTo(rect.width/2, -rect.height/2);
					g.lineTo(-rect.width/2,rect.width/2);
				}
				
			}
			else if (glyphClass == ASSOCIATION) 
			{
				// Fill circle with black if the glyph is "association" type
				g.beginFill(0x000000, 1);
				g.drawEllipse(-rect.width/2, -rect.height/2, rect.width, rect.height);
				g.endFill();
			}
			else if (glyphClass == DISSOCIATION) 
			{
				// Draw inner circle if glyph type is "dissociation"
				g.drawEllipse(-rect.width/2, -rect.height/2, rect.width, rect.height);
				g.drawEllipse(-rect.width/4, -rect.height/4, rect.width/2, rect.height/2);
			}
			else if (glyphClass == PROCESS) 
			{
				g.beginFill(PROCESS_NODE_COLOR,1.0);
				g.drawRect(-rect.width/2, -rect.height/2, rect.width, rect.height);
				g.endFill();
			}
			else if (glyphClass == UNSPECIFIED_ENTITY  ) 
			{
				if (isMultimer) 
				{
					drawEllyptics(cns,multimerOffset,isClone);
				}
				
				drawEllyptics(cns,0,isClone);
				
			}
			else if (glyphClass == PHENOTYPE ) 
			{
				drawHexagon(cns, rect,isClone);
			}
			else if (glyphClass == PERTURBING_AGENT ) 
			{
				drawPetrubingAgent(cns, rect,isClone);
			}
			else if (glyphClass == TAG ) 
			{
				drawTag(cns,rect,isClone);
			}
			else if (glyphClass == NUCLEIC_ACID_FEATURE) 
			{
				if (isMultimer) 
				{
					drawNucleicAcid(cns,rect, multimerOffset,isClone);
				}
				g.beginFill(0xffffff & fillColor, 1.0);
				drawNucleicAcid(cns,rect, 0,isClone);
				g.endFill();
			}
			else if (glyphClass == COMPARTMENT) 
			{
				// dummy 
			}
			
			renderStateAndInfoGlyphs(stateAndInfoGlyphs,cns,fillColor);
			
		}
		
		protected function renderStateAndInfoGlyphs(stateAndInfoGlyphs:Array,cns:CompoundNodeSprite, fillColor:uint)
		{
			var g:Graphics = cns.graphics;
			
			var stateCounter:int = 1;
			var infoCounter:int = 1;			
			
			// Draw state variable and unit of information glyphs also
			if (stateAndInfoGlyphs != null) 
			{
				for each (var tmpCns:CompoundNodeSprite in stateAndInfoGlyphs) 
				{					
					var childRect:Rectangle = tmpCns.data.glyph_bbox;               
					trace(tmpCns.data.id+ " " +childRect);
					// Adjust the position of state variable and unit of information glyphs
					var x = -cns.x + tmpCns.x-childRect.width/2;
					var y = -cns.y + tmpCns.y-childRect.height/2;
					
					if (cns.getChildByName(tmpCns.data.id)  != null )
					{
						cns.removeChild( cns.getChildByName(tmpCns.data.id) );
					}
					
					var myTextBox:TextSprite = new TextSprite();
					
					myTextBox.name = tmpCns.data.id;
					myTextBox.mouseEnabled = false;
					myTextBox.mouseChildren = false;
					myTextBox.buttonMode = false;
					myTextBox.textField.mouseEnabled = false;
					myTextBox.font = Fonts.ARIAL;
					myTextBox.kerning = true;
					myTextBox.size = 9;
					cns.addChild(myTextBox);
					
					if (tmpCns.data.glyph_class == STATE_VARIABLE) 
					{
						if (stateCounter <= MAX_NUMBER_OF_STATE_BOXES) 
						{
							g.beginFill(0xffffff & fillColor, 1);
							g.drawRoundRect(x,y,childRect.width, childRect.height,20,20);
							g.endFill();
							
							// 
							var tmpString:String = tmpCns.data.glyph_state_value;
							
							if(tmpCns.data.glyph_state_variable != "")
								tmpString += "@" + tmpCns.data.glyph_state_variable;
							
							
							if (tmpString.length > MAX_LENGTH_FOR_INFO_GLYPH_LABEL) 
							{
								tmpString = tmpString.substr(0, MAX_LENGTH_FOR_INFO_GLYPH_LABEL-5);
								tmpString += "...";
							}
							myTextBox.text = tmpString;
							stateCounter++;
							
							myTextBox.x = x + tmpCns.bounds.width/2-myTextBox.width/2;
							myTextBox.y = y + tmpCns.bounds.height/2-myTextBox.height/2;
						}
					}
						
					else if (tmpCns.data.glyph_class == UNIT_OF_INFORMATION) 
					{
						if (infoCounter <= MAX_NUMBER_OF_INFO_BOXES) 
						{
							g.beginFill(0xffffff & fillColor, 1);
							g.drawRect(x,y,childRect.width, childRect.height);
							g.endFill();
							
							var tmpString = tmpCns.data.glyph_label_text;
							if (tmpString.length > MAX_LENGTH_FOR_INFO_GLYPH_LABEL) 
							{
								tmpString = tmpString.substr(0, MAX_LENGTH_FOR_INFO_GLYPH_LABEL);
								tmpString += "...";
							}
							
							myTextBox.text = tmpString;
							
							myTextBox.x = x + tmpCns.bounds.width/2-myTextBox.width/2;
							myTextBox.y = y + tmpCns.bounds.height/2-myTextBox.height/2;
							
							infoCounter++;
						}
						
					}
				}               
			}
		}
		
		protected override function drawImage(d:DataSprite, w:Number, h:Number):void 
		{
			var url:String = d.props.imageUrl;
			var size:Number = d.size*defaultSize;
			
			if (size > 0 && url != null && StringUtil.trim(url).length > 0) {
				// Load the image into the cache first?
				if (!_imgCache.contains(url)) {trace("Will load IMAGE...");
					_imgCache.loadImage(url);
				}
				if (_imgCache.isLoaded(url)) {trace(" .LOADED :-)");
					draw();
				} else {trace(" .NOT loaded :-(");
					drawWhenLoaded();
				}
				
				function drawWhenLoaded():void {
					setTimeout(function():void {trace(" .TIMEOUT: Checking again...");
						if (_imgCache.isLoaded(url)) draw();
						else if (!_imgCache.isBroken(url)) drawWhenLoaded();
					}, 50);
				}
				
				function draw():void {trace("Will draw: " + d.data.id);
					// Get the image from cache:
					var bd:BitmapData = _imgCache.getImage(url);
					
					if (bd != null) {
						var bmpSize:Number = Math.min(bd.height, bd.width);
						var scale:Number = size/bmpSize;
						
						var m:Matrix = new Matrix();
						m.scale(scale, scale);
						m.translate(-(bd.width*scale)/2, -(bd.height*scale)/2);
						
						d.graphics.beginBitmapFill(bd, m, false, true);
						drawShape(d, d.shape, null);
						d.graphics.endFill();
					}
				}
			}
		}
		
		//renders shape especially for "macromolecules" glyph type
		protected function drawMolecule(cns:CompoundNodeSprite ,bounds:Rectangle, multimerOffset:Number, isClone:Boolean, glyphClass:String): void
		{
			var g:Graphics = cns.graphics;
			var cornerOffset:Number = 10;
			
			if(glyphClass == SIMPLE_CHEMICAL)
				cornerOffset = 20;
			
			g.drawRoundRect(-bounds.width/2+multimerOffset, -bounds.height/2+multimerOffset, bounds.width, bounds.height, cornerOffset,cornerOffset);
			
			if (isClone) 
			{
				g.beginFill(CLONE_MARKER_COLOR,1.0);
				drawOval(cns,true,multimerOffset);
				//g.drawRoundRect(-bounds.width/2+multimerOffset, bounds.height/4+multimerOffset, bounds.width, bounds.height/4, 4*cornerOffset, 4*cornerOffset);
				renderCloneMarkerText(cns, 0, bounds.height/4);
				g.endFill();
			}
		}
		
		//renders shape especially for "perturbing agent" glyph type
		protected function drawPetrubingAgent(cns:CompoundNodeSprite, bounds:Rectangle, isClone:Boolean): void
		{
			var g:Graphics = cns.graphics;
			var w  = bounds.width;
			var h  = bounds.height;
			
			g.moveTo(-w/4,0);
			g.lineTo(-w/2,-h/2);                    
			g.lineTo(w/2,-h/2);                     
			g.lineTo(w/4,0);                        
			g.lineTo(w/2,h/2);                      
			g.lineTo(-w/2,h/2);                     
			g.lineTo(-w/4,0);
			
			if (isClone) 
			{
				g.beginFill(CLONE_MARKER_COLOR,1.0);
				g.moveTo(-3*w/8,h/4);
				g.lineTo(-w/2,h/2);                     
				g.lineTo(w/2,h/2);                                      
				g.lineTo(3*w/8,h/4);
				g.moveTo(-3*w/8,h/4);
				g.endFill();
				
				renderCloneMarkerText(cns, 0, bounds.height/4);
			}
		}
		
		//renders shape especially for "tag" glyph type
		protected function drawTag(cns:CompoundNodeSprite, bounds:Rectangle, isClone:Boolean): void
		{
			var g:Graphics = cns.graphics;
			var w  = bounds.width;
			var h  = bounds.height;
			
			g.moveTo(-w/2,-h/2);
			g.lineTo(w/4,-h/2);                     
			g.lineTo(w/2,0);                        
			g.lineTo(w/4,h/2);                      
			g.lineTo(-w/2,h/2);                     
			g.lineTo(-w/2,-h/2);
			
			if (isClone) 
			{
				g.beginFill(CLONE_MARKER_COLOR,1.0);
				g.moveTo(-w/2, h/4);
				g.lineTo(3*w/8, h/4);                   
				g.lineTo(w/4,h/2);
				g.lineTo(-w/2,h/2);
				g.lineTo(-w/2, h/4);
				g.endFill();
				
				renderCloneMarkerText(cns, 0, bounds.height/4);
			}
		}
		
		//renders a hexagon especially for "phenotype" glyph type
		protected function drawHexagon(cns:CompoundNodeSprite, bounds:Rectangle, isClone:Boolean): void
		{
			var g:Graphics = cns.graphics;
			var w  = bounds.width;
			var h  = bounds.height;
			
			g.moveTo(-w/2,0);
			g.lineTo(-w/4,-h/2);
			g.lineTo(w/4,-h/2);                     
			g.lineTo(w/2,0);
			g.lineTo(w/4,h/2);                      
			g.lineTo(-w/4,h/2);
			g.lineTo(-w/2,0);
			
			if (isClone) 
			{
				g.beginFill(CLONE_MARKER_COLOR,1.0);
				g.moveTo(-3*w/8, h/4)
				g.lineTo(3*w/8, h/4);                   
				g.lineTo(w/4,h/2);
				g.lineTo(-w/4,h/2);
				g.lineTo(-3*w/8, h/4);
				g.endFill();
				
				renderCloneMarkerText(cns, 0, bounds.height/4);
			}
		}
		
		protected function drawNucleicAcid(cns:CompoundNodeSprite, bounds:Rectangle, multimerOffset:Number, isClone:Boolean)
		{
			var g:Graphics = cns.graphics;
			var w  = bounds.width;
			var h  = bounds.height;
			
			var cornerOffset = 10;
			
			var NAFCornerOffset = 8;
			
			g.moveTo(-w/2+multimerOffset,-h/2+multimerOffset);
			g.lineTo(w/2+multimerOffset,-h/2+multimerOffset);					
			g.lineTo(w/2+multimerOffset,h/2-NAFCornerOffset+multimerOffset);			
			g.curveTo(w/2+multimerOffset,h/2+multimerOffset,w/2-NAFCornerOffset+multimerOffset,h/2+multimerOffset);			
			g.lineTo(-w/2+NAFCornerOffset+multimerOffset,h/2+multimerOffset);			
			g.curveTo(-w/2+multimerOffset,h/2+multimerOffset,-w/2+multimerOffset,h/2-NAFCornerOffset+multimerOffset);
			g.lineTo(-w/2+multimerOffset,-h/2+multimerOffset);				
			
			if (isClone) 
			{
				g.beginFill(CLONE_MARKER_COLOR,1.0);
				g.moveTo(-w/2+multimerOffset,h/2-cornerOffset+multimerOffset);
				g.lineTo(w/2+multimerOffset,h/2-cornerOffset+multimerOffset);   
				g.lineTo(w/2-cornerOffset+multimerOffset,h/2+multimerOffset);                   
				g.lineTo(-w/2+cornerOffset+multimerOffset,h/2+multimerOffset);                  
				g.lineTo(-w/2+multimerOffset,h/2-cornerOffset+multimerOffset);
				g.endFill();
				
				renderCloneMarkerText(cns, 0, h/2-cornerOffset+multimerOffset);
				
			}
		}
		
		protected function drawEllyptics(cns:CompoundNodeSprite, multimerOffset:Number, isClone:Boolean)
		{
			var glyphClass = cns.data.glyph_class;
			var g:Graphics = cns.graphics;
			var rect:Rectangle = cns.bounds;
			
			drawOval(cns, false, multimerOffset);
			
			if (isClone) 
			{
				g.beginFill(CLONE_MARKER_COLOR,1.0);
				drawOval(cns, isClone, multimerOffset);
				g.endFill();
			}
		}
		
		//
		// Change "radius" to "xRadius" and add "yRadius" argument.
		protected function drawOval(cns:CompoundNodeSprite, isClone:Boolean, multimerOffset:Number): void
		{               
			var centerX = 0+multimerOffset;
			var centerY = 0+multimerOffset;
			var xRadius = cns.bounds.width/2;
			var yRadius = cns.bounds.height/2;
			var sides = 200;
			var loopBounds = sides;
			
			if (isClone) 
			{
				centerX = 0+multimerOffset;
				centerY = cns.bounds.height/6+multimerOffset;
				xRadius = 0.48*cns.bounds.width;
				yRadius = 0.31*cns.bounds.height;
				loopBounds = loopBounds/2;
				
				renderCloneMarkerText(cns,centerX, centerY);
			}
			
			// Change "radius" to "xRadius".
			cns.graphics.moveTo(centerX + xRadius,  centerY);
			//
			for(var i=0; i<=loopBounds; i++)
			{
				var pointRatio = i/sides;
				var radians = pointRatio * 2 * Math.PI;
				var xSteps = Math.cos(radians);
				var ySteps = Math.sin(radians);
				//
				// Change "radius" to "xRadius".
				var pointX = centerX + xSteps * xRadius;
				//
				// Change "radius" to "yRadius".
				var pointY = centerY + ySteps * yRadius;
				//
				cns.graphics.lineTo(pointX, pointY);
			}
		}
		
		protected function renderCloneMarkerText(cns:CompoundNodeSprite,x:Number, y:Number)
		{
			var labelText = cns.data.clone_label_text;
			
			if (labelText != "") 
			{
				// remove first if texsprite is already in node sprite
				if (cns.getChildByName(cns.data.id+"c")  != null )
				{
					cns.removeChild( cns.getChildByName(cns.data.id+"c") );
				}
				
				var myTextBox:TextSprite = new TextSprite();
				var textField:TextField = new TextField();
				
				myTextBox.color = 0x908888;
				myTextBox.name = cns.data.id+"c";
				myTextBox.mouseEnabled = false;
				myTextBox.mouseChildren = false;
				myTextBox.buttonMode = false;
				myTextBox.textField.mouseEnabled = false;
				
				myTextBox.text = labelText;                     
				myTextBox.x = x-(myTextBox.width/2);
				myTextBox.y = y;
				
				cns.addChild(myTextBox);
				
			}
		}
	}
}