/**
 * IE Scanner Module Configuration
 * Based on working CommandBox module structure
 */
component {

	this.title          = "CommandBox IE Scanner";
	this.author         = "George Murphy";
	this.version        = "1.0.0";
	this.cfmapping      = "commandbox-iescanner";
	this.modelNamespace = "commandbox-iescanner";
	this.entryPoint     = "iescanner";

	function configure(){
		settings = {};
		interceptors = [];
	}

	function onLoad(){
		// Module loaded successfully
	}

	function onUnLoad(){
		// Module unloaded successfully
	}

}