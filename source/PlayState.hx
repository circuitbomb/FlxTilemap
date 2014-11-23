﻿package;

import coffeegames.mapgen.MapAlign;
import coffeegames.mapgen.MapGenerator;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import tile.FlxIsoTilemap;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	//Set this to true to debug map culling
	static inline var CULLING_DEBUG:Bool = false;
	
	var mapGen:MapGenerator;
	var mapHeight:Int;
	var mapWidth:Int;
	var map:FlxIsoTilemap;
	var initial:flixel.math.FlxPoint;
	var final:flixel.math.FlxPoint;
	var player:Player;
	var cursor:flixel.FlxSprite;
	var text:String;
	var instructions:FlxText;
	
	var uiCam:FlxCamera;
	var mapCam:flixel.FlxCamera;
	var isZooming:Bool;
	var minimap:Bitmap;
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		super.create();
		
		FlxG.log.redirectTraces = false;
		FlxG.debugger.drawDebug = true;
		
		isZooming = false;
		
		//Map generator pre-defined sizes
		mapWidth = 100;
		mapHeight = 100;
		
/*		mapWidth = 150;
		mapHeight = 300;*/

		//Works!
/*		mapWidth = 1000;
		mapHeight = 1000;*/
		
		//Map camera
		mapCam = new FlxCamera(0, 0, 1280, 720, 1);
		FlxG.cameras.add(mapCam);
		
		//User interface camera
		uiCam = new FlxCamera(0, 0, 1280, 720, 1);
		uiCam.bgColor = 0x0000000;
		FlxG.cameras.add(uiCam);
		
		//Create the map and the player
		createMap();
		
		//Creates all user interface elements
		createUI();
		
		//Map mouse / touch scrolling helpers
		initial = FlxPoint.get(0, 0);
		final = FlxPoint.get(0, 0);
		
		//Cursor to show mouse click position
		cursor = new FlxSprite(0, 0);
		cursor.set_camera(mapCam);
		cursor.loadGraphic("images/cursor.png", true, 48, 72);
		add(cursor);
	}
	
	function createMap()
	{
		//Initializing map generator
		mapGen = new MapGenerator(mapWidth, mapHeight, 3, 5, 11, false);
		mapGen.setIndices(9, 8, 10, 11, 14, 16, 17, 15, 7, 5, 1, 1, 0);
		mapGen.generate();
		
		//Shows the minimap
		minimap = mapGen.showMinimap(FlxG.stage, 3, MapAlign.TopLeft);
		FlxG.addChildBelowMouse(minimap);
		mapGen.showColorCodes();
		
		//Getting data from generator
		var mapData:Array<Array<Int>> = mapGen.extractData();
		
		//Isometric tilemap
		if (CULLING_DEBUG)
			map = new FlxIsoTilemap(new Rectangle(128, 128, 1024, 464));
		else
			map = new FlxIsoTilemap(new Rectangle(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight));
			
		map._tileDepth = 24;
		map.loadMapFrom2DArray(mapData, "images/tileset.png", 48, 48, FlxTilemapAutoTiling.OFF, 0, 0, 1);
		map.adjustTiles();
		map.setTileProperties(0, FlxObject.NONE, onMapCollide, null, 2);
		map.setTileProperties(5, FlxObject.NONE, onMapCollide, null, 3);
		map.setTileProperties(8, FlxObject.ANY, onMapCollide, null, 10);
		map.cameras = [mapCam];
		#if debug
		map.ignoreDrawDebug = false;
		#end
		add(map);
		
		//Adding player to map
		player = new Player(0, 0);
		player.set_camera(mapCam);
		map.add(player);
		//Setting player position
		var isoPt:FlxPoint = map.getIsoPointByCoords(FlxPoint.weak(640, 96));
		var isoCoords = map.getIsoTileByMapCoords(Std.int(isoPt.x), Std.int(isoPt.y));
		var initialTile = map.getIsoTileByMapCoords(Std.int(isoPt.x), Std.int(isoPt.y));
		player.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
	}
	
	function createUI()
	{
		if (CULLING_DEBUG) {
			var frame = new FlxObject(128, 128, 1024, 464);
			#if debug
			frame.debugBoundingBoxColor = 0xFFFFFF;
			#end
			frame.set_camera(uiCam);
			add(frame);
			
			var scrCenterX = new FlxObject(639, 128, 2, 463);
			#if debug
			scrCenterX.debugBoundingBoxColor = 0xFFFFFF;
			#end
			scrCenterX.set_camera(uiCam);
			add(scrCenterX);
			
			var scrCenterY = new FlxObject(128, 359, 1024, 2);
			#if debug
			scrCenterY.debugBoundingBoxColor = 0xFFFFFF;
			#end
			scrCenterY.set_camera(uiCam);
			add(scrCenterY);
			
			var frameColor = 0xDD666666;
			//var frameColor = 0xFF666666;
			var top = new FlxSprite(0, 0);
			top.makeGraphic(1280, 128, frameColor);
			top.ignoreDrawDebug = true;
			top.set_camera(uiCam);
			add(top);
			
			var bottom = new FlxSprite(0, 592);
			bottom.makeGraphic(1280, 128, frameColor);
			bottom.ignoreDrawDebug = true;
			bottom.set_camera(uiCam);
			add(bottom);
			
			var left = new FlxSprite(0, 128);
			left.makeGraphic(128, 464, frameColor);
			left.ignoreDrawDebug = true;
			left.set_camera(uiCam);
			add(left);
			
			var right = new FlxSprite(1152, 128);
			right.makeGraphic(128, 464, frameColor);
			right.ignoreDrawDebug = true;
			right.set_camera(uiCam);
			add(right);
		}
		
		//Adding instruction label
		text = "";
		#if (web || desktop)
		text = "ARROWS - Move player | WASD - Scroll map | SPACE - reset | ENTER - Spawn chars | ZOOM : 1";
		#elseif (ios || android)
		text = "TOUCH AND DRAG - Scroll Map | TOUCH MAP - Move char to map position | ZOOM : 1";
		#end
		var textPos = minimap.x + minimap.width + 10;
		var textWidth = 1280 - minimap.width - 30;
		instructions = new FlxText(textPos, 10, textWidth, text, 14);
		instructions.scrollFactor.set(0, 0);
		instructions.set_camera(uiCam);
		instructions.ignoreDrawDebug = true;
		add(instructions);
	}
	
	/**
	 * Function that is called when this state is destroyed - you might want to 
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		// ### TODO: Test / make collision work
/*		FlxG.collide(map, map.spriteGroup, onMapCollide);
		map.overlaps(map.spriteGroup);*/
		
		handleInput(elapsed);
		handleTouchInput(elapsed);
	}
	
	function handleInput(elapsed:Float)
	{
		//Scrolls the map
		if (FlxG.keys.pressed.A)
			mapCam.scroll.x -= 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.D)
			mapCam.scroll.x += 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.W)
			mapCam.scroll.y -= 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.S)
			mapCam.scroll.y += 300 * FlxG.elapsed;
		
		//Restart the demo
		if (FlxG.keys.justPressed.SPACE) {
			FlxG.resetState();
		}
		
		//Adds 10 automatons
		if (FlxG.keys.justPressed.ENTER) {
			for (i in 0...10)
			{
				var automaton = new Automaton(0, 0);
				var isoPt:FlxPoint = map.getIsoPointByCoords(FlxPoint.weak(640, 360));
				trace( "Automaton -> isoPt : " + isoPt );
				var isoCoords = map.getIsoTileByMapCoords(Std.int(isoPt.x), Std.int(isoPt.y));
				trace( "Automaton -> isoCoords : " + isoCoords );
				
				var initialTile = map.getIsoTileByMapCoords(Std.int(isoPt.x), Std.int(isoPt.y));
				trace( "Automaton -> initialTile : " + initialTile );
				automaton.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
				map.add(automaton);
			}
		}
	}
	
	function handleTouchInput(elapsed:Float)
	{
		//Mouse drag start
		if (FlxG.mouse.justPressed) {
			//Get initial mouse press position
			initial = FlxG.mouse.getScreenPosition();
		}
		
		//Mouse drag end / click to move character
		if (FlxG.mouse.justReleased) {
			
			//Gets final mouse position after releasing press
			final = FlxG.mouse.getScreenPosition();
			
			//If initial and final click distance is small, consider it a click
			if (final.distanceTo(initial) < 2 && !player.isWalking) {
				
				//Mouse world position
				var wPos = FlxG.mouse.getWorldPosition(mapCam);
				//Player target tile
				var tile = map.getIsoTileByCoords(wPos);
				
				//Player target position (tile position with offsets)
				var tPos = FlxPoint.get(tile.isoPos.x + player.width / 2, tile.isoPos.y + player.height / 2);
				trace("Player -> Target tile position : " + tile.isoPos.x + "," + tile.isoPos.y + " | Map : " + tile.mapPos.x + "," + tile.mapPos.y);
				
				
				// ### TODO: Fix 'findPath' to work correctly with iso
/*				var pPos = FlxPoint.get(player.isoContainer.isoPos.x, player.isoContainer.isoPos.y);
				trace( "pPos : " + pPos );
				var points = map.findPath(pPos, tPos);
				trace( "points : " + points );
				
				if (points != null) {
					for (i in 0...points.length) {
						var t = map.getIsoTileByCoords(points[i]);
						map.setIsoTile(Std.int(t.mapPos.y), Std.int(t.mapPos.x), 0);
					}
					
					player.walkPath(points, 100);
				}*/
				
				
				//Walks directly to target
				player.walkPath([tPos], 200);
				
				
				//Sets the player position directly (debugging purposes)
				//player.setPosition(tile.isoPos.x + player.width / 2, tile.isoPos.y + player.height / 2);
				//trace("Player actual position : " + player.isoContainer.toString());
				
				
				//Placing cursor over the selected tile (offsets for correct positioning)
				cursor.x = tile.isoPos.x - cursor.width / 2;
				cursor.y = tile.isoPos.y - cursor.height / 2;
			}
		}
		
		//Mouse drag to scroll camera
		if (FlxG.mouse.pressed) {
			var pt = FlxG.mouse.getScreenPosition();
			if (pt.x > initial.x) {
				var amount = pt.x - initial.x;
				mapCam.scroll.x -= 2 * amount * elapsed;
			} 
			
			if (pt.x < initial.x) {
				var amount = initial.x - pt.x;
				mapCam.scroll.x += 2 * amount * elapsed;
			}
				
			if (pt.y > initial.y) {
				var amount = pt.y - initial.y;
				mapCam.scroll.y -= 2 * amount * elapsed;
			} 
			
			if (pt.y < initial.y) {
				var amount = initial.y - pt.y;
				mapCam.scroll.y += 2 * amount * elapsed;
			}
		}
		
		//Camera zoom in
		if (FlxG.mouse.wheel > 0 && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom + 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
			}} );
		}
		
		//Camera zoom out
		if (FlxG.mouse.wheel < 0 && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom - 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
			}} );
		}
	}
	
	function onMapCollide(objA:Dynamic, objB:Dynamic):Void
	{
		if (objB.allowCollisions == FlxObject.ANY) {
			//trace("Collided with wall tile");
		}
	}
}