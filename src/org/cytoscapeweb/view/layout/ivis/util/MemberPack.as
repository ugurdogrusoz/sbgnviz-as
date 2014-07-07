package org.cytoscapeweb.view.layout.ivis.util
{
	
	
	import org.as3commons.collections.ArrayList;
	import org.as3commons.collections.framework.IComparator;
	import org.cytoscapeweb.view.layout.ivis.layout.LGraph;
	import org.cytoscapeweb.view.layout.ivis.layout.cose.CoSENode;

	public class MemberPack
	{
		private  var 	members:ArrayList;
		public   var 	org:Organization;
		
		public function MemberPack(childG:LGraph)
		{
			members = new ArrayList();
			for (var i = 0; i < childG.getNodes().size; i++  ) 
			{
				members.add(childG.getNodes().itemAt(i));
			}
			org = new Organization();
			
			layout();
			
			var nodes:Array = new Array(childG.getNodes().size);
			
			for (var j = 0; j < childG.getNodes().size; j++)
			{
				nodes[j] =  childG.getNodes().itemAt(j) as CoSENode;
			}
			
		}
		
		public function layout():void
		{
			members.sort(new AreaComparator());
			
			for  (var i = 0; i < members.size; i++) 
			{
				this.org.insertNode(members.itemAt(i));
			}
				
		}
		
		public function getWidth():Number
		{
			return this.org.getWidth();
		}
		
		public function getHeight():Number
		{
			return this.org.getHeight();
		}
		
		public function adjustLocations(x:Number, y:Number):void
		{
			this.org.adjustLocations(x, y);
		}
		
		public function getMembers():ArrayList
		{
			return this.members;
		}
	}
}