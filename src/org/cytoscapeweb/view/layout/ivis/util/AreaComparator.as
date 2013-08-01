package org.cytoscapeweb.view.layout.ivis.util
{
	import org.as3commons.collections.framework.IComparator;

	public class AreaComparator implements IComparator 
	{
		import org.as3commons.collections.utils.UncomparableType;
		
		public function compare(item1:*, item2:*):int
		{
			var area1:Number = item1.getWidth() * item1.getHeight();
			var area2:Number = item2.getWidth() * item2.getHeight();
			
			if(area1 > area2) {
				return 1;
			} else if(area1 < area1) {
				return -1;
			} else  {
				//area1 == area2
				return 0;
			}
			
			return 0;
		}
		
	}
}