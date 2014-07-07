package org.cytoscapeweb.view.layout.ivis.util
{
	import org.as3commons.collections.ArrayList;
	import org.cytoscapeweb.view.layout.ivis.layout.cose.CoSENode;
	import org.cytoscapeweb.view.layout.ivis.layout.sbgnpd.SBGNPDConstants;
	
	public class Organization
	{
		/**
		 * Width of the container
		 */
		private var width:Number;
		
		/**
		 * Height of the container
		 */
		private var height:Number;
		
		private var rowWidth:ArrayList;
		private var rows:ArrayList;
		
		/**
		 * Creates a container whose width and height is only the margins
		 */
		public function Organization()
		{
			
			this.width = SBGNPDConstants.COMPLEX_MEM_MARGIN * 2;
			this.height = SBGNPDConstants.COMPLEX_MEM_MARGIN * 2;
			
			rowWidth = new ArrayList();
			rows = new ArrayList();
		}
		
		public function getWidth():Number
		{
			shiftToLastRow();
			return width;
		}
		
		public function getHeight():Number
		{
			return height;
		}
		
		/**
		 * Scans the rowWidth array list and returns the index of the row that has
		 * the minimum width.
		 */
		private function  getShortestRowIndex():Number
		{
			var r:Number = -1;
			var min:Number = Number.MAX_VALUE;
			
			for (var i = 0; i < rows.size; i++)
			{
				if (rowWidth.itemAt(i) < min)
				{
					r = i;
					min = rowWidth.itemAt(i);
				}
			}
			
			return r;
		}
		
		/**
		 * Scans the rowWidth array list and returns the index of the row that has
		 * the maximum width.
		 */
		private function  getLongestRowIndex():Number
		{
			var r:Number = -1;
			var max:Number = Number.MIN_VALUE;
			
			for (var i = 0; i < rows.size; i++)
			{
				if (rowWidth.itemAt(i) > max)
				{
					r = i;
					max = rowWidth.itemAt(i);
				}
			}
			
			return r;
		}
		
		public function insertNode(node:CoSENode):void
		{
			if (rows.size == 0)
			{
				insertNodeToRow(node, 0);
			}
			else if (canAddHorizontal(node.getWidth(), node.getHeight()))
			{
				insertNodeToRow(node, getShortestRowIndex());
			}
			else
			{
				insertNodeToRow(node, rows.size);
			}
		}
		
		/**
		 * This method performs tiling. If a new row is needed, it creates the row
		 * and places the new node there. Otherwise, it places the node to the end
		 * of the given row.
		 * 
		 * @param node
		 * @param rowIndex
		 */
		private function insertNodeToRow(node:CoSENode,rowIndex:Number):void
		{
			// Add new row if needed
			if (rowIndex == rows.size)
			{
				if (rows.size != 0)
				{
					height += SBGNPDConstants.COMPLEX_MEM_VERTICAL_BUFFER;
				}
				rows.add(new ArrayList());
				height += node.getHeight();
				
				rowWidth.add(SBGNPDConstants.COMPLEX_MIN_WIDTH);
			}
			
			// Update row width
			var w:Number = rowWidth.itemAt(rowIndex) + node.getWidth();
			
			if ((rows.itemAt(rowIndex) as ArrayList).size > 0)
			{
				w += SBGNPDConstants.COMPLEX_MEM_HORIZONTAL_BUFFER;
			}
			rowWidth.removeAt(rowIndex);
			rowWidth.addAt(rowIndex, w);
			
			// Insert node
			(rows.itemAt(rowIndex)as ArrayList).add(node);
			
			//TODO can you find a better height management function?
			updateHeight();
			
			// Update complex width
			if (this.width < w)
			{
				this.width = w;
			}
		}
		
		/**
		 * If moving the last node from the longest row and adding it to the last
		 * row makes the bounding box smaller, do it.
		 */
		private function  shiftToLastRow():void
		{
			var longest:Number = getLongestRowIndex();
			var last:Number = rowWidth.size -1;
			var row:ArrayList = this.rows.itemAt(longest);
			var node:CoSENode = row.last;
			
			 var diff:Number = node.getWidth()
				+ SBGNPDConstants.COMPLEX_MEM_HORIZONTAL_BUFFER;
			
			if (width - rowWidth.itemAt(last) > diff)
			{
				row.removeLast();
				(rows.itemAt(last) as ArrayList).add(node);
				rowWidth.addAt(longest, rowWidth.itemAt(longest) - diff);
				rowWidth.addAt(last, rowWidth.itemAt(last) + diff);
				
				width = rowWidth.itemAt(getLongestRowIndex());
				
				updateHeight();
				
				shiftToLastRow();
			}
		}
		
		/**
		 * Find the maximum height of each row, add them and update the height of
		 * the bounding box with the found value.
		 */
		private function updateHeight():void
		{
			var totalHeight:Number = 2*SBGNPDConstants.COMPLEX_MEM_MARGIN;
			
			for (var i:Number = 0; i < this.rows.size; i++)
			{
				var maxHeight:Number = 0;
				var r:ArrayList = this.rows.itemAt(i) as ArrayList;
				
				for (var j:Number = 0; j < r.size; j++)
				{
					if (r.itemAt(j).getHeight() > maxHeight)
						maxHeight =  r.itemAt(j).getHeight();
				}
				
				totalHeight += (maxHeight + SBGNPDConstants.COMPLEX_MEM_VERTICAL_BUFFER);
			}
			height = totalHeight;
		}
		
		private function canAddHorizontal(extraWidth:Number,extraHeight:Number):Boolean
		{
			var sri:Number = getShortestRowIndex();
			
			if (sri < 0)
			{
				return true;
			}
			var min:Number = rowWidth.itemAt(sri);
			
			if (this.width - min >= extraWidth
				+ SBGNPDConstants.COMPLEX_MEM_HORIZONTAL_BUFFER)
			{
				return true;
			}
			
			return this.height + SBGNPDConstants.COMPLEX_MEM_VERTICAL_BUFFER
				+ extraHeight > min + extraWidth
				+ SBGNPDConstants.COMPLEX_MEM_HORIZONTAL_BUFFER;
		}
		
		public function adjustLocations(x:Number, y:Number):void
		{		
			x += SBGNPDConstants.COMPLEX_MEM_MARGIN;
			y += SBGNPDConstants.COMPLEX_MEM_MARGIN;
			
			var left:Number = x;
			
			for (var i:int = 0; i < rows.size; i++) 
			{
				var row:ArrayList = rows.itemAt(i) as ArrayList;
				var x:Number = left;
				var maxHeight:Number = 0;
				
				for (var j:int = 0; j < row.size; j++) 
				{
					var node:CoSENode = row.itemAt(j) as CoSENode;

					node.setLocation(x, y);
					
					x += node.getWidth()
						+ SBGNPDConstants.COMPLEX_MEM_HORIZONTAL_BUFFER;
					
					if (node.getHeight() > maxHeight)
						maxHeight = node.getHeight();
				}
				
				y += maxHeight + SBGNPDConstants.COMPLEX_MEM_VERTICAL_BUFFER;
			}
		}
	}
}