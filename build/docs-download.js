#! /usr/bin/env node
// -*- js -*-

global.sys = require( /^v0\.[012]/.test( process.version ) ? "sys" : "util" );

// libraries
var http = require( "http" ),
	fs = require( "fs" ),

// configuration
	apiDocs = "Draggable Droppable Resizable Selectable Sortable Accordion Autocomplete Button Datepicker Dialog Menu Progressbar Slider Spinner Tooltip Tabs Position".split( " " ),
	effectsCoreDocs = "animate addClass effect hide removeClass show switchClass toggle toggleClass".split( " " ),
	effectsDocs = "Blind Bounce Clip Drop Explode Fade Fold Highlight Puff Pulsate Scale Shake Size Slide Transfer".split( " " ),

// command line	
	arguments = [].slice.call( process.argv, 2 ),
	docsDirectory = arguments.shift().replace( /\/?$/, "/" ),
	version = arguments.shift();

function downloadDocs( url, filename ) {
	var options = {
			host: "docs.jquery.com",
			port: 80,
			path: "/action/render/UI/" + url
		};

	http.get( options, function( response ) {
		var file = fs.createWriteStream( filename );
		response.pipe( file );
		response.on( "end", function() {
			console.log( "* Downloaded " + options.path + " to " + filename );
		});
	}).on( "error", function ( error ) {
		echo( "Error Downloading " + options.path );
		process.exit( 1 );
	});
}

apiDocs.forEach( function( api ) {
	downloadDocs( "API/" + version + "/" + api, docsDirectory + api.toLowerCase() + ".html" );
});
effectsCoreDocs.forEach( function( fn ) {
	downloadDocs( "Effects/" + fn, docsDirectory + fn + ".html" );
});
effectsDocs.forEach( function( effect ) {
	downloadDocs( "Effects/" + effect, docsDirectory + "effect-" + effect.toLowerCase() + ".html" );
});