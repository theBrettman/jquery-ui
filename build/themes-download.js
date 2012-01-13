#! /usr/bin/env node
// -*- js -*-

global.sys = require( /^v0\.[012]/.test( process.version ) ? "sys" : "util" );

// libraries
var exec = require( "child_process" ).exec,
	http = require( "http" ),
	fs = require( "fs" ),
	urls = fs.readFileSync( __dirname + "/themes", "utf-8" ).split( /[,\s]+/ ),
	arguments = [].slice.call( process.argv, 2 ),
	destDirectory = arguments.shift().replace( /\/?$/, "/" );

function downloadTheme( getParams ) {
	var theme = /t-name=([^&]+)/.exec( getParams )[1],
		filename = destDirectory + theme + ".zip",
		options = {
			host: "ui-dev.jquery.com",
			port: 80,
			path: "/download/?" + getParams
		};

	http.get( options, function( response ) {
		var file = fs.createWriteStream( filename );
		response.pipe( file );
		response.on( "end", function() {
			var unzipCommand = "unzip " + filename + " development-bundle/themes/** -x development-bundle/themes/base/* -d " + destDirectory + theme,
				finalDestination = fs.realpathSync( destDirectory + "../" + theme );
			console.log( "* Downloaded " + filename );
		});
	}).on( "error", function ( error ) {
		echo( "Error Downloading " + filename );
		process.exit( 1 );
	});
}

urls.forEach( downloadTheme );
