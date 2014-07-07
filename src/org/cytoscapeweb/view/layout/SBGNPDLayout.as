package org.cytoscapeweb.view.layout
{
	import flare.vis.data.Data;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.operator.layout.Layout;
	
	import flash.geom.Rectangle;
	
	import org.cytoscapeweb.ApplicationFacade;
	import org.cytoscapeweb.model.ConfigProxy;
	import org.cytoscapeweb.model.data.VisualStyleVO;
	import org.cytoscapeweb.util.GraphUtils;
	import org.cytoscapeweb.util.SizePolicies;
	import org.cytoscapeweb.util.VisualProperties;
	import org.cytoscapeweb.view.components.GraphVis;
	import org.cytoscapeweb.view.layout.ivis.layout.*;
	import org.cytoscapeweb.view.layout.ivis.layout.sbgnpd.SBGNPDLayout;
	import org.cytoscapeweb.view.layout.ivis.util.RectangleD;
	import org.cytoscapeweb.vis.data.CompoundNodeSprite;
	
	public class SBGNPDLayout extends CompoundSpringEmbedder
	{
		public function SBGNPDLayout()
		{
			super();
			this._ivisLayout = new org.cytoscapeweb.view.layout.ivis.layout.sbgnpd.SBGNPDLayout();
		}
		
		protected override function createNode(node:CompoundNodeSprite, parent:CompoundNodeSprite, layout:org.cytoscapeweb.view.layout.ivis.layout.Layout):void
		{
			super.createNode(node, parent, layout);
			
			var lNode:LNode = this._cwToLayout[node];
			lNode.nodeType = node.data.glyph_class;
			
			// copy geometry
			var expandedRect:RectangleD = calcSizeWithInfoBoxes(node);
			
			lNode.setLocation(expandedRect.x, expandedRect.y);
			
			if (!node.isInitialized())
			{
				lNode.setWidth(expandedRect.width);
				lNode.setHeight(expandedRect.height);
			}
		}
		
		// State and info box positions also set different than base class's method
		protected override function updateNode(ns:NodeSprite):void
		{
			var cns:CompoundNodeSprite = ns as CompoundNodeSprite;
			
			if (cns.isInitialized())
				return; 
			
			var node:LNode = this._cwToLayout[cns];
			var deltaX:Number, deltaY:Number, offsetX:Number, offsetY:Number;
		
			var expandedRect:RectangleD = calcSizeWithInfoBoxes(cns);
			if (node != null)
			{	
				//Update state and info box coordinates
				var stateAndInfoGlyphs:Array = cns.data.stateAndInfoGlyphs as Array;
				
				var newX:Number = node.getCenterX() + expandedRect.getCenterX() - cns.x;
				var newY:Number = node.getCenterY() + expandedRect.getCenterY() - cns.y;
				
				for (var i:int = 0; i < stateAndInfoGlyphs.length; i++) 
				{	
					var glyph:CompoundNodeSprite = stateAndInfoGlyphs[i];
					glyph.x = newX + glyph.x - cns.x;
					glyph.y = newY + glyph.y - cns.y;
				}
				
				cns.x = newX;
				cns.y = newY;
			}
		}
		
		public function calcSizeWithInfoBoxes(cns:CompoundNodeSprite):RectangleD
		{
			var stateAndInfoGlyphs:Array = cns.data.stateAndInfoGlyphs;
			
			// Calculate the maximum offset
			var minX:Number = cns.x-cns.bounds.width/2;
			var minY:Number = cns.y-cns.bounds.height/2;
			var maxX:Number = cns.x + cns.bounds.width/2;
			var maxY:Number = cns.y + cns.bounds.height/2;

			for (var i:int = 0; i < stateAndInfoGlyphs.length; i++) 
			{
				var glyph:CompoundNodeSprite = (stateAndInfoGlyphs[i] as CompoundNodeSprite);				
				var glyphRect:RectangleD = new RectangleD(glyph.x-glyph.bounds.width/2, glyph.y-glyph.bounds.height/2, glyph.bounds.width, glyph.bounds.height);
				
				if (glyphRect.getX() < minX)
					minX = glyphRect.getX();
				
				if (glyphRect.getRight() > maxX)
					maxX = glyphRect.getRight();
				
				if (glyphRect.getY() < minY)
					minY = glyphRect.getY();
				
				if (glyphRect.getBottom() > maxY)
					maxY = glyphRect.getBottom();			
			}			
			return new RectangleD(minX, minY, maxX-minX, maxY-minY);
		}
	}
}