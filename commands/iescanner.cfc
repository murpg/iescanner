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
	 * @directory.hint Directory to scan (defaults to current directory)
	 * @output.hint Output file path
	 * @format.hint Output format (csv, json, html)
	 * @help.hint Show help information
	 * @verbose.hint Show detailed progress
	 * @reloadPatterns.hint Force reload of patterns from JSON file
	 */
	function run(
		string directory = ".",
		string output = "",
		string format = "csv",
		boolean help = false,
		boolean verbose = false,
		boolean reloadPatterns = false
	) {
		
		/* Clear pattern cache if requested */
		if (arguments.reloadPatterns) {
			clearPatternCache();
			print.line("Pattern cache cleared. Patterns will be reloaded from JSON.");
		}
		
		/* Show help if requested */
		if (arguments.help) {
			print.line();
			print.line("IE Legacy Code Scanner");
			print.line("======================");
			print.line();
			print.line("Usage:");
			print.line("  box iescanner [directory=path] [output=file] [format=csv|json|html]");
			print.line();
			print.line("Examples:");
			print.line("  box iescanner                              ## Scan current directory");
			print.line("  box iescanner directory=C:\myapp           ## Scan specific directory");
			print.line("  box iescanner directory=.                  ## Scan current directory explicitly");
			print.line("  box iescanner format=html output=report.html");
			print.line("  box iescanner reloadPatterns=true          ## Force reload patterns from JSON");
			print.line();
			print.line("Options:");
			print.line("  directory      - Directory to scan (default: current directory)");
			print.line("  output         - Output file name (default: ie-scan-[timestamp].[format])");
			print.line("  format         - Output format: csv, json, or html (default: csv)");
			print.line("  verbose        - Show detailed progress (default: false)");
			print.line("  reloadPatterns - Force reload patterns from JSON file (default: false)");
			print.line();
			return;
		}
		
		/* Set default output filename if not provided */
		if (!len(arguments.output)) {
			var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
			arguments.output = "ie-scan-#timestamp#.#arguments.format#";
		}
		
		/* Resolve directory path (handles ".", relative, and absolute paths) */
		if (arguments.directory == ".") {
			arguments.directory = getCWD();
		} else {
			arguments.directory = resolvePath(arguments.directory);
		}
		
		/* Validate directory exists */
		if (!directoryExists(arguments.directory)) {
			print.line("ERROR: Directory not found: #arguments.directory#");
			print.line();
			print.line("Please specify a valid directory:");
			print.line("  box iescanner directory=C:\path\to\your\app");
			print.line("  box iescanner directory=.");
			print.line();
			return;
		}
		
		/* Start scanning */
		print.line();
		print.line("+==========================================+");
		print.line("|   IE Legacy Code Scanner - v1.0.0       |");
		print.line("+==========================================+");
		print.line();
		print.line("Directory: #arguments.directory#");
		print.line("Output: #arguments.output#");
		print.line("Format: #arguments.format#");
		print.line();
		
		/* Track start time for performance metrics */
		var startTime = getTickCount();
		
		/* Get patterns - this will now load from JSON */
		var patterns = getPatterns();
		var issues = [];
		var filesScanned = 0;
		var filesWithIssues = 0;
		
		/* Get files to scan */
		print.line("Searching for files...");
		
		try {
			var files = directoryList(
				arguments.directory,
				true,
				"path",
				"*.cfm|*.cfc|*.js|*.html|*.htm"
			);
		} catch (any e) {
			print.line("Error listing files: #e.message#");
			return;
		}
		
		print.line("Found #files.len()# files to scan");
		
		if (files.len() == 0) {
			print.line("No files found matching the criteria.");
			print.line("Make sure the directory contains .cfm, .cfc, .js, .html, or .htm files.");
			return;
		}
		
		/* Initialize progress tracking */
		print.line();
		print.line("Scanning files...");
		var progressInterval = max(1, int(files.len() / 50)); // Show up to 50 progress markers
		
		/* Scan each file */
		for (var file in files) {
			filesScanned++;
			
			if (arguments.verbose) {
				print.line("[#filesScanned#/#files.len()#] #getFileFromPath(file)#");
			} else {
				// Show progress dots at intervals
				if (filesScanned % progressInterval == 0 || filesScanned == files.len()) {
					var percent = int((filesScanned / files.len()) * 100);
					print.text(".").toConsole();
					
					// Show percentage every 20%
					if (percent % 20 == 0 && filesScanned % progressInterval == 0) {
						print.text(" #percent#% ").toConsole();
					}
				}
			}
			
			/* Scan the file */
			var fileIssues = scanFile(file, patterns, arguments.directory);
			
			if (fileIssues.len() > 0) {
				filesWithIssues++;
				issues.append(fileIssues, true);
			}
		}
		
		/* Complete progress display */
		if (!arguments.verbose && files.len() > 0) {
			print.line(" 100%");
		}
		
		print.line();
		
		/* Calculate scan time */
		var scanTime = (getTickCount() - startTime) / 1000;
		
		/* Generate output */
		try {
			generateOutput(issues, arguments.output, arguments.format);
			print.line("Report saved: #arguments.output#");
		} catch (any e) {
			print.line("Error saving report: #e.message#");
		}
		
		/* Show summary */
		print.line();
		print.line("[SUCCESS] Scan Complete!");
		print.line();
		print.line("========================================");
		print.line("SUMMARY:");
		print.line("Files scanned: #filesScanned#");
		print.line("Files with issues: #filesWithIssues#");
		print.line("Total issues found: #issues.len()#");
		print.line("Scan time: #numberFormat(scanTime, '0.00')# seconds");
		print.line();
		
		/* Show severity breakdown if issues found */
		if (issues.len() > 0) {
			var severityCount = countBySeverity(issues);
			print.line("Issues by Severity:");
			if (severityCount.CRITICAL > 0) print.line("  CRITICAL: #severityCount.CRITICAL#");
			if (severityCount.HIGH > 0) print.line("  HIGH: #severityCount.HIGH#");
			if (severityCount.MEDIUM > 0) print.line("  MEDIUM: #severityCount.MEDIUM#");
			if (severityCount.LOW > 0) print.line("  LOW: #severityCount.LOW#");
			
			/* Show sample issues if verbose */
			if (arguments.verbose && issues.len() > 0) {
				print.line();
				print.line("Sample Issues:");
				var count = 0;
				for (var issue in issues) {
					if (++count > 5) break;
					print.line("  * [#issue.severity#] #issue.file#:#issue.line# - #issue.description#");
				}
				if (issues.len() > 5) {
					print.line("  ... and #issues.len() - 5# more issues");
				}
			}
		} else {
			print.line("[SUCCESS] No IE-specific issues found!");
		}
		
		print.line("========================================");
		print.line();
	}
	
	/**
	 * Get patterns to search for - Now loads from JSON file
	 */
	private array function getPatterns() {
		/* Return cached patterns if already loaded */
		if (structKeyExists(variables, "patternsLoaded") && variables.patternsLoaded && structKeyExists(variables, "cachedPatterns")) {
			return variables.cachedPatterns;
		}
		
		try {
			/* Try to load from JSON file */
			var patterns = loadPatternsFromJSON();
			
			/* Cache the patterns */
			variables.cachedPatterns = patterns;
			variables.patternsLoaded = true;
			
			return patterns;
			
		} catch (any e) {
			/* Log error if available */
			if (structKeyExists(variables, "print")) {
				print.line("Warning: Could not load patterns from JSON: #e.message#");
				print.line("Using default patterns instead.");
			}
			
			/* Fall back to default patterns */
			return getDefaultPatterns();
		}
	}
	
	/**
	 * Load patterns from the JSON configuration file
	 */
	private array function loadPatternsFromJSON() {
		/* Build path to patterns.json */
		var moduleRoot = expandPath("/commandbox-iescanner");
		var patternFile = moduleRoot & "/config/patterns.json";
		
		/* Alternative paths to try if the first doesn't work */
		if (!fileExists(patternFile)) {
			/* Try relative to the command file */
			patternFile = expandPath("../config/patterns.json");
		}
		
		if (!fileExists(patternFile)) {
			/* Try relative to current directory */
			patternFile = expandPath("./modules/commandbox-iescanner/config/patterns.json");
		}
		
		if (!fileExists(patternFile)) {
			/* Try CommandBox modules path */
			var cbPath = expandPath("~/.CommandBox/cfml/modules/commandbox-iescanner/config/patterns.json");
			if (fileExists(cbPath)) {
				patternFile = cbPath;
			}
		}
		
		/* If still not found, throw error */
		if (!fileExists(patternFile)) {
			throw(
				type = "FileNotFoundException",
				message = "patterns.json file not found",
				detail = "Searched paths: #moduleRoot#/config/patterns.json and alternatives"
			);
		}
		
		/* Read and parse JSON file */
		var jsonContent = fileRead(patternFile);
		var patternsData = deserializeJSON(jsonContent);
		
		/* Process patterns to convert special characters */
		var processedPatterns = [];
		
		for (var pattern in patternsData) {
			/* Create new pattern object with processed values */
			var processedPattern = {};
			processedPattern["severity"] = structKeyExists(pattern, "severity") ? pattern.severity : "MEDIUM";
			processedPattern["description"] = structKeyExists(pattern, "description") ? pattern.description : "";
			processedPattern["recommendation"] = structKeyExists(pattern, "recommendation") ? pattern.recommendation : "";
			
			/* Handle pattern string - convert < to chr(60) */
			if (structKeyExists(pattern, "pattern")) {
				var patternString = pattern.pattern;
				
				/* Check if pattern contains < character */
				if (find("<", patternString)) {
					/* Replace all < with chr(60) */
					patternString = replace(patternString, "<", chr(60), "all");
				}
				
				processedPattern["pattern"] = patternString;
			}
			
			/* Validate pattern has required fields */
			if (!structKeyExists(processedPattern, "pattern") || !len(processedPattern.pattern)) {
				continue; /* Skip invalid patterns */
			}
			
			processedPatterns.append(processedPattern);
		}
		
		/* Validate we have at least some patterns */
		if (arrayLen(processedPatterns) == 0) {
			throw(
				type = "InvalidPatternException",
				message = "No valid patterns found in JSON file",
				detail = "The patterns.json file exists but contains no valid patterns"
			);
		}
		
		return processedPatterns;
	}
	
	/**
	 * Get default patterns as fallback
	 */
	private array function getDefaultPatterns() {
		/* Minimal set of critical patterns as fallback */
		/* Using string concatenation to avoid false positives when scanning this file */
		return [
			{
				pattern: "docu" & "ment\.all",
				severity: "HIGH",
				description: "IE-specific docu" & "ment.all",
				recommendation: "Use document.getElementById() or querySelector()"
			},
			{
				pattern: "attach" & "Event",
				severity: "HIGH",
				description: "IE-specific attach" & "Event",
				recommendation: "Use addEventListener()"
			},
			{
				pattern: "ActiveX" & "Object",
				severity: "CRITICAL",
				description: "ActiveX object usage",
				recommendation: "Remove ActiveX dependencies"
			},
			{
				pattern: chr(60) & "cfform",
				severity: "HIGH",
				description: "CFFORM tag",
				recommendation: "Replace with HTML form"
			},
			{
				pattern: chr(60) & "cfgrid",
				severity: "HIGH",
				description: "CFGRID tag",
				recommendation: "Replace with modern grid library"
			},
			{
				pattern: "XDomain" & "Request",
				severity: "HIGH",
				description: "IE-specific XDomain" & "Request for CORS",
				recommendation: "Use XMLHttpRequest with proper CORS headers or fetch API"
			}
		];
	}
	
	/**
	 * Scan a file for issues
	 */
	private array function scanFile(required string filePath, required array patterns, required string baseDir) {
		var issues = [];
		
		try {
			var content = fileRead(arguments.filePath);
			var lines = listToArray(content, chr(10));
			
			/* Make relative path */
			var relativePath = replace(arguments.filePath, arguments.baseDir, "");
			if (left(relativePath, 1) == "\" || left(relativePath, 1) == "/") {
				relativePath = mid(relativePath, 2, len(relativePath));
			}
			
			var lineNum = 0;
			for (var line in lines) {
				lineNum++;
				
				for (var pattern in arguments.patterns) {
					try {
						/* Ensure pattern has valid regex */
						if (!structKeyExists(pattern, "pattern") || !len(pattern.pattern)) {
							continue;
						}
						
						if (reFindNoCase(pattern.pattern, line)) {
							issues.append({
								file: relativePath,
								line: lineNum,
								severity: structKeyExists(pattern, "severity") ? pattern.severity : "MEDIUM",
								description: structKeyExists(pattern, "description") ? pattern.description : "Detected pattern",
								recommendation: structKeyExists(pattern, "recommendation") ? pattern.recommendation : "Review and update"
							});
						}
					} catch (any patternError) {
						/* Skip invalid regex patterns but continue scanning */
					}
				}
			}
		} catch (any e) {
			/* Skip files that cannot be read but don't stop the scan */
		}
		
		return issues;
	}
	
	/**
	 * Generate output file
	 */
	private void function generateOutput(required array issues, required string outputPath, required string format) {
		switch(arguments.format) {
			case "json":
				var data = {
					scanDate: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
					totalIssues: arguments.issues.len(),
					issues: arguments.issues
				};
				fileWrite(arguments.outputPath, serializeJSON(data));
				break;
				
			case "html":
				var html = generateHTMLReport(arguments.issues);
				fileWrite(arguments.outputPath, html);
				break;
				
			default: /* csv */
				var csv = ["File,Line,Severity,Description,Recommendation"];
				for (var issue in arguments.issues) {
					var row = [];
					row.append('"' & replace(issue.file, '"', '""', "all") & '"');
					row.append(issue.line);
					row.append(issue.severity);
					row.append('"' & replace(issue.description, '"', '""', "all") & '"');
					row.append('"' & replace(issue.recommendation, '"', '""', "all") & '"');
					csv.append(row.toList(","));
				}
				fileWrite(arguments.outputPath, csv.toList(chr(10)));
		}
	}
	
	/**
	 * Generate HTML report
	 */
	private string function generateHTMLReport(required array issues) {
		var html = [];
		
		/* Count by severity first for summary */
		var severityCount = countBySeverity(arguments.issues);
		
		html.append('<!DOCTYPE html>');
		html.append('<html>');
		html.append('<head>');
		html.append('<title>IE Legacy Code Scan Report</title>');
		html.append('<style>');
		html.append('body { font-family: Arial, sans-serif; margin: 20px; background: ##f5f5f5; }');
		html.append('.container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }');
		html.append('h1 { color: ##333333; border-bottom: 3px solid ##4CAF50; padding-bottom: 10px; }');
		html.append('.summary { background: ##f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid ##4CAF50; }');
		html.append('.stat-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }');
		html.append('.stat-card { background: ##f9f9f9; padding: 15px; border-radius: 5px; text-align: center; }');
		html.append('.stat-card h3 { margin: 0 0 10px 0; color: ##666; font-size: 14px; }');
		html.append('.stat-card .value { font-size: 24px; font-weight: bold; }');
		html.append('table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
		html.append('th { background: ##4CAF50; color: white; padding: 12px; text-align: left; }');
		html.append('td { padding: 10px; border-bottom: 1px solid ##dddddd; }');
		html.append('tr:hover { background: ##f5f5f5; }');
		html.append('.critical { color: ##ff0000; font-weight: bold; }');
		html.append('.high { color: ##ff8800; font-weight: bold; }');
		html.append('.medium { color: ##ffaa00; }');
		html.append('.low { color: ##666666; }');
		html.append('</style>');
		html.append('</head>');
		html.append('<body>');
		html.append('<div class="container">');
		html.append('<h1>IE Legacy Code Scan Report</h1>');
		
		/* Summary section */
		html.append('<div class="summary">');
		html.append('<h2 style="margin-top: 0;">Scan Summary</h2>');
		html.append('<p><strong>Scan Date:</strong> #dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")#</p>');
		html.append('<p><strong>Total Issues Found:</strong> #arguments.issues.len()#</p>');
		html.append('</div>');
		
		/* Stat cards */
		html.append('<div class="stat-cards">');
		if (severityCount.CRITICAL > 0) {
			html.append('<div class="stat-card">');
			html.append('<h3>Critical Issues</h3>');
			html.append('<div class="value critical">#severityCount.CRITICAL#</div>');
			html.append('</div>');
		}
		if (severityCount.HIGH > 0) {
			html.append('<div class="stat-card">');
			html.append('<h3>High Priority</h3>');
			html.append('<div class="value high">#severityCount.HIGH#</div>');
			html.append('</div>');
		}
		if (severityCount.MEDIUM > 0) {
			html.append('<div class="stat-card">');
			html.append('<h3>Medium Priority</h3>');
			html.append('<div class="value medium">#severityCount.MEDIUM#</div>');
			html.append('</div>');
		}
		if (severityCount.LOW > 0) {
			html.append('<div class="stat-card">');
			html.append('<h3>Low Priority</h3>');
			html.append('<div class="value low">#severityCount.LOW#</div>');
			html.append('</div>');
		}
		html.append('</div>');
		
		/* Issues table */
		if (arguments.issues.len() > 0) {
			html.append('<h2>Issues Detail</h2>');
			html.append('<table>');
			html.append('<thead>');
			html.append('<tr>');
			html.append('<th>File</th>');
			html.append('<th>Line</th>');
			html.append('<th>Severity</th>');
			html.append('<th>Description</th>');
			html.append('<th>Recommendation</th>');
			html.append('</tr>');
			html.append('</thead>');
			html.append('<tbody>');
			
			for (var issue in arguments.issues) {
				html.append('<tr>');
				html.append('<td>#htmlEditFormat(issue.file)#</td>');
				html.append('<td>#issue.line#</td>');
				html.append('<td class="#lcase(issue.severity)#">#issue.severity#</td>');
				html.append('<td>#htmlEditFormat(issue.description)#</td>');
				html.append('<td>#htmlEditFormat(issue.recommendation)#</td>');
				html.append('</tr>');
			}
			
			html.append('</tbody>');
			html.append('</table>');
		} else {
			html.append('<div style="text-align: center; padding: 40px; background: ##e8f5e9; border-radius: 5px; margin: 20px 0;">');
			html.append('<h2 style="color: ##4CAF50;">✔ No IE-Specific Issues Found!</h2>');
			html.append('<p>Your code appears to be free of IE-specific patterns.</p>');
			html.append('</div>');
		}
		
		html.append('</div>'); /* Close container */
		html.append('</body>');
		html.append('</html>');
		
		return html.toList("");
	}
	
	/**
	 * Count issues by severity
	 */
	private struct function countBySeverity(required array issues) {
		var count = {
			"CRITICAL": 0,
			"HIGH": 0,
			"MEDIUM": 0,
			"LOW": 0
		};
		
		for (var issue in arguments.issues) {
			if (structKeyExists(count, issue.severity)) {
				count[issue.severity]++;
			}
		}
		
		return count;
	}
	
	/**
	 * Clear pattern cache
	 */
	public void function clearPatternCache() {
		variables.patternsLoaded = false;
		variables.cachedPatterns = [];
	}
}