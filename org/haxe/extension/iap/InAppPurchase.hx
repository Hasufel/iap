package org.haxe.extension.iap;


import flash.events.EventDispatcher;
import flash.events.Event;
import flash.net.SharedObjectFlushStatus;
import flash.net.SharedObject;
import flash.Lib;

#if android
import openfl.utils.JNI;
#end


class InAppPurchase {
	
	
	private static var dispatcher = new EventDispatcher ();
	private static var initialized = false;
	private static var items = new Map<String, Int> ();
	
	
	public static function addEventListener (type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		
		dispatcher.addEventListener (type, listener, useCapture, priority, useWeakReference);
		
	}
	
	
	public static function buy (productID:String):Void {
		
		#if ios
		
		purchases_buy (productID);
		
		#elseif android	
		
		if (funcBuy == null) {
			
			funcBuy = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "buy", "(Ljava/lang/String;)V");
			
		}
		
		funcBuy (productID);
		
		#end
			
	}
	
	
	public static function canBuy ():Bool {
		
		#if ios
		
		return purchases_canbuy ();
		
		#else
		
		return false;
		
		#end
		
	}
	
	
	public static function dispatchEvent (event:Event):Bool {
		
		return dispatcher.dispatchEvent (event);
		
	}
	
	
	public static function getDescription (productID:String):String {
		
		#if ios
		
		return purchases_desc (productID);
		
		#else
		
		return "None";
		
		#end
		
	}
	
	
	public static function getPrice (productID:String):String {
		
		#if ios
		
		return purchases_price (productID);
		
		#else
		
		return "None";
		
		#end
		
	}
	
	
	public static function getQuantity (productID:String):Int {
		
		#if ios
		
		if (hasBought (productID)) {
			
			return items.get (productID);
			
		}
		
		#end
		
		return 0;
		
	}
	
	
	public static function getTitle (productID:String):String {
		
		#if ios
		
		return purchases_title (productID);
		
		#else
		
		return "None";
		
		#end
		
	}
	
	
	public static function hasBought (productID:String):Bool {
		
		#if ios
		
		if (items == null) {
			
			return false;
			
		}
		
		return items.exists (productID) && items.get (productID) > 0;
		
		#else
		
		return false;
		
		#end
		
	}
	
	
	public static function hasEventListener (type:String):Bool {
		
		return dispatcher.hasEventListener (type);
		
	}
	
	
	public static function initialize (publicKey:String = ""):Void {
		
		#if ios
		
		if (!initialized) {
			
			set_event_handle (notifyListeners);
			load ();
			
			initialized = true;
			
		}
		
		purchases_initialize ();
		
		#elseif android
		
		if (funcInit == null) {
			
			funcInit = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "initialize", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V");
			load ();
			
		}
		
		funcInit (publicKey, new InAppPurchaseHandler ());
		
		#end
		
	}
	
	
	private static function load ():Void {
		
		try {
			
			var data = SharedObject.getLocal ("in-app-purchases");
			var saveData = Reflect.field (data.data, "data");
			
			if (saveData != null) {
				
				items = saveData;
				//trace (items);
				
			}
			
		} catch (e:Dynamic) {
			
			trace ("ERROR: Could not load purchases: " + e);
			
		}
		
	}
	
	
	private static function notifyListeners (inEvent:Dynamic):Void {
		
		#if ios
		
		var type = Std.string (Reflect.field (inEvent, "type"));
		var data = Std.string (Reflect.field (inEvent, "data"));
		
		switch (type) {
			
			case "started":
				
				dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_READY, data));
				
			case "success":
				
				dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_SUCCESS, data));
			
			case "failed":
				
				dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_FAILED, data));
			
			case "cancel":
				
				dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_CANCELED, data));
			
			case "restore":
				
				dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_RESTORED, data));
			
			default:
			
		}
		
		// Consumable
		
		if (type == "success") {
			
			var productID = data;
			
			if (hasBought (productID)) {
				
				items.set (productID, InAppPurchase.items.get (productID) + 1);
				
			} else {
				
				items.set (productID, 1);
				
			}
			
			save ();
			
		}
		
		#end
		
	}
	
	
	private static function registerHandle ():Void {
		
		#if ios
		
		set_event_handle (notifyListeners);
		
		#end
		
	}
	
	
	public static function release ():Void {
		
		#if ios
		
		purchases_release ();
		
		#end
		
	}
	
	
	public static function removeEventListener (type:String, listener:Dynamic, capture:Bool = false):Void {
		
		dispatcher.removeEventListener (type, listener, capture);
		
	}
	
	
	public static function restorePurchases ():Void {
		
		#if ios
		
		purchases_restore ();
		
		#elseif android
		//
		//if (funcRestore == null) {
		//	
		//	funcRestore = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "restore", "()V");
		//	
		//}
		//
		//funcRestore ();
		
		#end
		
	}
	
	
	private static function save ():Void {
		
		var so = SharedObject.getLocal("in-app-purchases");
		Reflect.setField(so.data, "data", items);
		
		#if (cpp || neko)
		
		var flushStatus:SharedObjectFlushStatus = null;
		
		try {
			
			flushStatus = so.flush ();
			
		} catch (e:Dynamic) {
			
			trace ("ERROR: Failed to save purchases: " + e);
			
		}
		
		/*if (flushStatus != null) {
			
			switch (flushStatus) {
				
				case SharedObjectFlushStatus.PENDING: trace ("Requesting permission to save purchases");
				case SharedObjectFlushStatus.FLUSHED: trace ("Saved purchases");
				default:
				
			}
			
		}*/
		
		#end
		
	}
	
	
	public static function use (productID:String):Void {
		
		#if ios
		
		if (hasBought (productID)) {
			
			items.set (productID, items.get (productID) - 1);
			save ();
			
		}
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if android
	
	private static var funcInit:Dynamic;
	private static var funcBuy:Dynamic;
	private static var funcRestore:Dynamic;
	private static var funcTest:Dynamic;
	
	#elseif ios
	
	private static var purchases_initialize = Lib.load ("iap", "iap_initialize", 0);
	private static var purchases_restore = Lib.load ("iap", "iap_restore", 0);
	private static var purchases_buy = Lib.load ("iap", "iap_buy", 1);
	private static var purchases_canbuy = Lib.load ("iap", "iap_canbuy", 0);
	private static var purchases_release = Lib.load ("iap", "iap_release", 0);
	private static var purchases_title = Lib.load ("iap", "iap_title", 1);
	private static var purchases_desc = Lib.load ("iap", "iap_desc", 1);
	private static var purchases_price = Lib.load ("iap", "iap_price", 1);
	private static var set_event_handle = Lib.load ("iap", "iap_set_event_handle", 1);
	
	#end
	
	
}


#if (android && !display)


@:access(org.haxe.extension.iap.InAppPurchase) class InAppPurchaseHandler {
	
	
	public function new () {
		
		
		
	}
	
	
	public function onCanceledPurchase (productID:String):Void {
		
		InAppPurchase.dispatcher.dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_CANCELED, productID));
		
	}
	
	
	public function onFailedPurchase (productID:String):Void {
		
		InAppPurchase.dispatcher.dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_FAILED, productID));
		
	}
	
	
	public function onPurchase (productID:String):Void {
		
		InAppPurchase.dispatcher.dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_SUCCESS, productID));
		
		if (InAppPurchase.hasBought (productID)) {
			
			InAppPurchase.items.set (productID, InAppPurchase.items.get (productID) + 1);
			
		} else {
			
			InAppPurchase.items.set (productID, 1);
			
		}
		
		InAppPurchase.save ();
		
	}
	
	
	public function onRestorePurchases ():Void {
		
		InAppPurchase.dispatcher.dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_RESTORED));
		
	}
	
	
	public function onStarted (msg:String):Void {
		
		InAppPurchase.dispatcher.dispatchEvent (new InAppPurchaseEvent (InAppPurchaseEvent.PURCHASE_READY));
		
	}
	
	
}

#end