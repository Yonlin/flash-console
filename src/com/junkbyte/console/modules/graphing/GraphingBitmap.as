package com.junkbyte.console.modules.graphing
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class GraphingBitmap
	{
		protected var _panel:GraphingPanelModule;
		protected var _group:GraphingGroup;

		protected var _bm:Bitmap;
		protected var _bmd:BitmapData;

		protected var lowestValue:Number;
		protected var highestValue:Number;
		protected var lastValues:Object = new Object();

		public function GraphingBitmap(panel:GraphingPanelModule, group:GraphingGroup)
		{
			_panel = panel;
			_group = group;
			initDisplay();
		}

		protected function initDisplay():void
		{

			_bm = new Bitmap();
			_panel.addChild(_bm);
		}

		public function setArea(x:Number, y:Number, w:Number, h:Number):void
		{
			_bm.y = y;
			if (_bmd != null && _bmd.width == w && _bmd.height == h)
			{
				return;
			}
			var prevBMD:BitmapData = _bmd;
			_bmd = new BitmapData(w, h, true, 0);
			if (prevBMD != null)
			{
				var matrix:Matrix = new Matrix(1, 0, 0, _bmd.height / prevBMD.height);
				matrix.tx = _bmd.width - prevBMD.width;
				_bmd.draw(prevBMD, matrix, null, null, null, true);
				prevBMD.dispose();
			}
			_bm.bitmapData = _bmd;
		}

		public function reset():void
		{
			lowestValue = highestValue = NaN;
			lastValues = new Object();
		}

		public function push(values:Vector.<Number>):void
		{
			var lowest:Number = isNaN(_group.fixedMin) ? lowestValue : _group.fixedMin;
			var highest:Number = isNaN(_group.fixedMax) ? highestValue : _group.fixedMax;

			for each (var v:Number in values)
			{
				if (isNaN(_group.fixedMin) && (isNaN(lowest) || v < lowest))
				{
					lowest = v;
				}
				if (isNaN(_group.fixedMax) && (isNaN(highest) || v > highest))
				{
					highest = v;
				}
			}

			if (lowestValue != lowest || highestValue != highest)
			{
				scaleBitmapData(lowest, highest);
			}
			draw(values);
		}

		protected function scaleBitmapData(newLow:Number, newHigh:Number):void
		{
			var scaleBMD:BitmapData = _bmd.clone();
			_bmd.fillRect(new Rectangle(0, 0, _bmd.width, _bmd.height), 0);

			var newDiff:Number = newHigh - newLow;

			if (newDiff != 0)
			{
				var valuePerPixel:Number = newDiff /_bmd.height;
				var valuePerHalfPixel:Number = valuePerPixel * 0.5;
				newHigh += valuePerHalfPixel;
				newLow -= valuePerHalfPixel;
				
				newDiff = newHigh - newLow;
			}

			var oldDiff:Number = highestValue - lowestValue;

			var matrix:Matrix = new Matrix();
			matrix.ty = (newHigh - highestValue) / oldDiff * _bmd.height;
			matrix.scale(1, oldDiff / newDiff);
			_bmd.draw(scaleBMD, matrix, null, null, null, true);
			
			scaleBMD.dispose();

			lowestValue = newLow;
			highestValue = newHigh;
		}

		protected function draw(values:Vector.<Number>):void
		{
			var diffGraph:Number = highestValue - lowestValue;
			var pixX:uint = _bmd.width - 1;

			var H:int = _bmd.height;

			_bmd.lock();

			_bmd.scroll(-1, 0);
			_bmd.fillRect(new Rectangle(pixX, 0, 1, _bmd.height), 0);

			for (var i:int = _group.lines.length - 1; i >= 0; i--)
			{
				var interest:GraphingLine = _group.lines[i];
				var value:Number = values[i];
				var pixY:int = ((value - lowestValue) / diffGraph) * H;
				pixY = makePercentValue(pixY);

				var lastValue:Number = lastValues[i];

				if (isNaN(lastValue) == false)
				{
					var pixY2:int = ((lastValue - lowestValue) / diffGraph) * H;
					pixY2 = makePercentValue(pixY2);
					var min:int = Math.min(pixY, pixY2);
					var max:int = Math.max(pixY, pixY2);
					_bmd.fillRect(new Rectangle(pixX, min, 1, Math.max(1, max - min)), interest.color + 0xCC000000);
				}
				_bmd.setPixel32(pixX, pixY, interest.color + 0xFF000000);

				lastValues[i] = value;
			}
			_bmd.unlock();
		}

		protected function makePercentValue(value:Number):Number
		{
			if (!_group.inverted)
			{
				value = _bmd.height - value;
			}
			if (value < 0)
			{
				value = 0;
			}
			if (value >= _bmd.height)
			{
				value = _bmd.height - 1;
			}
			return value;
		}
	}
}