var Module = {
  preRun: [],
  postRun: [],
  print: (function() {
    var body;
    return function(text) {
      if (!body) {
        body = document.getElementsByTagName('body').item(0);
      }
      if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
      // These replacements are necessary if you render to raw HTML
      text = text.replace(/&/g, "&amp;");
      text = text.replace(/</g, "&lt;");
      text = text.replace(/>/g, "&gt;");
      text = text.replace('\n', '<br>', 'g');
      //console.log(text);
      body.insertAdjacentHTML('beforeend', text + '<br>');
      body.scrollTop = body.scrollHeight; // focus on bottom
    };
  })(),
  printErr: function(text) {
    if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
    console.error(text);
  },
  canvas: (function() {
    var canvas = null; //document.getElementById('canvas');
    return canvas;
  })(),

  setStatus: function(text) {
    if (!Module.setStatus.last) Module.setStatus.last = { time: Date.now(), text: '' };
    if (text === Module.setStatus.text) return;
    var m = text.match(/([^(]+)\((\d+(\.\d+)?)\/(\d+)\)/);
    var now = Date.now();
    if (m && now - Date.now() < 30) return; // if this is a progress update, skip it if too soon
    if (m) {
      text = m[1];
    }
    console.log(text);
  },

  totalDependencies: 0,
  monitorRunDependencies: function(left) {
    this.totalDependencies = Math.max(this.totalDependencies, left);
    Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
  }
};
Module.setStatus('Downloading...');
window.onerror = function(event) {
  // TODO: do not warn on ok events like simulating an infinite loop or exitStatus
  Module.setStatus('Exception thrown, see JavaScript console');
  Module.setStatus = function(text) {
    if (text) Module.printErr('[post-exception status] ' + text);
  };
};


var loadBinary = function(url, onload, onerror) {
  var xhr = new XMLHttpRequest;
  xhr.open("GET", url, true);
  xhr.responseType = "arraybuffer";
  xhr.onload = function xhr_onload() {
    if (xhr.status == 200 || xhr.status == 0 && xhr.response) {
      onload(xhr.response);
    } else if (onerror) {
      onerror();
    } else {
      throw 'Loading data file "' + url + '" failed.';
    }
  };
  xhr.onerror = onerror;
  xhr.send(null);
}

//var Module;
//if (!Module) Module = (typeof Module !== 'undefined' ? Module : null) || {};
var onload = function(runtime, buffer) {
  Module["asm"] = function(global, env, memory) {
    //env["f64-to-int"] = function(f) { return f | 0; } // for asm2wasm of binaryen
    env["getSTACKTOP"] = function getSTACKTOP() { return STACKTOP; };
    env["getSTACK_MAX"] = function getSTACK_MAX() { return STACK_MAX; }
    env["getTempDoublePtr"] = function getTempDoublePtr() { return tempDoublePtr; }
    env["getABORT"] = function getABORT() { return ABORT; }
    env["getCttz_i8"] = function getCttz_i8() { return cttz_i8; }
    return WASM.instantiateModule(buffer, env, memory);
  }
  setTimeout(function() {
    var script = document.createElement('script');
    script.src = runtime;
    document.body.appendChild(script);
  }, 1);
}
