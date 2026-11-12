/**
 * IE Scanner Command
 * File: commands/iescanner.cfc
 */
component extends="commandbox.system.BaseCommand" {

	/* Cache properties for patterns */
	property name="cachedPatterns" type="array";
	property name="patternsLoaded" type="boolean" default="false";

	/**
	 * Run the IE Scanner
	 * @directory.hint  Directory to scan (defaults to current directory)
	 * @output.hint     Output file path
	 * @format.hint     Output format (csv, json, html)
	 * @help.hint       Show help information
	 * @verbose.hint    Show detailed progress
	 * @reloadPatterns.hint Force reload of patterns from JSON file
	 * @extensions.hint Comma-separated list of file extensions to scan (no dots)
	 * @patterns.hint   Absolute path to a custom patterns JSON file
	 * @severity.hint  Comma-separated severities to include (CRITICAL,HIGH,MEDIUM,LOW); default all
	 */
	function run(
		string  directory      = ".",
		string  output         = "",
		string  format         = "csv",
		boolean help           = false,
		boolean verbose        = false,
		boolean reloadPatterns = false,
		string  extensions     = "cfm,cfc,js,html,htm",
		string  patterns       = "",
		string  severity       = ""
	) {

		/* Clear pattern cache if requested */
		if ( arguments.reloadPatterns ) {
			clearPatternCache();
			print.line( "Pattern cache cleared. Patterns will be reloaded from JSON." );
		}

		/* Show help if requested */
		if ( arguments.help ) {
			print.line();
			print.line( "IE Legacy Code Scanner" );
			print.line( "======================" );
			print.line();
			print.line( "Usage:" );
			print.line( "  iescanner [directory=path] [format=csv|json|html] [output=file]" );
			print.line( "            [extensions=ext1,ext2] [patterns=/path/to/patterns.json]" );
			print.line();
			print.line( "Examples:" );
			print.line( "  iescanner" );
			print.line( "  iescanner directory=C:\myapp" );
			print.line( "  iescanner directory=C:\myapp format=html output=C:\reports\report.html" );
			print.line( "  iescanner directory=C:\myapp extensions=cfm,cfc,js,html,htm,pl" );
			print.line( "  iescanner directory=C:\myapp patterns=D:\config\solr-patterns.json" );
			print.line( "  iescanner reloadPatterns=true" );
			print.line();
			print.line( "Options:" );
			print.line( "  directory      - Directory to scan (default: current directory)" );
			print.line( "  format         - Output format: csv, json, or html (default: csv)" );
			print.line( "  output         - Output file path (default: ie-scan-[timestamp].[format])" );
			print.line( "  verbose        - Show each file as it is scanned (default: false)" );
			print.line( "  reloadPatterns - Force reload of patterns from JSON file (default: false)" );
			print.line( "  extensions     - File extensions to scan, no dots, comma-separated" );
			print.line( "                   (default: cfm,cfc,js,html,htm)" );
			print.line( "  patterns       - Absolute path to a custom patterns JSON file." );
			print.line( "                   When provided, bypasses the default config/patterns.json" );
			print.line( "                   search and the pattern cache." );
			print.line( "  severity       - Comma-separated severities to include:" );
			print.line( "                   CRITICAL,HIGH,MEDIUM,LOW (default: all)" );
			print.line();
			return;
		}

		/* Set default output filename if not provided */
		if ( !len( arguments.output ) ) {
			var timestamp = dateFormat( now(), "yyyymmdd" ) & timeFormat( now(), "HHmmss" );
			arguments.output = "ie-scan-#timestamp#.#arguments.format#";
		}

		/* Resolve directory path (handles ".", relative, and absolute paths) */
		if ( arguments.directory == "." ) {
			arguments.directory = getCWD();
		} else {
			arguments.directory = resolvePath( arguments.directory );
		}

		/* Validate directory exists */
		if ( !directoryExists( arguments.directory ) ) {
			print.line( "ERROR: Directory not found: #arguments.directory#" );
			print.line();
			print.line( "Please specify a valid directory:" );
			print.line( "  iescanner directory=C:\path\to\your\app" );
			print.line( "  iescanner directory=." );
			print.line();
			return;
		}

		/* Validate custom patterns file exists if one was provided */
		if ( len( trim( arguments.patterns ) ) && !fileExists( arguments.patterns ) ) {
			print.line( "ERROR: Patterns file not found: #arguments.patterns#" );
			print.line();
			print.line( "Please specify a valid path to a patterns JSON file:" );
			print.line( "  iescanner patterns=D:\config\solr-patterns.json" );
			print.line();
			return;
		}

		/* Build directoryList filter from extensions parameter */
		var filterList = "";
		for ( var ext in listToArray( arguments.extensions ) ) {
			filterList = listAppend( filterList, "*." & trim( ext ), "|" );
		}

		/* Start scanning */
		print.line();
		print.line( "+==========================================+" );
		print.line( "|   IE Legacy Code Scanner - v1.3.0       |" );
		print.line( "+==========================================+" );
		print.line();
		print.line( "Directory : #arguments.directory#" );
		print.line( "Output    : #arguments.output#" );
		print.line( "Format    : #arguments.format#" );
		print.line( "Extensions: #arguments.extensions#" );

		if ( len( trim( arguments.patterns ) ) ) {
			print.line( "Patterns  : #arguments.patterns#" );
		} else {
			print.line( "Patterns  : config/patterns.json (default)" );
		}

		if ( len( trim( arguments.severity ) ) ) {
			print.line( "Severity  : #arguments.severity# (filter)" );
		}

		print.line();

		/* Track start time for performance metrics */
		var startTime = getTickCount();

		/* Load patterns.
		   A custom path bypasses the cache so that multiple scans in the same
		   session can use different pattern files without interference. */
		var loadedPatterns = [];
		if ( len( trim( arguments.patterns ) ) ) {
			loadedPatterns = loadPatternsFromFile( arguments.patterns );
		} else {
			loadedPatterns = getPatterns();
		}

		/* Optional severity filter: keep only patterns whose severity was requested */
		if ( len( trim( arguments.severity ) ) ) {
			var allowedSeverities = {};
			for ( var sev in listToArray( arguments.severity ) ) {
				allowedSeverities[ uCase( trim( sev ) ) ] = true;
			}
			var severityFiltered = [];
			for ( var sp in loadedPatterns ) {
				if ( structKeyExists( allowedSeverities, uCase( sp.severity ) ) ) {
					severityFiltered.append( sp );
				}
			}
			loadedPatterns = severityFiltered;

			if ( loadedPatterns.len() == 0 ) {
				print.line( "ERROR: No patterns match severity filter: #arguments.severity#" );
				print.line( "Valid severities: CRITICAL, HIGH, MEDIUM, LOW" );
				return;
			}
		}

		var issues       = [];
		var filesScanned = 0;
		var filesWithIssues = 0;

		/* Get files to scan */
		print.line( "Searching for files..." );

		try {
			var files = directoryList(
				arguments.directory,
				true,
				"path",
				filterList
			);
		} catch ( any e ) {
			print.line( "Error listing files: #e.message#" );
			return;
		}

		print.line( "Found #files.len()# files to scan" );

		if ( files.len() == 0 ) {
			print.line( "No files found matching the criteria." );
			print.line( "Extensions searched: #arguments.extensions#" );
			return;
		}

		/* Initialize progress tracking */
		print.line();
		print.line( "Scanning files..." );
		var progressInterval = max( 1, int( files.len() / 50 ) );

		/* Scan each file */
		for ( var file in files ) {
			filesScanned++;

			if ( arguments.verbose ) {
				print.line( "[#filesScanned#/#files.len()#] #getFileFromPath( file )#" );
			} else {
				if ( filesScanned % progressInterval == 0 || filesScanned == files.len() ) {
					var percent = int( ( filesScanned / files.len() ) * 100 );
					print.text( "." ).toConsole();

					if ( percent % 20 == 0 && filesScanned % progressInterval == 0 ) {
						print.text( " #percent#% " ).toConsole();
					}
				}
			}

			/* Scan the file */
			var fileIssues = scanFile( file, loadedPatterns, arguments.directory );

			if ( fileIssues.len() > 0 ) {
				filesWithIssues++;
				issues.append( fileIssues, true );
			}
		}

		/* Complete progress display */
		if ( !arguments.verbose && files.len() > 0 ) {
			print.line( " 100%" );
		}

		print.line();

		/* Calculate scan time */
		var scanTime = ( getTickCount() - startTime ) / 1000;

		/* Generate output */
		try {
			generateOutput( issues, arguments.output, arguments.format );
			print.line( "Report saved: #arguments.output#" );
		} catch ( any e ) {
			print.line( "Error saving report: #e.message#" );
		}

		/* Show summary */
		print.line();
		print.line( "[SUCCESS] Scan Complete!" );
		print.line();
		print.line( "========================================" );
		print.line( "SUMMARY:" );
		print.line( "Files scanned    : #filesScanned#" );
		print.line( "Files with issues: #filesWithIssues#" );
		print.line( "Total issues     : #issues.len()#" );
		print.line( "Scan time        : #numberFormat( scanTime, '0.00' )# seconds" );
		print.line();

		/* Show severity breakdown if issues found */
		if ( issues.len() > 0 ) {
			var severityCount = countBySeverity( issues );
			print.line( "Issues by Severity:" );
			if ( severityCount.CRITICAL > 0 ) print.line( "  CRITICAL: #severityCount.CRITICAL#" );
			if ( severityCount.HIGH     > 0 ) print.line( "  HIGH    : #severityCount.HIGH#" );
			if ( severityCount.MEDIUM   > 0 ) print.line( "  MEDIUM  : #severityCount.MEDIUM#" );
			if ( severityCount.LOW      > 0 ) print.line( "  LOW     : #severityCount.LOW#" );

			/* Show sample issues if verbose */
			if ( arguments.verbose && issues.len() > 0 ) {
				print.line();
				print.line( "Sample Issues:" );
				var count = 0;
				for ( var issue in issues ) {
					if ( ++count > 5 ) break;
					print.line( "  * [#issue.severity#] #issue.file#:#issue.line# - #issue.description#" );
				}
				if ( issues.len() > 5 ) {
					print.line( "  ... and #issues.len() - 5# more issues" );
				}
			}
		} else {
			print.line( "[SUCCESS] No issues found!" );
		}

		print.line( "========================================" );
		print.line();
	}

	/**
	 * Get patterns using the default search path and cache.
	 * Used when no custom patterns path is provided.
	 */
	private array function getPatterns() {
		/* Return cached patterns if already loaded */
		if ( structKeyExists( variables, "patternsLoaded" ) && variables.patternsLoaded
				&& structKeyExists( variables, "cachedPatterns" ) ) {
			return variables.cachedPatterns;
		}

		try {
			/* Locate and load the default patterns.json */
			var patternFile = findDefaultPatternsFile();
			var patterns    = loadPatternsFromFile( patternFile );

			/* Cache for the session */
			variables.cachedPatterns = patterns;
			variables.patternsLoaded = true;

			return patterns;

		} catch ( any e ) {
			if ( structKeyExists( variables, "print" ) ) {
				print.line( "Warning: Could not load patterns from JSON: #e.message#" );
				print.line( "Using default patterns instead." );
			}
			return getDefaultPatterns();
		}
	}

	/**
	 * Locate the default patterns.json by searching known module paths.
	 * Returns the resolved file path or throws FileNotFoundException.
	 */
	private string function findDefaultPatternsFile() {
		var moduleRoot  = expandPath( "/commandbox-iescanner" );
		var patternFile = moduleRoot & "/config/patterns.json";

		if ( !fileExists( patternFile ) ) {
			patternFile = expandPath( "../config/patterns.json" );
		}

		if ( !fileExists( patternFile ) ) {
			patternFile = expandPath( "./modules/commandbox-iescanner/config/patterns.json" );
		}

		if ( !fileExists( patternFile ) ) {
			var cbPath = expandPath( "~/.CommandBox/cfml/modules/commandbox-iescanner/config/patterns.json" );
			if ( fileExists( cbPath ) ) {
				patternFile = cbPath;
			}
		}

		if ( !fileExists( patternFile ) ) {
			throw(
				type    = "FileNotFoundException",
				message = "patterns.json file not found",
				detail  = "Searched paths: #moduleRoot#/config/patterns.json and alternatives"
			);
		}

		return patternFile;
	}

	/**
	 * Load and process patterns from a JSON file at the given absolute path.
	 * Used for both the default patterns.json and any custom patterns file.
	 */
	private array function loadPatternsFromFile( required string filePath ) {
		if ( !fileExists( arguments.filePath ) ) {
			throw(
				type    = "FileNotFoundException",
				message = "Patterns file not found: #arguments.filePath#"
			);
		}

		var jsonContent    = fileRead( arguments.filePath );
		var patternsData   = deserializeJSON( jsonContent );
		var processedPatterns = [];

		for ( var pattern in patternsData ) {
			var processedPattern = {};
			processedPattern["severity"]       = structKeyExists( pattern, "severity" )       ? pattern.severity       : "MEDIUM";
			processedPattern["description"]    = structKeyExists( pattern, "description" )    ? pattern.description    : "";
			processedPattern["recommendation"] = structKeyExists( pattern, "recommendation" ) ? pattern.recommendation : "";

			/* Handle pattern string - convert < to chr(60) to avoid CF parsing issues */
			if ( structKeyExists( pattern, "pattern" ) ) {
				var patternString = pattern.pattern;
				if ( find( "<", patternString ) ) {
					patternString = replace( patternString, "<", chr( 60 ), "all" );
				}
				processedPattern["pattern"] = patternString;
			}

			/* Skip entries missing a valid pattern string */
			if ( !structKeyExists( processedPattern, "pattern" ) || !len( processedPattern.pattern ) ) {
				continue;
			}

			processedPatterns.append( processedPattern );
		}

		if ( arrayLen( processedPatterns ) == 0 ) {
			throw(
				type    = "InvalidPatternException",
				message = "No valid patterns found in file: #arguments.filePath#",
				detail  = "The file exists but contains no entries with a valid 'pattern' field."
			);
		}

		return processedPatterns;
	}

	/**
	 * Hardcoded fallback patterns used when no patterns.json can be located.
	 * Using string concatenation to avoid false positives when scanning this file.
	 */
	private array function getDefaultPatterns() {
		return [
			{
				pattern:        "docu" & "ment\.all",
				severity:       "HIGH",
				description:    "IE-specific docu" & "ment.all",
				recommendation: "Use document.getElementById() or querySelector()"
			},
			{
				pattern:        "attach" & "Event",
				severity:       "HIGH",
				description:    "IE-specific attach" & "Event",
				recommendation: "Use addEventListener()"
			},
			{
				pattern:        "ActiveX" & "Object",
				severity:       "CRITICAL",
				description:    "ActiveX object usage",
				recommendation: "Remove ActiveX dependencies"
			},
			{
				pattern:        chr( 60 ) & "cfform",
				severity:       "HIGH",
				description:    "CFFORM tag",
				recommendation: "Replace with HTML form"
			},
			{
				pattern:        chr( 60 ) & "cfgrid",
				severity:       "HIGH",
				description:    "CFGRID tag",
				recommendation: "Replace with modern grid library"
			},
			{
				pattern:        "XDomain" & "Request",
				severity:       "HIGH",
				description:    "IE-specific XDomain" & "Request for CORS",
				recommendation: "Use XMLHttpRequest with proper CORS headers or fetch API"
			}
		];
	}

	/**
	 * Scan a single file for pattern matches, returning an array of issue structs.
	 */
	private array function scanFile( required string filePath, required array patterns, required string baseDir ) {
		var issues = [];

		try {
			var content      = fileRead( arguments.filePath );
			var lines        = listToArray( content, chr( 10 ) );

			/* Build a relative path for reporting */
			var relativePath = replace( arguments.filePath, arguments.baseDir, "" );
			if ( left( relativePath, 1 ) == "\" || left( relativePath, 1 ) == "/" ) {
				relativePath = mid( relativePath, 2, len( relativePath ) );
			}

			var lineNum = 0;
			for ( var line in lines ) {
				lineNum++;

				for ( var pattern in arguments.patterns ) {
					try {
						if ( !structKeyExists( pattern, "pattern" ) || !len( pattern.pattern ) ) {
							continue;
						}

						if ( reFindNoCase( pattern.pattern, line ) ) {
							issues.append({
								file:           relativePath,
								line:           lineNum,
								severity:       structKeyExists( pattern, "severity" )       ? pattern.severity       : "MEDIUM",
								description:    structKeyExists( pattern, "description" )    ? pattern.description    : "Detected pattern",
								recommendation: structKeyExists( pattern, "recommendation" ) ? pattern.recommendation : "Review and update"
							});
						}
					} catch ( any patternError ) {
						/* Skip invalid regex patterns and continue scanning */
					}
				}
			}
		} catch ( any e ) {
			/* Skip unreadable files and continue scanning */
		}

		return issues;
	}

	/**
	 * Generate the output report file in the requested format.
	 */
	private void function generateOutput( required array issues, required string outputPath, required string format ) {
		switch ( arguments.format ) {
			case "json":
				var data = {
					scanDate:    dateTimeFormat( now(), "yyyy-mm-dd HH:nn:ss" ),
					totalIssues: arguments.issues.len(),
					issues:      arguments.issues
				};
				fileWrite( arguments.outputPath, serializeJSON( data ) );
				break;

			case "html":
				var html = generateHTMLReport( arguments.issues );
				fileWrite( arguments.outputPath, html );
				break;

			default: /* csv */
				var csv = [ "File,Line,Severity,Description,Recommendation" ];
				for ( var issue in arguments.issues ) {
					var row = [];
					row.append( '"' & replace( issue.file,           '"', '""', "all" ) & '"' );
					row.append( issue.line );
					row.append( issue.severity );
					row.append( '"' & replace( issue.description,    '"', '""', "all" ) & '"' );
					row.append( '"' & replace( issue.recommendation, '"', '""', "all" ) & '"' );
					csv.append( row.toList( "," ) );
				}
				fileWrite( arguments.outputPath, csv.toList( chr( 10 ) ) );
		}
	}

	/**
	 * Generate an HTML report string.
	 */
	private string function generateHTMLReport( required array issues ) {
		var html         = [];
		var severityCount = countBySeverity( arguments.issues );

		html.append( '<!DOCTYPE html>' );
		html.append( '<html>' );
		html.append( '<head>' );
		html.append( '<title>IE Legacy Code Scan Report</title>' );
		html.append( '<style>' );
		html.append( 'body { font-family: Arial, sans-serif; margin: 20px; background: ##f5f5f5; }' );
		html.append( '.container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }' );
		html.append( 'h1 { color: ##333333; border-bottom: 3px solid ##4CAF50; padding-bottom: 10px; }' );
		html.append( '.summary { background: ##f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid ##4CAF50; }' );
		html.append( '.stat-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }' );
		html.append( '.stat-card { background: ##f9f9f9; padding: 15px; border-radius: 5px; text-align: center; }' );
		html.append( '.stat-card h3 { margin: 0 0 10px 0; color: ##666; font-size: 14px; }' );
		html.append( '.stat-card .value { font-size: 24px; font-weight: bold; }' );
		html.append( 'table { width: 100%; border-collapse: collapse; margin-top: 20px; }' );
		html.append( 'th { background: ##4CAF50; color: white; padding: 12px; text-align: left; }' );
		html.append( 'td { padding: 10px; border-bottom: 1px solid ##dddddd; }' );
		html.append( 'tr:hover { background: ##f5f5f5; }' );
		html.append( '.critical { color: ##ff0000; font-weight: bold; }' );
		html.append( '.high { color: ##ff8800; font-weight: bold; }' );
		html.append( '.medium { color: ##ffaa00; }' );
		html.append( '.low { color: ##666666; }' );
		html.append( '</style>' );
		html.append( '</head>' );
		html.append( '<body>' );
		html.append( '<div class="container">' );
		html.append( '<h1>IE Legacy Code Scan Report</h1>' );

		html.append( '<div class="summary">' );
		html.append( '<h2 style="margin-top: 0;">Scan Summary</h2>' );
		html.append( '<p><strong>Scan Date:</strong> #dateTimeFormat( now(), "yyyy-mm-dd HH:nn:ss" )#</p>' );
		html.append( '<p><strong>Total Issues Found:</strong> #arguments.issues.len()#</p>' );
		html.append( '</div>' );

		html.append( '<div class="stat-cards">' );
		if ( severityCount.CRITICAL > 0 ) {
			html.append( '<div class="stat-card"><h3>Critical Issues</h3><div class="value critical">#severityCount.CRITICAL#</div></div>' );
		}
		if ( severityCount.HIGH > 0 ) {
			html.append( '<div class="stat-card"><h3>High Priority</h3><div class="value high">#severityCount.HIGH#</div></div>' );
		}
		if ( severityCount.MEDIUM > 0 ) {
			html.append( '<div class="stat-card"><h3>Medium Priority</h3><div class="value medium">#severityCount.MEDIUM#</div></div>' );
		}
		if ( severityCount.LOW > 0 ) {
			html.append( '<div class="stat-card"><h3>Low Priority</h3><div class="value low">#severityCount.LOW#</div></div>' );
		}
		html.append( '</div>' );

		if ( arguments.issues.len() > 0 ) {
			html.append( '<h2>Issues Detail</h2>' );
			html.append( '<table><thead><tr>' );
			html.append( '<th>File</th><th>Line</th><th>Severity</th><th>Description</th><th>Recommendation</th>' );
			html.append( '</tr></thead><tbody>' );

			for ( var issue in arguments.issues ) {
				html.append( '<tr>' );
				html.append( '<td>#encodeForHTML( issue.file )#</td>' );
				html.append( '<td>#issue.line#</td>' );
				html.append( '<td class="#lcase( issue.severity )#">#issue.severity#</td>' );
				html.append( '<td>#encodeForHTML( issue.description )#</td>' );
				html.append( '<td>#encodeForHTML( issue.recommendation )#</td>' );
				html.append( '</tr>' );
			}

			html.append( '</tbody></table>' );
		} else {
			html.append( '<div style="text-align: center; padding: 40px; background: ##e8f5e9; border-radius: 5px; margin: 20px 0;">' );
			html.append( '<h2 style="color: ##4CAF50;">No Issues Found!</h2>' );
			html.append( '<p>Your code appears to be free of the scanned patterns.</p>' );
			html.append( '</div>' );
		}

		html.append( '</div>' );
		html.append( '</body>' );
		html.append( '</html>' );

		return html.toList( "" );
	}

	/**
	 * Count issues grouped by severity level.
	 */
	private struct function countBySeverity( required array issues ) {
		var count = { "CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0 };
		for ( var issue in arguments.issues ) {
			if ( structKeyExists( count, issue.severity ) ) {
				count[ issue.severity ]++;
			}
		}
		return count;
	}

	/**
	 * Clear the pattern cache, forcing a reload on the next scan.
	 */
	public void function clearPatternCache() {
		variables.patternsLoaded = false;
		variables.cachedPatterns = [];
	}

}
