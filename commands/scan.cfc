/**
 * Scan subcommand
 * box iescanner scan
 */
component extends="commandbox.system.BaseCommand" {
    
    property name="progressBar" inject="progressBar@shell";
    property name="moduleSettings" inject="coldbox:modulesettings:commandbox-iescanner";
    
    /**
     * @directory.hint Directory to scan
     * @output.hint Output file path
     * @format.hint Output format (csv, json, html)
     * @extensions.hint File extensions to scan
     * @recursive.hint Scan subdirectories
     * @verbose.hint Show detailed output
     */
    function run(
        string directory = getCWD(),
        string output = "ie-scan.csv",
        string format = "csv",
        string extensions = "",
        boolean recursive = true,
        boolean verbose = false
    ) {
        
        // Use default extensions if not provided
        if (!len(arguments.extensions)) {
            arguments.extensions = moduleSettings.defaultExtensions;
        }
        
        arguments.directory = resolvePath(arguments.directory);
        
        if (!directoryExists(arguments.directory)) {
            return error("Directory not found: #arguments.directory#");
        }
        
        print.line();
        print.boldCyanLine("╔══════════════════════════════════════════╗");
        print.boldCyanLine("║      IE Legacy Code Scanner v1.0.0      ║");
        print.boldCyanLine("╚══════════════════════════════════════════╝");
        print.line();
        print.yellowLine("Scanning directory: #arguments.directory#");
        print.line("Output format: #arguments.format#");
        print.line("File extensions: #arguments.extensions#");
        print.line("Recursive: #arguments.recursive#");
        print.line();
        
        var startTime = getTickCount();
        var patterns = moduleSettings.patterns;
        var issues = [];
        var stats = {
            filesScanned: 0,
            filesWithIssues: 0,
            severityCount: {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0},
            categoryCount: {}
        };
        
        // Get files to scan
        var files = directoryList(
            arguments.directory,
            arguments.recursive,
            "path",
            function(path) {
                // Check extension
                var ext = listLast(path, ".");
                if (!listFindNoCase(arguments.extensions, ext)) {
                    return false;
                }
                // Check exclude patterns
                for (var exclude in moduleSettings.excludePatterns) {
                    if (path contains exclude) {
                        return false;
                    }
                }
                return true;
            }
        );
        
        print.line("Found #files.len()# files to scan");
        print.line();
        
        // Progress bar
        if (!arguments.verbose && files.len() > 0) {
            progressBar.start("Scanning: ", files.len());
        }
        
        // Scan each file
        for (var file in files) {
            stats.filesScanned++;
            
            if (arguments.verbose) {
                print.line("Scanning: #getFileFromPath(file)#");
            } else if (files.len() > 0) {
                progressBar.update(stats.filesScanned);
            }
            
            var fileIssues = scanFile(file, patterns, arguments.directory);
            if (fileIssues.len() > 0) {
                stats.filesWithIssues++;
                issues.append(fileIssues, true);
                
                // Update stats
                for (var issue in fileIssues) {
                    if (structKeyExists(stats.severityCount, issue.severity)) {
                        stats.severityCount[issue.severity]++;
                    }
                    if (!structKeyExists(stats.categoryCount, issue.category)) {
                        stats.categoryCount[issue.category] = 0;
                    }
                    stats.categoryCount[issue.category]++;
                }
            }
        }
        
        if (!arguments.verbose && files.len() > 0) {
            progressBar.finish();
        }
        
        var scanTime = (getTickCount() - startTime) / 1000;
        
        // Generate output
        switch(arguments.format) {
            case "json":
                generateJSON(issues, stats, arguments.output);
                break;
            case "html":
                generateHTML(issues, stats, arguments.output);
                break;
            default:
                generateCSV(issues, arguments.output);
        }
        
        // Display summary
        print.line();
        print.boldGreenLine("✓ Scan Complete!");
        print.line();
        print.yellowLine("═══════════════════════════════════════════");
        print.boldWhiteLine("SUMMARY:");
        print.line("Files scanned: #stats.filesScanned#");
        print.line("Files with issues: #stats.filesWithIssues#");
        print.line("Total issues found: #issues.len()#");
        print.line();
        
        if (stats.severityCount.CRITICAL > 0) {
            print.boldRedLine("  CRITICAL: #stats.severityCount.CRITICAL# issues");
        }
        if (stats.severityCount.HIGH > 0) {
            print.redLine("  HIGH: #stats.severityCount.HIGH# issues");
        }
        if (stats.severityCount.MEDIUM > 0) {
            print.yellowLine("  MEDIUM: #stats.severityCount.MEDIUM# issues");
        }
        if (stats.severityCount.LOW > 0) {
            print.line("  LOW: #stats.severityCount.LOW# issues");
        }
        
        print.yellowLine("═══════════════════════════════════════════");
        print.line("Scan time: #numberFormat(scanTime, '0.00')# seconds");
        print.line("Report saved to: #arguments.output#");
        print.line();
        
        // Show sample issues if verbose
        if (arguments.verbose && issues.len() > 0) {
            print.yellowLine("Sample Issues:");
            var count = 0;
            for (var issue in issues) {
                if (++count > 5) break;
                print.line("  • [#issue.severity#] #issue.file#:#issue.line# - #issue.description#");
            }
            if (issues.len() > 5) {
                print.line("  ... and #issues.len() - 5# more issues");
            }
            print.line();
        }
    }
    
    private array function scanFile(filePath, patterns, baseDir) {
        var issues = [];
        
        try {
            var content = fileRead(arguments.filePath);
            var lines = listToArray(content, chr(10));
            var relativePath = replace(arguments.filePath, arguments.baseDir, "");
            if (left(relativePath, 1) == "\" || left(relativePath, 1) == "/") {
                relativePath = mid(relativePath, 2, len(relativePath));
            }
            
            var lineNum = 0;
            for (var line in lines) {
                lineNum++;
                for (var pattern in arguments.patterns) {
                    if (reFindNoCase(pattern.pattern, line)) {
                        issues.append({
                            file: relativePath,
                            line: lineNum,
                            category: pattern.category,
                            severity: pattern.severity,
                            description: pattern.description,
                            recommendation: pattern.recommendation,
                            code: left(trim(line), 100)
                        });
                    }
                }
            }
        } catch (any e) {
            // Skip files that can't be read
        }
        
        return issues;
    }
    
    private void function generateCSV(issues, outputPath) {
        var csv = ["File,Line,Category,Severity,Issue,Recommendation"];
        
        for (var issue in arguments.issues) {
            csv.append(
                '"#replace(issue.file, '"', '""', 'all')#",' &
                '#issue.line#,' &
                '"#issue.category#",' &
                '#issue.severity#,' &
                '"#issue.description#",' &
                '"#issue.recommendation#"'
            );
        }
        
        fileWrite(arguments.outputPath, csv.toList(chr(10)));
    }
    
    private void function generateJSON(issues, stats, outputPath) {
        var data = {
            scanDate: now(),
            stats: arguments.stats,
            issues: arguments.issues
        };
        fileWrite(arguments.outputPath, serializeJSON(data));
    }
    
    private void function generateHTML(issues, stats, outputPath) {
        var html = '<!DOCTYPE html>
<html>
<head>
    <title>IE Legacy Code Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: ##f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: ##333; border-bottom: 3px solid ##4CAF50; padding-bottom: 10px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat-card { background: ##f9f9f9; padding: 15px; border-radius: 5px; border-left: 4px solid ##4CAF50; }
        .stat-card h3 { margin: 0 0 10px 0; color: ##666; font-size: 14px; }
        .stat-card .value { font-size: 24px; font-weight: bold; color: ##333; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: ##4CAF50; color: white; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid ##ddd; }
        tr:hover { background: ##f5f5f5; }
        .critical { background: ##ffebee; color: ##c62828; font-weight: bold; }
        .high { background: ##fff3e0; color: ##e65100; }
        .medium { background: ##fffde7; color: ##f57f17; }
        .low { background: ##f1f8e9; color: ##558b2f; }
        .code { font-family: monospace; font-size: 12px; background: ##f5f5f5; padding: 2px 4px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>IE Legacy Code Scan Report</h1>
        <div class="summary">
            <div class="stat-card">
                <h3>Files Scanned</h3>
                <div class="value">' & arguments.stats.filesScanned & '</div>
            </div>
            <div class="stat-card">
                <h3>Total Issues</h3>
                <div class="value">' & arguments.issues.len() & '</div>
            </div>
            <div class="stat-card">
                <h3>Critical Issues</h3>
                <div class="value" style="color: ##c62828;">' & arguments.stats.severityCount.CRITICAL & '</div>
            </div>
            <div class="stat-card">
                <h3>High Priority</h3>
                <div class="value" style="color: ##e65100;">' & arguments.stats.severityCount.HIGH & '</div>
            </div>
        </div>
        
        <h2>Issues Detail</h2>
        <table>
            <thead>
                <tr>
                    <th>File</th>
                    <th>Line</th>
                    <th>Category</th>
                    <th>Severity</th>
                    <th>Issue</th>
                    <th>Recommendation</th>
                </tr>
            </thead>
            <tbody>';
        
        for (var issue in arguments.issues) {
            html &= '
                <tr>
                    <td>' & issue.file & '</td>
                    <td>' & issue.line & '</td>
                    <td>' & issue.category & '</td>
                    <td class="' & lcase(issue.severity) & '">' & issue.severity & '</td>
                    <td>' & issue.description & '</td>
                    <td>' & issue.recommendation & '</td>
                </tr>';
        }
        
        html &= '
            </tbody>
        </table>
    </div>
</body>
</html>';
        
        fileWrite(arguments.outputPath, html);
    }
}
