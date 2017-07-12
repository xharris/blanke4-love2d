var nwHELPER = nwPLUGINS['build_helper'];

var new_dirname = __dirname; // nwHELPER.nonASAR(__dirname)

exports.modules = ['image', 'spritesheet', 'entity', 'state', 'scene', 'audio', 'script'];

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
exports.entity_template = nwPATH.join(new_dirname, 'entity_template.lua');
exports.state_template = nwPATH.join(new_dirname, 'state_template.lua');
exports.language = 'lua';
exports.file_ext = 'lua';

function getBuildPath() {
	return nwPATH.join(b_project.curr_project, 'BUILDS');
}

exports.targets = {
	"source" : {
		build: function(objects) {
			b_console.log('build: source');

			last_object_set = objects;
			var path = nwPATH.join(getBuildPath(), 'source');
			build(path, objects, function(){
				eSHELL.openItem(path);
			});
		}
	},

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

						var cmd = '';
						switch(nwOS.type()) {
							case "Windows_NT":
								// combine love.exe and .love
								// Ex. copy /b love.exe+SuperGame.love SuperGame.exe
								cmd = 'copy /b \"'+nwPATH.join(getLoveFolder('win'), "love.exe")+'\"+\"'+path+'\" \"'+build_path+'\"';

							break;

							case "Darwin":
								  // Ex. cat love.exe SuperGame.love > SuperGame.exe
								  cmd = 'cat \"'+nwPATH.join(getLoveFolder('win'), "love.exe")+'\" \"'+path+'\" > \"'+build_path+'\"';
							break;
						}

						if (cmd !== '') {
							nwCHILD.exec(cmd);	
							// copy required dlls
							var other_files = ["love.dll", "lua51.dll", "mpg123.dll", "SDL2.dll"];
							for (var o = 0; o < other_files.length; o++) {
								var file = other_files[o];
								nwFILEX.copy(nwPATH.join(getLoveFolder('win'), file), nwPATH.join(nwPATH.dirname(build_path), file));
							}
							
							eSHELL.openItem(nwPATH.dirname(build_path));
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
					nwFILEX.copy(nwPATH.join(getLoveFolder('mac')), build_path, function(){
						// create .love and copy it into app/Contents/Resources/
						buildLove(objects, function(path){
							nwFILEX.copy(path, nwPATH.join(build_path, 'Contents', 'Resources', b_project.getSetting("engine", "title")+'.love'), function(err){
								if (err) return;
								
								//

								// modify app/Contents/Info.plist			
								var plist_repl = [
									['org.love2d.love', 'com.BlankE.'+b_project.getSetting("engine", "title")],
									['LÖVE Project', 'BlankE project'],
									['LÖVE>', b_project.getSetting("engine", "title")]
								];
								plist_path = nwPATH.join(build_path, 'Contents', 'Info.plist');
								console.log('edit:'+plist_path);
								nwHELPER.copyScript(plist_path, plist_path, plist_repl);

								eSHELL.openItem(nwPATH.dirname(build_path));
							});
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
				console.log('to ' + zip_path);
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
		'' : nwPATH.join(new_dirname, "bin"),
		'win' : nwPATH.join(new_dirname, "bin"),
		'mac' : nwPATH.join(new_dirname, "bin", "love-"+version+"-macosx-x64")
	}
	return paths[os];
}

function getLoveFolder(os='', version=b_project.getSetting("engine", "version")) {
	var paths = {
		'' : nwPATH.join(new_dirname, "bin"),
		'win' : nwPATH.join(new_dirname, "bin", "love-"+version+"-win32"),
		'mac' : nwPATH.join(new_dirname, "bin", "love-"+version+"-macosx-x64", "love.app")
	}
	return paths[os];
}

// only works for windows atm
function runLove(love_path, show_cmd) {
    show_cmd = ifndef(show_cmd, b_project.getSetting("engine","console"));
    
    var os = nwOS.type();
    if (os === "Windows_NT") os = 'win';
    if (os === "Darwin") os = 'mac';

	downloadLove(os, function(){
		var cmd = '';

		// run on WINDOWS
		if (os === 'win') {
			if (show_cmd) 
				cmd = 'start cmd.exe /K \"\"'+nwPATH.join(getLoveFolder('win'), "love.exe")+'\" \"'+love_path+'\"\"';
			else 
				cmd = '\"'+nwPATH.join(getLoveFolder('win'), "love.exe")+'\" \"'+love_path+'\"';
		}

		// run on MAC
		if (os === 'mac') {
			if (show_cmd)
				cmd = "echo \""+nwPATH.join(getLoveFolder('mac'),"Contents","MacOS","love")+"\" \""+love_path+"\" > runlove.command; chmod +x runlove.command; open runlove.command"
			else
				cmd = '\"'+nwPATH.join(getLoveFolder('mac'),"Contents","MacOS","love")+'\" \"'+love_path+'\"';
		}

        var run_count = b_project.getSetting("engine", "instance count");
        for (var r = 0; r < run_count; r++)
            nwCHILD.exec(cmd);
	});
}

exports.run = function(objects) {
	last_object_set = objects;
	var path = nwPATH.join(getBuildPath(), 'source');
	build(path, objects, function(){
		runLove(path);
	});
} 

exports.settings = {
    "general" : [
        {"type" : "number", "name" : "instance count", "default" : 1, "min" : 1, "max" :  1000000, "tooltip": "Number of instances of the game to run"},
		{"type" : "bool", "name" : "Compress Scenes", "default" : "false", "tooltip": "Compress map data files created by Scene object"}
	],
	"includes" : [
		{"type" : "bool", "name" : "printr", "default" : "false", "tooltip": "Print tables using print_r", "include": 'require "plugins.printr"'},
		{"type" : "bool", "name" : "luasocket", "default" : "false", "tooltip": "helper for http requests", "include": 'require "plugins.luasocket"'}
	],/*
	"blanke helpers" : [
		{"type" : "bool", "name" : "pause on lose focus", "default" : "true", "tooltip": "pause the game if the user minimizes the window or switches to a different window"}
	],*/
	"misc" : [
		{"type" : "text", "name" : "identity", "default" : "-", "tooltip": "The name of the save directory"},
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

function copyMain() {
    if (b_project.getData("engine") !== "love2d") return;
    // copy main.lua template to project folder
    nwFILE.stat(nwPATH.join(b_project.curr_project, "assets", "main.lua"), function(err, stat){
        if (err || !stat.isFile()) {
            console.log("copying ", nwPATH.join(new_dirname, 'main.lua'))
            var html_code = nwFILEX.copy(
                nwPATH.join(new_dirname, 'main.lua'),
                nwPATH.join(b_project.curr_project, "assets", "main.lua")
            );
        }
    });
}

exports.loaded = function() {
    document.addEventListener("project.new", function(e){
        copyMain();
    });
    
	document.addEventListener("project.open", function(e){
		copyMain();
        
        // change identity value (setting)
        if (b_project.getSetting("engine", "identity") == "nil")
            b_project.setSetting("engine",  "identity", nwPATH.basename(b_project.bip_path));
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
    
    var arr_types = ["entity", "state"];
    
	var state_init = '';
	var first_state = ''; 
    // ALL OBJECT SCRIPT INCLUDES
    for (var t = 0; t < arr_types.length; t++) {
        var type = arr_types[t];
        for (var o in objects[type]) {
            var obj = objects[type][o];
            
            if (type === "state" && first_state === "") {
                first_state = obj.name;
                script_includes += obj.name+" = {}\n";
            }
            
            if (type === "entity") {
            	script_includes += obj.name + " = Class{__includes=Entity,__tostring = function(self) return \'"+obj.name+"\' end,classname=\'"+obj.name+"\'}\n"
            }

            if (obj.code_path.length > 1) {
                obj.code_path = nwPATH.join(type, obj.name + '_' + o + '.lua');
                script_includes += "require \"assets/scripts/"+obj.code_path.replace(/\\/g,"/").replace('.lua','')+"\"\n";
            }

            
        }
    }
           
    // ALL OBJECTS ARRAY
    var obj_array = "";
    for (var t = 0; t < arr_types.length; t++) {
        var type = arr_types[t];
        obj_array += "game." + type + " = {";
        for (var o in objects[type]) {
            var obj = objects[type][o];
            obj_array += obj.name + ", ";
        }
        obj_array = obj_array.slice(0, -2);
        obj_array += "}\n";
    }
    
	var assets = '';

	// SCRIPTS
	for (var e in objects['script']) {
		var script = objects['script'][e];

		if (script.code_path.length > 1) {
			script.code_path = nwPATH.join('script', script.name + '_' + e + '.lua');
			assets += "function assets:"+script.name+"()\n"+
					  "\treturn 'assets/scripts/"+script.code_path.replace(/\\/g,"/")+"'\n"+
					  "end\n\n";
		}		
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

        if (img) { // was sprite assigned an image?
            params = spr.parameters;

            assets += "function assets:"+spr.name+'()\n'+
                      "\tlocal img = assets:"+img.name+"()\n"+
                      "\treturn anim8.newGrid("+params.frameWidth+", "+params.frameHeight+", img:getWidth(), img:getHeight()), img\n"+
                      "end\n\n";
        }
	}

	// SCENE
	for (var s in objects['scene']) {
		var scene = objects['scene'][s];
		var scene_data = JSON.stringify(getModuleFn("scene", "convertMapToScene")(s));

		nwMKDIRP(nwPATH.join(build_path, 'assets', 'scene'), function(){
			nwFILE.writeFile(nwPATH.join(build_path, 'assets', 'scene', scene.name+'.json'), scene_data, (err) => {
			  if (err) throw err;
			});
		});

		assets += "function assets:"+scene.name+'()\n'+
				  "\treturn \"assets/scene/"+scene.name+".json\"\n"+
				  "end\n\n";
	}

	// CONF.LUA
	var conf = '';
	for (var cat in exports.settings) {
		for (var s = 0; s < exports.settings[cat].length; s++) {
			var setting = exports.settings[cat][s].name;
			var value = b_project.getSetting("engine", setting)
			var category = cat;

			if (!["includes", "blanke helpers", "general"].includes(category)) {
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
        ['<OBJ_ARRAY>', obj_array],
		['<INCLUDES>', script_includes],
		['<FIRST_STATE>', first_state],
        ['<GAME_NAME>', b_project.getSetting("engine", "title")]
	];

	nwHELPER.copyScript(nwPATH.join(new_dirname, 'conf.lua'), nwPATH.join(build_path,'conf.lua'), conf_replacements);
	nwHELPER.copyScript(nwPATH.join(new_dirname, 'assets.lua'), nwPATH.join(build_path,'assets.lua'), assets_replacements);
	nwHELPER.copyScript(nwPATH.join(new_dirname, 'includes.lua'), nwPATH.join(build_path,'includes.lua'), includes_replacements);

	nwMKDIRP(nwPATH.join(build_path, 'assets'), function(){
		nwHELPER.copyScript(nwPATH.join(b_project.curr_project, "assets", "main.lua"), nwPATH.join(build_path,'main.lua'), main_replacements);

		// move game resources
		b_project.copyResources(nwPATH.join(build_path, 'assets'));
		nwFILEX.copy(nwPATH.join(new_dirname, "plugins"), nwPATH.join(build_path, 'plugins'), function(err) {
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