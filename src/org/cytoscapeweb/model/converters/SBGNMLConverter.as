package org.cytoscapeweb.model.converters
{	
	import flare.data.DataField;
	import flare.data.DataSchema;
	import flare.data.DataSet;
	import flare.data.DataTable;
	import flare.data.DataUtil;
	import flare.data.converters.IDataConverter;
	import flare.query.methods.iff;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.operator.layout.ForceDirectedLayout;
	
	import flash.geom.Rectangle;
	import flash.sampler.NewObjectSample;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import flexunit.utils.ArrayList;
	
	import org.cytoscapeweb.model.data.GraphicsDataTable;
	import org.cytoscapeweb.util.DataSchemaUtils;
	import org.cytoscapeweb.util.Groups;
	import org.cytoscapeweb.util.Utils;
	import org.cytoscapeweb.util.methods.$each;
	import org.cytoscapeweb.vis.data.CompoundNodeSprite;
	
	public class SBGNMLConverter implements IDataConverter
	{	
		//SBGN ML HEADER
		public static const SBGNML_HEADER = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"+
			"<sbgn xmlns=\"http://sbgn.org/libsbgn/pd/0.1\">";
		// Top level SBGN elements
		public static const SBGNML:String    = "sbgn";
		protected static const ARC:String    	 = "arc";
		protected static const MAP:String    	 = "map";
		
		//Glyph attributes
		protected static const GLYPH_ID:String = ID;
		protected static const GLYPH_CLASS:String = "glyph_class";
		protected static const GLYPH_ORIENTATION:String = "glyph_orientation";
		
		//Glyph bounding box attributes
		protected static const GLYPH_BBOX:String = "glyph_bbox";
		
		protected static const GLYPH_LABEL_TEXT:String = "glyph_label_text";
		protected static const GLYPH_LABEL_BBOX:String = "glyph_label_bbox";
		
		protected static const GLYPH_STATE_VALUE:String = "glyph_state_value";
		protected static const GLYPH_STATE_VARIABLE:String = "glyph_state_variable";
		
		protected static const CLONE_MARKER:String = "clone_marker";
		protected static const CLONE_LABEL_TEXT:String = "clone_label_text";
		protected static const CLONE_LABEL_BBOX:String = "clone_label_bbox";
		
		protected static const HAS_STATE:String = "has_state";
		protected static const HAS_INFO:String = "has_info";
		
		protected static const STATE_AND_INFO_GLYPHS:String = "stateAndInfoGlyphs";
		protected static const LABEL_OFFSET:String = "labelOffset";
		
		// Arc attributes
		protected static const ARC_TARGET:String = "target";
		protected static const ARC_SOURCE:String = "source";
		protected static const ARC_CLASS:String = "arc_class";
		protected static const ARC_END_X:String = "arc_end_x";
		protected static const ARC_END_Y:String = "arc_end_y";
		protected static const ARC_START_X:String = "arc_start_x";
		protected static const ARC_START_Y:String = "arc_start_y";
		protected static const ARC_GLYPH_ID:String = "arc_glyph_id";
		
		// SBGN namespace
		protected static const SBGN_NAMESPACE:String = "http://sbgn.org/libsbgn/pd/0.1";
		
		protected static const NODE:String   = "node";
		protected static const EDGE:String   = "edge";
		
		protected static const INT:String = "int";
		protected static const INTEGER:String = "integer";
		protected static const LONG:String = "long";
		protected static const FLOAT:String = "float";
		protected static const DOUBLE:String = "double";
		protected static const REAL:String = "real";
		protected static const BOOLEAN:String = "boolean";
		protected static const STRING:String = "string";
		protected static const DATE:String = "date";
		
		protected static const ID:String        = "id";
		protected static const CLASS:String      = "class";
		protected static const KEY:String        = "key";
		protected static const FOR:String        = "for";
		protected static const ALL:String        = "all";
		protected static const ATTRNAME:String   = "attr.name";
		protected static const ATTRTYPE:String   = "attr.type";
		protected static const DEFAULT:String    = "default";
		
		protected static var sbgnml:XML;
		
		// map for reaching the owners of compartments from the port id.
		protected var portIDtoOwnerGlyph:Object ={};
		
		/** @inheritDoc */
		public function read(input:IDataInput, schema:DataSchema=null):DataSet 
		{return null}
		
		/** @inheritDoc */
		public function write(ds:DataSet, output:IDataOutput=null):IDataOutput 
		{
			if (output == null) output = new ByteArray();
			sbgnml.setNamespace(new Namespace(SBGN_NAMESPACE));
			output.writeUTFBytes(sbgnml.toXMLString());
			
			return output;
		}
		
		/**
		 * Parses a SBGNML XML object into a DataSet instance.
		 * @param sbgnml the XML object containing SBGNML markup
		 * @return the parsed DataSet instance
		 */
		public function parse(sbgnML:XML):DataSet 
		{	
			sbgnml = sbgnML;
			
			var lookup:Object = {};
			
			var glyphSprites:Array = new Array();
			var arcSprites:Array = new Array();
			var compartmentSprites: Array = new Array();
			
			var _glyphSprites: ArrayList = new ArrayList();
			
			var cns:CompoundNodeSprite;
			
			var glyphSchema:DataSchema = initGlyphSchema();
			var arcSchema:DataSchema = initArcSchema();
			
			var glyphs:XMLList = sbgnml.elements("map")..glyph;
			var arcs:XMLList = sbgnml.elements("map").elements("arc");
			
			//parse glyphs
			for each (var glyph:XML in glyphs) 
			{
				cns = new CompoundNodeSprite();
				cns.data = parseGlyphData(glyph,glyphSchema);						
				
				var bbox:Rectangle = cns.data.glyph_bbox;
				
				cns.x = bbox.x+bbox.width/2;
				cns.y = bbox.y+bbox.height/2;
				cns.bounds = bbox;
				
				// Add compartments to a seperate list
				if (glyph.@[CLASS].toString() == "compartment") 
				{
					compartmentSprites.push(cns);
				}
				else if (glyph.@[CLASS].toString() != "state variable" && glyph.@[CLASS].toString() != "unit of information") 
				{
					_glyphSprites.addItem(cns);
				}
				
				// if "state variable" and "unit of ingormation" type nodes occur, do not add them to the nodes that will be rendered.
				if (glyph.@[CLASS].toString() != "state variable" && glyph.@[CLASS].toString() != "unit of information") 
				{
					glyphSprites.push(cns);
				}
				
				lookup[cns.data.id] = cns;
			}
			
			// Add Child glyphs
			for each (var glyph:XML in glyphs) 
			{
				var parent:XML = glyph.parent();
				
				if (parent.name() != MAP && parent.name() != ARC ) 
				{
					var parentCns:CompoundNodeSprite = new CompoundNodeSprite();					
					parentCns = lookup[parent.@[ID].toString()] as CompoundNodeSprite;										
					
					if (parentCns != null) 
					{
						// if "state variable" and "unit of ingormation" type nodes occur, do not add them as compound node child.
						if (glyph.@[CLASS].toString() == "state variable" || glyph.@[CLASS].toString() == "unit of information" ) 
						{
							var childCns:CompoundNodeSprite = lookup[glyph.@[ID].toString()];
							parentCns.data.stateAndInfoGlyphs.push(childCns);
							
							//Flags for determining whether this node have unit of information or state, or both.
							if(glyph.@[CLASS].toString() == "state variable")
							{
								parentCns.data.has_state = true;
								parentCns.data.labelOffset -= 1;
							}
							else if(glyph.@[CLASS].toString() == "unit of information")
							{
								parentCns.data.has_info = true;
								parentCns.data.labelOffset += 1;
							}						
						}
						else
						{					
							//parentCns.initialize();							
							parentCns.addNode(lookup[glyph.@[ID].toString()]);	
							if (_glyphSprites.contains(lookup[glyph.@[ID].toString()])) 
							{
								_glyphSprites.removeItem(lookup[glyph.@[ID].toString()]);
							}
						}	
					}
				}
			}
			
			addCompartmentChildren(compartmentSprites,_glyphSprites);
			
			
			var e:Object = {};
			
			//parse arcs
			for each (var arc:XML in arcs) 
			{
				e = parseArcData(arc,arcSchema);			
				arcSprites.push(e);
			}
			
			
			return new DataSet(
				new DataTable(glyphSprites,glyphSchema),
				new DataTable(arcSprites,arcSchema)
			);	
		}
		
		protected function addCompartmentChildren(compartments:Array, compoundGlyphs:ArrayList)
		{
			for (var i:int = 0; i < compoundGlyphs.length(); i++) 
			{
				var cns:CompoundNodeSprite = (CompoundNodeSprite)(compoundGlyphs.getItemAt(i));
				
				var parentCompartment:CompoundNodeSprite = findCompartmentWithSmallestBounds(cns, compartments);
				
				if (parentCompartment != null) 
				{
					parentCompartment.addNode(cns);
				}
			}
		}
		
		protected function findCompartmentWithSmallestBounds(cns:CompoundNodeSprite, compartments:Array):CompoundNodeSprite
		{
			var min:CompoundNodeSprite;
			
			for (var i:int = 0; i < compartments.length; i++) 
			{
				if (cns.data.id != compartments[i].data.id && compartments[i].bounds.containsRect( cns.bounds ) /*&&  min.bounds.containsRect(compartments[i].bounds)*/ )
				{
					min = compartments[i];
				}
			}
			
			return min;
			
		}
		
		protected function parseArcData(arcList:XML, schema:DataSchema):Object 
		{
			var n:Object = {};
			
			// set default values
			var field:DataField;
			for (var i:int = 0; i < schema.numFields; ++i) 
			{
				field = schema.getFieldAt(i);
				n[field.name] = field.defaultValue;
			}
			
			// parse arc element attributes
			for each (var arc:XML in arcList) 
			{
				for each( var attr:XML in arc.attributes() )
				{
					if (attr.name() == "target") 
					{
						field = schema.getFieldByName(ARC_TARGET);
						var tmpStr:String = DataUtil.parseValue(attr.toString(), field.type).toString();
						n[ARC_TARGET] = tmpStr;	
						
						if(portIDtoOwnerGlyph[tmpStr] != null)
							n[ARC_TARGET] = portIDtoOwnerGlyph[tmpStr];
						trace("TARGET "+n[ARC_TARGET]);
						
					}
					else if (attr.name() == "source") 
					{
						field = schema.getFieldByName(ARC_SOURCE);
						var tmpStr:String = DataUtil.parseValue(attr.toString(), field.type).toString();
						n[ARC_SOURCE] = tmpStr;	
						
						if(portIDtoOwnerGlyph[tmpStr] != null)
							n[ARC_SOURCE] = portIDtoOwnerGlyph[tmpStr];
						trace("SOURCE "+n[ARC_SOURCE]);
					}
					else if (attr.name() == CLASS) 
					{
						field = schema.getFieldByName(ARC_CLASS);
						n[ARC_CLASS] = DataUtil.parseValue(attr.toString(), field.type);
					}
					
				}
				
				// parse start element attributes
				for each (var attr:XML in arc.elements("start")) 
				{
					var field:DataField;
					if (attr.name() == "x") 
					{
						field = schema.getFieldByName(ARC_START_X);
						n[ARC_START_X] = DataUtil.parseValue(attr.toString(), field.type);
					}
					else if (attr.name() == "y") 
					{
						field = schema.getFieldByName(ARC_START_Y);
						n[ARC_START_Y] = DataUtil.parseValue(attr.toString(), field.type);
					}
				}
				
				//parse end element attributes
				for each (var attr:XML in arc.elements("start")) 
				{
					var field:DataField;
					if (attr.name() == "x") 
					{
						field = schema.getFieldByName(ARC_END_X);
						n[ARC_END_X] = DataUtil.parseValue(attr.toString(), field.type);
					}
					else if (attr.name() == "y") 
					{
						field = schema.getFieldByName(ARC_END_Y);
						n[ARC_END_Y] = DataUtil.parseValue(attr.toString(), field.type);
					}
				}
				
			}
			
			return n;
		}
		
		
		public function parseGlyphData(glyph:XML, schema:DataSchema):Object 
		{
			var n:Object = {};
			var name:String, value:Object;
			
			n = parseGlyphAttributes(glyph, schema, n);
			
			var label:XMLList = glyph.elements("label");
			var clone:XMLList = glyph.elements("clone");
			var bbox:XMLList = glyph.elements("bbox");
			var state:XMLList = glyph.elements("state");
			var ports:XMLList = glyph.elements("port");
			
			if (label.length() > 0) 
			{
				n = parseLabelAttributes(label,schema,"glyph",n);	
			}
			
			if (clone.length() > 0) 
			{
				n = parseCloneAttributes(clone,schema,n);
			}
			
			if (bbox.length() > 0) 
			{
				n = parseBboxAttributes(bbox,schema,"glyph",n);	
			}
			
			if (state.length() > 0) 
			{
				
				n = parseStateAttributes(state,schema,n);
			}
			
			if (ports.length() > 0) 
			{
				// Even our viewer does not support ports, we should somehow store the ports in a map for reaching the port's owner glyphs'
				// via port's id
				parsePortElements(n.id,ports);
			}
			
			// add "state variable" and "unit of information" glyph array; 
			n[STATE_AND_INFO_GLYPHS] = new Array();
			return n;
		}
		
		// Even our viewer does not support ports, we should somehow store the ports in a map for reaching the port's owner glyphs'
		// via port's id
		public function parsePortElements(ownerID:String,portList:XMLList): void
		{	
			for each (var port:XML in portList) 
			{
				for each( var attr:XML in port.attributes() )
				{
					if(attr.name() == ID)
					{
						portIDtoOwnerGlyph[attr.toString()] = ownerID;
					}
				}
			}
		}
		
		public function parseCloneAttributes(cloneList:XMLList, schema:DataSchema, n:Object): Object
		{
			if (cloneList.length() > 0) 
			{
				var field = schema.getFieldByName(CLONE_MARKER);
				n[CLONE_MARKER] = true;
				
				if(cloneList.elements("bbox").length() > 0)
				{
					n = parseBboxAttributes(cloneList.elements("bbox"),schema,"clone",n);
				}
				
				if(cloneList.elements("label").length() > 0)
				{
					n = parseLabelAttributes(cloneList.elements("label"),schema,"clone",n); 
				}
				
				// Label also
			}			
			return n;		
		}
		
		public function parseStateAttributes(stateList:XMLList, schema:DataSchema, n:Object): Object
		{
			for each (var state:XML in stateList) 
			{
				for each( var attr:XML in state.attributes() )
				{
					var field:DataField;
					if (attr.name() == "value") 
					{
						field = schema.getFieldByName(GLYPH_STATE_VALUE);
						n[GLYPH_STATE_VALUE] = DataUtil.parseValue(attr.toString(), field.type);
					}
					else if (attr.name() == "variable") 
					{
						field = schema.getFieldByName(GLYPH_STATE_VARIABLE);
						n[GLYPH_STATE_VARIABLE] = DataUtil.parseValue(attr.toString(), field.type);
					}
				}
			}
			return n;
		}
		
		
		public function parseBboxAttributes(bboxList:XMLList, schema:DataSchema, type:String ,n:Object): Object
		{
			var bbox_target:String ;
			
			if (type == "clone") 
			{
				bbox_target = CLONE_LABEL_BBOX;
			}
			else if (type == "glyph_label") 
			{
				bbox_target = GLYPH_LABEL_BBOX;
			}
			else if (type == "glyph") 
			{
				bbox_target = GLYPH_BBOX;
			}
			
			for each (var bbox:XML in bboxList) 
			{
				var x:Number,y:Number,w:Number,h:Number;
				var rect:Rectangle;
				
				for each( var attr:XML in bbox.attributes() )
				{
					var field:DataField;
					
					if (attr.name() == "y") 
					{
						y = DataUtil.parseValue(attr.toString(),DataUtil.NUMBER) as Number;
					}
						
					else if(attr.name() == "x")
					{
						x = DataUtil.parseValue(attr.toString(),DataUtil.NUMBER) as Number;
					}
						
					else if (attr.name() == "h")
					{
						h = DataUtil.parseValue(attr.toString(),DataUtil.NUMBER) as Number;
					}
						
					else if (attr.name() == "w")
					{
						w = DataUtil.parseValue(attr.toString(),DataUtil.NUMBER)  as Number;			
					}				
				}
				rect = new Rectangle(x,y,w,h);
				n[bbox_target] = rect;
			}
			
			return n;
			
		}
		
		public function parseLabelAttributes(labelList:XMLList, schema:DataSchema, type:String ,n:Object): Object
		{
			var labelTextTarget:String;
			
			if (type == "clone") 
			{
				labelTextTarget = CLONE_LABEL_TEXT;
			}
			else if(type == "glyph")
			{
				labelTextTarget = GLYPH_LABEL_TEXT;
			}	
			
			for each (var label:XML in labelList) 
			{
				for each( var attr:XML in label.attributes() )
				{
					var field:DataField;
					if (attr.name() == "text") 
					{
						field = schema.getFieldByName(labelTextTarget);
						n[labelTextTarget] = DataUtil.parseValue(attr.toString(), field.type);
					}
				}
			}
			
			// if any bbox element of label exists add them too
			if(label.elements("bbox").length() > 0)
			{
				n = parseBboxAttributes(label.elements("bbox"),schema,"glyph_label",n);
			}
			
			return n;
		}
		
		public function parseGlyphAttributes(glyphList:XML, schema:DataSchema, n:Object): Object
		{
			var field:DataField;
			
			// set default values			
			for (var i:int = 0; i < schema.numFields; ++i) 
			{
				field = schema.getFieldAt(i);
				n[field.name] = field.defaultValue;
			}
			
			var tmpObj:Object = n;
			for each (var glyph:XML in glyphList) 
			{
				for each( var attr:XML in glyph.attributes() )
				{
					if (attr.name() == ID) 
					{
						field = schema.getFieldByName(GLYPH_ID);
						tmpObj[GLYPH_ID] = DataUtil.parseValue(attr.toString(), field.type).toString();
						tmpObj[ID] = DataUtil.parseValue(attr.toString(), field.type).toString();
					}
					else if (attr.name() == CLASS)
					{
						field = schema.getFieldByName(GLYPH_CLASS);
						tmpObj[GLYPH_CLASS] = DataUtil.parseValue(attr.toString(), field.type);
					}
					else if (attr.name() == "orientation")
					{
						field = schema.getFieldByName(GLYPH_ORIENTATION);
						tmpObj[GLYPH_ORIENTATION] = DataUtil.parseValue(attr.toString(), field.type);
					}
				}
			}
			
			return tmpObj;
		}
		
		
		public function initArcSchema():DataSchema
		{
			var arcSchema:DataSchema = DataSchemaUtils.minimumEdgeSchema(false);
			
			//arcSchema.addField(new DataField(ARC_TARGET, DataUtil.STRING, "", ARC_TARGET));
			//arcSchema.addField(new DataField(ARC_SOURCE, DataUtil.STRING, "", ARC_SOURCE));
			arcSchema.addField(new DataField(ARC_CLASS, DataUtil.STRING, 0, ARC_CLASS));
			
			arcSchema.addField(new DataField(ARC_START_Y, DataUtil.NUMBER, 0, ARC_START_Y));
			arcSchema.addField(new DataField(ARC_START_X, DataUtil.NUMBER, 0, ARC_START_X));
			
			arcSchema.addField(new DataField(ARC_END_Y, DataUtil.NUMBER, 0, ARC_END_Y));
			arcSchema.addField(new DataField(ARC_END_X, DataUtil.NUMBER, 0, ARC_END_X));
			arcSchema.addField(new DataField(ARC_GLYPH_ID, DataUtil.STRING, "", ARC_GLYPH_ID));
			
			return arcSchema;
		}
		
		public function initGlyphSchema():DataSchema
		{
			
			var glyphSchema:DataSchema = DataSchemaUtils.minimumNodeSchema();
			
			//Attributes for SBNG-ML notation
			
			//Glyph specific
			//glyphSchema.addField(new DataField(GLYPH_ID, DataUtil.STRING, "", GLYPH_ID));
			glyphSchema.addField(new DataField(GLYPH_CLASS, DataUtil.STRING, "", GLYPH_CLASS));
			glyphSchema.addField(new DataField(GLYPH_ORIENTATION, DataUtil.STRING, "", GLYPH_ORIENTATION));
			glyphSchema.addField(new DataField(GLYPH_BBOX, DataUtil.OBJECT, null, GLYPH_BBOX));
			
			//Label specific
			glyphSchema.addField(new DataField(GLYPH_LABEL_TEXT, DataUtil.STRING, "", GLYPH_LABEL_TEXT));
			glyphSchema.addField(new DataField(GLYPH_LABEL_BBOX, DataUtil.OBJECT, null, GLYPH_LABEL_BBOX));
			
			//State specific
			glyphSchema.addField(new DataField(GLYPH_STATE_VALUE, DataUtil.STRING, "", GLYPH_STATE_VALUE));
			glyphSchema.addField(new DataField(GLYPH_STATE_VARIABLE, DataUtil.STRING, "", GLYPH_STATE_VARIABLE));
			
			//Clone specific
			glyphSchema.addField(new DataField(CLONE_MARKER, DataUtil.BOOLEAN, false, CLONE_MARKER));
			glyphSchema.addField(new DataField(CLONE_LABEL_TEXT, DataUtil.STRING, "", CLONE_LABEL_TEXT));
			glyphSchema.addField(new DataField(CLONE_LABEL_BBOX, DataUtil.OBJECT, null, CLONE_LABEL_BBOX));
			
			//Addition for adjusting label of nodes according to state or info boxes
			glyphSchema.addField(new DataField(HAS_STATE, DataUtil.BOOLEAN, false, HAS_STATE));
			glyphSchema.addField(new DataField(HAS_INFO, DataUtil.BOOLEAN, false, HAS_INFO));
			
			//Array for state and info glyphs
			glyphSchema.addField(new DataField(STATE_AND_INFO_GLYPHS, DataUtil.OBJECT, false, STATE_AND_INFO_GLYPHS));
			
			//Label offset field moved here because of performance reasons on custom mapper of cytoscapeweb.
			glyphSchema.addField(new DataField(LABEL_OFFSET, DataUtil.NUMBER, 0, LABEL_OFFSET));
			
			return glyphSchema;
		}	
	}
}