var nwHELPER = nwPLUGINS['build_helper'];
var nwDECOMP = require('decompress');

exports.modules = ['entity', 'image', 'state', 'spritesheet', 'audio', 'script'];
exports.colors = [
/*
	'#ef9a9a', // red 200
	'#e57373', // red 300
	'#ef5350', // red 400
*/
	'#f48fb1', // pink 200
	'#f06292', // pink 300
	'#ec407a', // pink 400

	'#90caf9', // blue 200
	'#64b5f6', // blue 300
	'#42a5f5', // blue 400
]

// code editor
exports.entity_template = nwPATH.join(__dirname, 'entity_template.lua');
exports.state_template = nwPATH.join(__dirname, 'state_template.lua');
exports.language = 'lua';
exports.file_ext = 'lua';

function getBuildPath() {
	return nwPATH.join(b_project.curr_project, 'BUILDS');
}

exports.targets = {
	"love" : {
		build: function(objects) {
			b_console.log('build: love')

			buildLove(objects, function(path){
				eSHELL.openItem(nwPATH.dirname(path));
			});
		}
	},

	"windows" : {
		build: function(objects) {
			b_console.log('build: windows')

			var build_path = nwPATH.join(getBuildPath(), 'windows',  b_project.getSetting("engine", "title")+'.exe');
			nwMKDIRP(nwPATH.dirname(build_path), function(){

				buildLove(objects, function(path){
					downloadLove('win', function(){

						switch(nwOS.platform()) {
							case "win32":
								// combine love.exe and .love
								// Ex. copy /b love.exe+SuperGame.love SuperGame.exe
								cmd = 'copy /b \"'+nwPATH.join(getLoveFolder('win'), "love.exe")+'\"+\"'+path+'\" \"'+build_path+'\"';
								nwCHILD.exec(cmd);

								// copy required dlls
								var other_files = ["love.dll", "lua51.dll", "mpg123.dll", "SDL2.dll"];
								for (var o = 0; o < other_files.length; o++) {
									var file = other_files[o];
									nwFILEX.copy(nwPATH.join(getLoveFolder('win'), file), nwPATH.join(nwPATH.dirname(build_path), file));
								}
								
								eSHELL.openItem(nwPATH.dirname(build_path));
							break;
						}

					});
					
				});

			});
		}
	},

	"mac" : {
		build: function(objects) {
			var build_path = nwPATH.join(getBuildPath(), 'mac')

			nwMKDIRP(build_path, function(){
				downloadLove('mac', function(){

					// copy love.app and rename it
					build_path = nwPATH.join(build_path, b_project.getSetting("engine", "title")+'.app');
					nwFILEX.copy(nwPATH.join(getLoveFolder('mac'), "love.app"), build_path, function(){
						// create .love and copy it into app/Contents/Resources/
						buildLove(objects, function(path){
							nwFILEX.copy(path, nwPATH.join(build_path, 'Contents', 'Resources', b_project.getSetting("engine", "title")+'.love'));

							// modify app/Contents/Info.plist			
							plist_repl = [
								['<COMPANY>', 'Made with BlankE'],
								['<TITLE>', b_project.getSetting("engine", "title")]
							];
							plist_path = nwPATH.join(build_path, 'Contents', 'Info.plist');
							nwHELPER.copyScript(plist_path, plist_path, plist_repl);

							eSHELL.openItem(nwPATH.dirname(build_path));
						});
					});

				});
			});
		}
	}
}

// problem with decompress mac build
function downloadLove(os='win', callback) {
	// check if already downloaded
	nwFILE.stat(getLoveFolder(os), function(err, stat){
		if (err || !stat.isDirectory()) {

			nwMKDIRP(getLoveDownFolder(os), function(){
				// download version for os
				var zip_path = getLoveFolder(os)+".zip";
				b_console.log('downloading ' + nwPATH.basename(zip_path));
				nwHELPER.download(getLoveURL(os), zip_path, function(err){
					// unzip it
					nwDECOMP(zip_path, getLoveDownFolder(os)).then(function(files){
						// delete zip
						nwFILEX.remove(zip_path);
						if (callback) callback();
					});
				});
			});

		} else {
			if (callback) callback();
		}
	});
}

function getLoveURL(os='win', version=b_project.getSetting("engine", "version")) {
	var paths = {
		'win' : "http://bitbucket.org/rude/love/downloads/love-"+version+"-win32.zip",
		'mac' : "http://bitbucket.org/rude/love/downloads/love-"+version+"-macosx-x64.zip"
	}
	return paths[os];
}

function getLoveDownFolder(os='', version=b_project.getSetting("engine", "version")) {
	var paths = {
		'' : nwPATH.join(__dirname, "bin"),
		'win' : nwPATH.join(__dirname, "bin"),
		'mac' : nwPATH.join(__dirname, "bin", "love-"+version+"-macosx-x64")
	}
	return paths[os];
}

function getLoveFolder(os='', version=b_project.getSetting("engine", "version")) {
	var paths = {
		'' : nwPATH.join(__dirname, "bin"),
		'win' : nwPATH.join(__dirname, "bin", "love-"+version+"-win32"),
		'mac' : nwPATH.join(__dirname, "bin", "love-"+version+"-macosx-x64", "love.app")
	}
	return paths[os];
}

// only works for windows atm
function runLove(love_path, show_cmd=b_project.getSetting("engine","console")) {
	downloadLove('win', function(){
		var cmd = '';
		if (show_cmd) 
			cmd = 'start cmd.exe /K \"\"'+nwPATH.join(getLoveFolder('win'), "love.exe")+'\" \"'+love_path+'\"\"';
		else 
			cmd = '\"'+nwPATH.join(getLoveFolder('win'), "love.exe")+'\" \"'+love_path+'\"';
		
		nwCHILD.exec(cmd);
	});
}

exports.run = function(objects) {
	last_object_set = objects;
	var path = nwPATH.join(getBuildPath(), 'temp');
	build(path, objects, function(){
		runLove(path);
	});
} 

exports.settings = {
	"includes" : [
		{"type" : "bool", "name" : "printr", "default" : "false", "tooltip": "Print tables using print_r", "include": 'require "plugins.printr"'},
		{"type" : "bool", "name" : "luasocket", "default" : "false", "tooltip": "helper for http requests", "include": 'require "plugins.luasocket"'},
		{"type" : "bool", "name" : "enet", "default" : "false", "tooltip": "helper for multiplayer networking", "include": 'require "plugins.enet"'}
	],/*
	"blanke helpers" : [
		{"type" : "bool", "name" : "pause on lose focus", "default" : "true", "tooltip": "pause the game if the user minimizes the window or switches to a different window"}
	],*/
	"misc" : [
		{"type" : "text", "name" : "identity", "default" : "nil", "tooltip": "The name of the save directory"},
		{"type" : "text", "name" : "version", "default" : "0.10.2", "tooltip": "The LÖVE version this game was made for"},
		{"type" : "bool", "name" : "console", "default" : "false", "tooltip": "Attach a console (Windows only)"},
		{"type" : "bool", "name" : "accelerometer joystick", "default" : "true", "tooltip": "Enable the accelerometer on iOS and Android by exposing it as a Joystick"},
		{"type" : "bool", "name" : "external storage", "default" : "false", "tooltip": "True to save files (and read from the save directory) in external storage on Android"},
		{"type" : "bool", "name" : "gamma correct", "default" : "false"}
	],
	"window" : [
		{"type" : "text", "name" : "title", "default" : "Untitled"},
		// icon
		{"type" : "number", "name" : "width", "default" : 800, "min" : 0, "max" : 1000000},
		{"type" : "number", "name" : "height", "default" : 600, "min" : 0, "max" : 1000000},
		{"type" : "bool", "name" : "borderless", "default" : "false"},
		{"type" : "bool", "name" : "resizable", "default" : "true"},
		{"type" : "number", "name" : "minwidth", "default" : 1, "min" : 0, "max" : 1000000},
		{"type" : "number", "name" : "minheight", "default" : 1, "min" : 0, "max" : 1000000},

		{"type" : "bool", "name" : "fullscreen", "default" : "false"},
		{"type" : "select", "name" : "fullscreen type", "default" : "desktop", "options" : ["desktop", "exclusive"]},
		{"type" : "bool", "name" : "vsync", "default" : "true"},

		{"type" : "number", "name" : "msaa", "default" : 0, "min" : 0, "max" : 16, "tooltip": "The number of samples to use with multi-sampled antialiasing"},
		{"type" : "number", "name" : "display", "default" : 0, "min" : 0, "max" : 16, "tooltip": "Index of the monitor to show the window in"},
		{"type" : "bool", "name" : "highdpi", "default" : "false", "tooltip": "Enable high-dpi mode for the window on a Retina display"}
		// window.x
		// window.y	
	], 
	"modules" : [
		{"type" : "bool", "name" : "audio", "default" : "true"},
		{"type" : "bool", "name" : "event", "default" : "true"},
		{"type" : "bool", "name" : "graphics", "default" : "true"},
		{"type" : "bool", "name" : "image", "default" : "true"},
		{"type" : "bool", "name" : "joystick", "default" : "true"},
		{"type" : "bool", "name" : "keyboard", "default" : "true"},
		{"type" : "bool", "name" : "math", "default" : "true"},
		{"type" : "bool", "name" : "mouse", "default" : "true"},
		{"type" : "bool", "name" : "physics", "default" : "true"},
		{"type" : "bool", "name" : "sound", "default" : "true"},
		{"type" : "bool", "name" : "system", "default" : "true"},
		{"type" : "bool", "name" : "timer", "default" : "true", "tooltip": "Disabling it will result 0 delta time in love.update"},
		{"type" : "bool", "name" : "touch", "default" : "true"},
		{"type" : "bool", "name" : "video", "default" : "true"},
		{"type" : "bool", "name" : "window", "default" : "true"},
		{"type" : "bool", "name" : "thread", "default" : "true"}
	]
}

var codemirror;
var love2d_uuid = guid();
exports.library_const = [
	{
		"name": "main.lua",
		dbl_click: function() {
			b_ui.openCodeEditor({
				uuid: love2d_uuid,
				type: 'main',
				properties: {
					name: 'main.lua'
				},
				editor: {
					file_path: nwPATH.join(b_project.curr_project, "assets", "main.lua")
				}
			});
		}

	}
]

exports.loaded = function() {
	document.addEventListener("project.open", function(e){
		if (b_project.getData("engine") !== "love2d") return;
		// copy main.lua template to project folder
		nwFILE.stat(nwPATH.join(b_project.curr_project, "assets", "main.lua"), function(err, stat){
			if (err || !stat.isFile()) {
				var html_code = nwFILEX.copy(
					nwPATH.join(__dirname, 'main.lua'),
					nwPATH.join(b_project.curr_project, "assets", "main.lua")
				);
			}
		});
	});

	document.addEventListener("filedrop", function(e){
		if (nwPATH.extname(e.detail.path) == ".love") {
			runLove(e.detail.path);
		}
	});
}



var building = false;
function build(build_path, objects, callback) {
	if (building) return;
	building = true;

	var script_includes = '';

	// PLUGINS
	var remove_plugins = [];
	for (var p = 0; p < exports.settings.includes.length; p++) {
		var plugin = exports.settings.includes[p];

		if (b_project.getSetting("engine", plugin.name))
			script_includes += plugin.include + '\n';
		else 
			remove_plugins.push(plugin.name);
	}

	// ENTITIES
	for (var e in objects['entity']) {
		var ent = objects['entity'][e];

		if (ent.code_path.length > 1)
			script_includes += ent.name + " = require \"assets/scripts/"+ent.code_path.replace(/\\/g,"/").replace('.lua','')+"\"\n";
	}

	// STATES
	var state_init = '';
	var first_state = '';
	for (var e in objects['state']) {
		var ent = objects['state'][e];

		if (first_state === '') {
			first_state = ent.name;
		}

		if (ent.code_path.length > 1)
			script_includes += ent.name + " = require \"assets/scripts/"+ent.code_path.replace(/\\/g,"/").replace('.lua','')+"\"\n";
	}

	var assets = '';

	// SCRIPTS
	for (var e in objects['script']) {
		var script = objects['script'][e];
		var path = script.code_path;

		assets += "function assets:"+script.name+"()\n"+
				  "\treturn 'assets/scripts/"+path.replace(/\\/g,"/").replace('.lua','')+"'\n"+
				  "end\n\n";
	}

	// IMAGES
	for (var e in objects['image']) {
		var img = objects['image'][e];
		var params = img.parameters;

		// wrap undefined bug
		var comment_wrap = (params["[wrap]horizontal"] == undefined ? "--" : "");

		assets += "function assets:"+img.name+"()\n"+
				  "\tlocal new_img = love.graphics.newImage(\'assets/image/"+img.path+"\')\n"+
				  "\tnew_img:setFilter('"+params.min+"', '"+params.mag+"', "+params.anisotropy+")\n"+
			 	  "\t"+comment_wrap+"new_img:setWrap('"+params["[wrap]horizontal"]+"', '"+params["[wrap]vertical"]+"')\n"+
			 	  "\treturn new_img\n"+
			 	  "end\n\n";			  
	}

	// AUDIO
	for (var e in objects['audio']) {
		var audio = objects['audio'][e];
		var params = audio.parameters;
		
		assets += "function assets:"+audio.name+"()\n"+
				  "\tlocal new_audio = love.audio.newSource(\'assets/audio/"+audio.path+"\', \'"+params.type+"\')\n";
		
		var values = [
			["Looping", params.looping],
			["Volume", params.volume],
			["Pitch", params.pitch],
			["VolumeLimits", params["[volume]min"]+", "+params["[volume]max"]],
		];
		for (var v = 0; v < values.length; v++) {
			assets += "\tnew_audio:set"+values[v][0]+"("+values[v][1]+")\n";
		}

		// add things only mono channel audio can do
		var mono_values = [
			["Position", params["[position]x"]+", "+params["[position]y"]+", "+params["[position]z"]],
			["Cone", params.innerAngle+", "+params.outerAngle+", "+params.outerVolume]
		];
		assets += "\tif new_audio:getChannels() == 1 then\n"
		for (var v = 0; v < mono_values.length; v++) {
			assets += "\t\tnew_audio:set"+mono_values[v][0]+"("+mono_values[v][1]+")\n";
		}
		assets += "\tend\n"+
				  "\treturn new_audio\n"+
				  "end\n\n";
	}

	// SPRITESHEET
	for (var e in objects['spritesheet']) {
		var spr = objects['spritesheet'][e];
		var img = b_library.getByUUID("image", spr.img_source);

		params = spr.parameters;

		assets += "function assets:"+spr.name+'()\n'+
				  "\tlocal img = assets:"+img.name+"()\n"+
				  "\treturn anim8.newGrid("+params.frameWidth+", "+params.frameHeight+", img:getWidth(), img:getHeight()), img\n"+
				  "end\n\n";
	}

	// CONF.LUA
	var conf = '';
	for (var cat in exports.settings) {
		for (var s = 0; s < exports.settings[cat].length; s++) {
			var setting = exports.settings[cat][s].name;
			var value = b_project.getSetting("engine", setting)
			var category = cat;

			if (!["includes", "blanke helpers"].includes(category)) {
				if (category === "misc") {
					category = "";
				} else {
					category += ".";
				}

				var input_type = exports.settings[cat][s].type;
				if (input_type === "text") {
					if (value !== "nil" || value == undefined) 
						value = "\""+value.addSlashes()+"\"";
				}
				if (input_type === "select") {
					value = "\""+value+"\"";
				}

				if (value != undefined)
					conf += "\tt."+category+setting.replace(' ','')+" = "+value+"\n";
			}
		}
		conf += "\n";
	}

	main_replacements = [
		['<STATE_INIT>', state_init]
	];

	conf_replacements = [
		["<CONF>", conf]
	];

	assets_replacements = [
		['<ASSETS>', assets]
	];

	includes_replacements = [
		['<INCLUDES>', script_includes],
		['<FIRST_STATE>', first_state]
	];

	nwHELPER.copyScript(nwPATH.join(__dirname, 'conf.lua'), nwPATH.join(build_path,'conf.lua'), conf_replacements);
	nwHELPER.copyScript(nwPATH.join(__dirname, 'assets.lua'), nwPATH.join(build_path,'assets.lua'), assets_replacements);
	nwHELPER.copyScript(nwPATH.join(__dirname, 'includes.lua'), nwPATH.join(build_path,'includes.lua'), includes_replacements);

	nwMKDIRP(nwPATH.join(build_path, 'assets'), function(){
		nwHELPER.copyScript(nwPATH.join(b_project.curr_project, "assets", "main.lua"), nwPATH.join(build_path,'main.lua'), main_replacements);

		// move game resources
		b_project.copyResources(nwPATH.join(build_path, 'assets'));
		nwFILEX.copy(nwPATH.join(__dirname, "plugins"), nwPATH.join(build_path, 'plugins'), function(err) {
			if (!err) {
				nwFILE.unlink(nwPATH.join(build_path, 'assets', 'main.lua'), function(err){
					// zip up .love (HEY: change line from folder to .love)
					// ...

					// remove removed plugins :P
					for (var p = 0; p < remove_plugins.length; p++) {
						nwFILEX.remove(nwPATH.join(build_path,'plugins',remove_plugins[p]));
					}
				
					building = false;
					if (callback)
						callback();
				});
			}
		});
	});
}

function buildLove(objects, callback) {
	var love_path = nwPATH.join(getBuildPath(), 'love', b_project.getSetting("engine", "title")+'.love');
	var path = nwPATH.join(getBuildPath(), 'temp');

	build(path, objects, function(){
		nwHELPER.zip(path, love_path, function(){
			// remove temp folder
			nwFILEX.removeSync(path);
			if (callback) 
				callback(love_path)
		});		
	});
}