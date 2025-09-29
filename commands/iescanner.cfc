/**
 * IE Scanner Command
 * File: commands/iescanner.cfc
 */
component extends="commandbox.system.BaseCommand" {
	
	/**
	 * Run the IE Scanner
	 * @directory.hint Directory to scan (defaults to current directory)
	 * @output.hint Output file path
	 * @format.hint Output format (csv, json, html)
	 * @help.hint Show help information
	 * @verbose.hint Show detailed progress
	 */
	function run(
		string directory = ".",
		string output = "",
		string format = "csv",
		boolean help = false,
		boolean verbose = false
	) {
		
		// Show help if requested
		if (arguments.help) {
			print.line();
			print.boldCyanLine("IE Legacy Code Scanner");
			print.line("======================");
			print.line();
			print.yellowLine("Usage:");
			print.line("  box iescanner [directory=path] [output=file] [format=csv|json|html]");
			print.line();
			print.yellowLine("Examples:");
			print.line("  box iescanner                              ## Scan current directory");
			print.line("  box iescanner directory=C:\myapp           ## Scan specific directory");
			print.line("  box iescanner directory=.                  ## Scan current directory explicitly");
			print.line("  box iescanner format=html output=report.html");
			print.line();
			print.yellowLine("Options:");
			print.line("  directory - Directory to scan (default: current directory)");
			print.line("  output    - Output file name (default: ie-scan-[timestamp].[format])");
			print.line("  format    - Output format: csv, json, or html (default: csv)");
			print.line("  verbose   - Show detailed progress (default: false)");
			print.line();
			return;
		}
		
		// Set default output filename if not provided
		if (!len(arguments.output)) {
			var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
			arguments.output = "ie-scan-#timestamp#.#arguments.format#";
		}
		
		// Resolve directory path (handles ".", relative, and absolute paths)
		if (arguments.directory == ".") {
			arguments.directory = getCWD();
		} else {
			arguments.directory = resolvePath(arguments.directory);
		}
		
		// Validate directory exists
		if (!directoryExists(arguments.directory)) {
			print.redLine("ERROR: Directory not found: #arguments.directory#");
			print.line();
			print.yellowLine("Please specify a valid directory:");
			print.line("  box iescanner directory=C:\path\to\your\app");
			print.line("  box iescanner directory=.");
			print.line();
			return;
		}
		
		// Start scanning
		print.line();
		print.boldGreenLine("IE Legacy Code Scanner");
		print.line("======================");
		print.line("Directory: #arguments.directory#");
		print.line("Output: #arguments.output#");
		print.line("Format: #arguments.format#");
		print.line();
		
		// Define patterns to search for
		var patterns = getPatterns();
		var issues = [];
		var filesScanned = 0;
		
		// Get files to scan
		print.line("Searching for files...");
		
		try {
			var files = directoryList(
				arguments.directory,
				true,
				"path",
				"*.cfm|*.cfc|*.js|*.html|*.htm"
			);
		} catch (any e) {
			print.redLine("Error listing files: #e.message#");
			return;
		}
		
		print.line("Found #files.len()# files to scan");
		
		if (files.len() == 0) {
			print.yellowLine("No files found matching the criteria.");
			print.line("Make sure the directory contains .cfm, .cfc, .js, .html, or .htm files.");
			return;
		}
		
		// Scan each file
		print.line();
		print.line("Scanning files...");
		
		for (var file in files) {
			filesScanned++;
			
			if (arguments.verbose) {
				print.line("[#filesScanned#/#files.len()#] #getFileFromPath(file)#");
			} else if (filesScanned % 10 == 0) {
				print.text(".");
			}
			
			// Scan the file
			var fileIssues = scanFile(file, patterns, arguments.directory);
			issues.append(fileIssues, true);
		}
		
		if (!arguments.verbose && files.len() > 0) {
			print.line();
		}
		
		print.line();
		
		// Generate output
		try {
			generateOutput(issues, arguments.output, arguments.format);
			print.greenLine("Report saved: #arguments.output#");
		} catch (any e) {
			print.redLine("Error saving report: #e.message#");
		}
		
		// Show summary
		print.line();
		print.boldGreenLine("==== SCAN COMPLETE ====");
		print.line("Files scanned: #filesScanned#");
		print.line("Issues found: #issues.len()#");
		print.line();
		
		// Show severity breakdown if issues found
		if (issues.len() > 0) {
			var severityCount = countBySeverity(issues);
			print.yellowLine("Issues by Severity:");
			if (severityCount.CRITICAL > 0) print.redLine("  CRITICAL: #severityCount.CRITICAL#");
			if (severityCount.HIGH > 0) print.yellowLine("  HIGH: #severityCount.HIGH#");
			if (severityCount.MEDIUM > 0) print.line("  MEDIUM: #severityCount.MEDIUM#");
			if (severityCount.LOW > 0) print.line("  LOW: #severityCount.LOW#");
		} else {
			print.greenLine("✓ No IE-specific issues found!");
		}
		
		print.line();
	}
	
	/**
	 * Get patterns to search for
	 */
	private array function getPatterns() {
		return [
		{
				pattern: "document\.all",
				severity: "HIGH",
				description: "IE-specific document.all",
				recommendation: "Use document.getElementById() or querySelector()"
			},
			{
				pattern: "attachEvent",
				severity: "HIGH",
				description: "IE-specific attachEvent",
				recommendation: "Use addEventListener()"
			},
			{
				pattern: "detachEvent",
				severity: "HIGH",
				description: "IE-specific detachEvent",
				recommendation: "Use removeEventListener()"
			},
			{
				pattern: "ActiveXObject",
				severity: "CRITICAL",
				description: "ActiveX object usage",
				recommendation: "Remove ActiveX dependencies"
			},
			{
				pattern: "XDomainRequest",
				severity: "HIGH",
				description: "IE-specific XDomainRequest for CORS",
				recommendation: "Use XMLHttpRequest with proper CORS headers or fetch API"
			},
			{
				pattern: "VBArray",
				severity: "HIGH",
				description: "IE-specific VBArray object",
				recommendation: "Use standard JavaScript arrays"
			},
			{
				pattern: "\.doScroll\s*\(",
				severity: "MEDIUM",
				description: "IE-specific doScroll method",
				recommendation: "Use standard DOM ready detection or DOMContentLoaded event"
			},
			{
				pattern: "createPopup\s*\(",
				severity: "HIGH",
				description: "IE-specific createPopup method",
				recommendation: "Use modern modal/popup libraries or window.open()"
			},
			{
				pattern: "execScript\s*\(",
				severity: "HIGH",
				description: "IE-specific execScript method",
				recommendation: "Use eval() or Function constructor (with security considerations)"
			},
			{
				pattern: chr(60) & "cfform",
				severity: "HIGH",
				description: "CFFORM tag",
				recommendation: "Replace with HTML form"
			},
			{
				pattern: chr(60) & "cfinput",
				severity: "HIGH",
				description: "CFINPUT tag",
				recommendation: "Replace with HTML5 input"
			},
			{
				pattern: chr(60) & "cfselect",
				severity: "HIGH",
				description: "CFSELECT tag",
				recommendation: "Replace with HTML select"
			},
			{
				pattern: chr(60) & "cfgrid",
				severity: "HIGH",
				description: "CFGRID tag",
				recommendation: "Replace with modern grid library"
			},
			{
				pattern: chr(60) & "cftree",
				severity: "HIGH",
				description: "CFTREE tag",
				recommendation: "Replace with jsTree or similar"
			},
			{
				pattern: chr(60) & "cflayout",
				severity: "HIGH",
				description: "CFLAYOUT tag",
				recommendation: "Use CSS Grid or Flexbox"
			},
			{
				pattern: chr(60) & "cfwindow",
				severity: "HIGH",
				description: "CFWINDOW tag",
				recommendation: "Use modal library"
			},
			{
				pattern: chr(60) & "cfajaxproxy",
				severity: "HIGH",
				description: "CFAJAXPROXY tag",
				recommendation: "Use fetch API"
			},
			{
				pattern: "ColdFusion\.Ajax",
				severity: "HIGH",
				description: "ColdFusion Ajax functions",
				recommendation: "Replace with modern JavaScript"
			},
			{
				pattern: chr(60) & "!--\[if\s+IE",
				severity: "MEDIUM",
				description: "IE conditional comments",
				recommendation: "Remove or use feature detection"
			},
			{
				pattern: "window\.event(?!\s*=)",
				severity: "HIGH",
				description: "IE-specific window.event",
				recommendation: "Pass event as parameter to handlers"
			},
			{
				pattern: "event\.returnValue",
				severity: "MEDIUM",
				description: "IE-specific event.returnValue",
				recommendation: "Use event.preventDefault()"
			},
			{
				pattern: "event\.cancelBubble",
				severity: "MEDIUM",
				description: "IE-specific event.cancelBubble",
				recommendation: "Use event.stopPropagation()"
			},
			{
				pattern: chr(60) & "cfmenu",
				severity: "HIGH",
				description: "CFMENU tag",
				recommendation: "Use CSS/JavaScript menu"
			},
			{
				pattern: chr(60) & "cftooltip",
				severity: "MEDIUM",
				description: "CFTOOLTIP tag",
				recommendation: "Use CSS tooltips or tooltip library"
			},
			{
				pattern: "filter\s*:\s*alpha",
				severity: "MEDIUM",
				description: "IE-specific CSS alpha filter",
				recommendation: "Use CSS3 opacity property"
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
			
			// Make relative path
			var relativePath = replace(arguments.filePath, arguments.baseDir, "");
			if (left(relativePath, 1) == "\" || left(relativePath, 1) == "/") {
				relativePath = mid(relativePath, 2, len(relativePath));
			}
			
			var lineNum = 0;
			for (var line in lines) {
				lineNum++;
				
				for (var pattern in arguments.patterns) {
					try {
						if (reFindNoCase(pattern.pattern, line)) {
							issues.append({
								file: relativePath,
								line: lineNum,
								severity: pattern.severity,
								description: pattern.description,
								recommendation: pattern.recommendation
							});
						}
					} catch (any e) {
						// Skip invalid patterns
					}
				}
			}
		} catch (any e) {
			// Skip files that cannot be read
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
				
			default: // csv
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
		
		html.append('<!DOCTYPE html>');
		html.append('<html>');
		html.append('<head>');
		html.append('<title>IE Legacy Code Scan Report</title>');
		html.append('<style>');
		html.append('body { font-family: Arial, sans-serif; margin: 20px; background: ##f5f5f5; }');
		html.append('.container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }');
		html.append('h1 { color: ##333333; border-bottom: 3px solid ##4CAF50; padding-bottom: 10px; }');
		html.append('.summary { background: ##f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid ##4CAF50; }');
		html.append('table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
		html.append('th { background: ##4CAF50; color: white; padding: 12px; text-align: left; }');
		html.append('td { padding: 10px; border-bottom: 1px solid ##dddddd; }');
		html.append('tr:hover { background: ##f5f5f5; }');
		html.append('.critical { color: ##ff0000; font-weight: bold; }');
		html.append('.high { color: ##ff8800; font-weight: bold; }');
		html.append('.medium { color: ##ffaa00; }');
		html.append('.low { color: ##666666; }');
		html.append('.stats { display: flex; justify-content: space-around; margin: 20px 0; }');
		html.append('.stat-card { text-align: center; padding: 15px; background: ##f9f9f9; border-radius: 5px; flex: 1; margin: 0 10px; }');
		html.append('.stat-number { font-size: 2em; font-weight: bold; color: ##4CAF50; }');
		html.append('.stat-label { color: ##666; margin-top: 5px; }');
		html.append('</style>');
		html.append('</head>');
		html.append('<body>');
		html.append('<div class="container">');
		html.append('<h1>IE Legacy Code Scan Report</h1>');
		
		// Summary section
		html.append('<div class="summary">');
		html.append('<h2 style="margin-top: 0;">Scan Summary</h2>');
		html.append('<p><strong>Scan Date:</strong> #dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")#</p>');
		html.append('<p><strong>Total Issues Found:</strong> #arguments.issues.len()#</p>');
		
		// Count by severity
		var severityCount = countBySeverity(arguments.issues);
		if (severityCount.CRITICAL > 0) {
			html.append('<p><span class="critical">CRITICAL Issues: #severityCount.CRITICAL#</span></p>');
		}
		if (severityCount.HIGH > 0) {
			html.append('<p><span class="high">HIGH Priority Issues: #severityCount.HIGH#</span></p>');
		}
		if (severityCount.MEDIUM > 0) {
			html.append('<p><span class="medium">MEDIUM Priority Issues: #severityCount.MEDIUM#</span></p>');
		}
		if (severityCount.LOW > 0) {
			html.append('<p><span class="low">LOW Priority Issues: #severityCount.LOW#</span></p>');
		}
		html.append('</div>');
		
		// Issues table
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
			html.append('<h2 style="color: ##4CAF50;">✓ No IE-Specific Issues Found!</h2>');
			html.append('<p>Your code appears to be free of IE-specific patterns.</p>');
			html.append('</div>');
		}
		
		html.append('</div>'); // Close container
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
}