package org.cytoscapeweb.view.layout.ivis.layout.sbgnpd
{
	import org.as3commons.collections.ArrayList;
	import org.as3commons.collections.Map;
	import org.as3commons.collections.framework.IIterator;
	import org.cytoscapeweb.view.layout.ivis.layout.*;
	import org.cytoscapeweb.view.layout.ivis.layout.cose.CoSELayout;
	import org.cytoscapeweb.view.layout.ivis.layout.cose.CoSENode;
	import org.cytoscapeweb.view.layout.ivis.layout.fd.*;
	import org.cytoscapeweb.view.layout.ivis.util.*;
		
	public class SBGNPDLayout extends CoSELayout
	{
		private var complexOrder:ArrayList;
		
		//Map CoSENode MemberPack
		private var memberPackMap:Map;
		
		//Map CoSENODE LGraph
		private var childGraphMap:Map;
		
		public function SBGNPDLayout()
		{
			super();
			complexOrder = new ArrayList();
			memberPackMap = new Map();
			childGraphMap = new Map();
		}
		
		/**
		 * This method performs layout on constructed l-level graph. It returns true
		 * on success, false otherwise.
		 */
		override public  function layout():Boolean
		{
			var b:Boolean = false;
			
			DFSComplex();
			resetLists();
			
			b = super.layout();

			repopulateComplexes();
			resetLists();

			return b;
		}
		
		/**
		 * This method searched unmarked complex nodes recursively, because they may
		 * contain complex children. After the order is found, child graphs of each
		 * complex node are cleared.
		 */
		public function DFSComplex():void
		{
			for (var i:Number=0; i< getAllNodes().length; i++)
			{
				var o:Object = getAllNodes()[i];
				if (!(o is CoSENode) || (o as CoSENode).nodeType != "complex")
					continue;
				
				var comp:CoSENode =  o as CoSENode;
				
				// complex is found, recurse on it until no visited complex remains.
				if (!comp.visited)
					DFSVisitComplex(comp);
			}
			
			// clear each complex
			for (var j:Number = 0; j < complexOrder.size; j++)
			{
				clearComplex(complexOrder.itemAt(j));
			}
		}
		
		/**
		 * This method recurses on the complex objects. If a node does not contain
		 * any complex nodes or all the nodes in the child graph is already marked,
		 * it is reported. (Depth first)
		 * 
		 */
		public function DFSVisitComplex(node:CoSENode):void
		{
			if (node.getChild() != null)
			{
				for (var i:Number = 0; i < node.getChild().getNodes().size; i++)
				{		
					var sbgnChild:CoSENode = node.getChild().getNodes().itemAt(i) as CoSENode;
					DFSVisitComplex(sbgnChild);
				}
			}
			
			if (node.nodeType == "complex" && !containsUnmarkedComplex(node))
			{
				complexOrder.add(node);
				node.visited = true;
			}
		}
		
		/**
		 * This method checks if the given node contains any unmarked complex nodes
		 * in its child graph.
		 * 
		 * @return true - if there are unmarked complex nodes false - otherwise
		 */
		public function containsUnmarkedComplex(comp:CoSENode):Boolean
		{
			if (comp.getChild() == null)
				return false;
			else
			{
				for (var i:Number=0; i < comp.getChild().getNodes().size; i++)
				{
					var sbgnChild:CoSENode = comp.getChild().getNodes().itemAt(i) as CoSENode;
					
					if (sbgnChild.nodeType == "complex" && !sbgnChild.visited)
						return true;
				}
				return false;
			}
		}
		
		/**
		 * This method applies polyomino packing on the child graph of a complex
		 * member and then..
		 * 
		 * @param comp
		 */
		private function clearComplex(comp:CoSENode):void
		{
			var pack:MemberPack = null;
			var childGr:LGraph = comp.getChild();
			childGraphMap.add(comp ,childGr);

			pack = new MemberPack(childGr);
			this.memberPackMap.add(comp ,pack);		
			
			getGraphManager().getGraphs().remove(childGr);
			comp.setChild(null);
			
			comp.setWidth(pack.getWidth());
			comp.setHeight(pack.getHeight());
						
			// Redirect the edges of complex members to the complex.
			if (childGr != null)
			{
				for (var i:Number=0; i < childGr.getNodes().size; i++)
				{
					var chNd:CoSENode = childGr.getNodes().itemAt(i);
					
					for(var j:Number = 0; j < chNd.getEdges().toArray().length; j++)
					{
						var edge:LEdge = chNd.getEdges().toArray()[j] as LEdge;
						
						if (edge.getSource() == chNd)
						{
							chNd.getEdges().remove(edge);
							edge.setSource(comp);
							comp.getEdges().add(edge);
						}
						else if (edge.getTarget() == chNd)
						{
							chNd.getEdges().remove(edge);
							edge.setTarget(comp);
							comp.getEdges().add(edge);
						}
					}
				}
			}
		}
		
		/**
		 * Reassigns the complex content. The outermost complex is placed first.
		 */
		protected function repopulateComplexes():void
		{
			for (var i:Number = complexOrder.size - 1; i >= 0; i--)
			{
				var comp:CoSENode = complexOrder.itemAt(i);
				var chGr:LGraph = childGraphMap.itemFor(comp);
				
				// repopulate the complex
				comp.setChild(chGr);
				getGraphManager().getGraphs().add(chGr);
				var pack:MemberPack = memberPackMap.itemFor(comp);
				pack.adjustLocations(comp.getLeft(), comp.getTop());
			}
		}
		
		private function resetLists():void
		{
			// Reset lists
			getGraphManager().resetAllNodes();
			getGraphManager().resetAllNodesToApplyGravitation();
			getGraphManager().resetAllEdges();
		}
	}
}