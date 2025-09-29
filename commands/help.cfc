/**
 * Help subcommand
 * box iescanner help
 */
component extends="commandbox.system.BaseCommand" {
    
    function run() {
        print.line();
        print.boldCyanLine("╔══════════════════════════════════════════╗");
        print.boldCyanLine("║   IE Legacy Code Scanner - Help Guide   ║");
        print.boldCyanLine("╚══════════════════════════════════════════╝");
        print.line();
        
        print.yellowLine("DESCRIPTION:");
        print.indentedLine("Scans ColdFusion applications for Internet Explorer");
        print.indentedLine("specific code patterns and generates reports.");
        print.line();
        
        print.yellowLine("USAGE:");
        print.indentedLine("box iescanner [options]");
        print.indentedLine("box iescanner scan [options]");
        print.indentedLine("box iescanner help");
        print.line();
        
        print.yellowLine("OPTIONS:");
        print.indentedLine("directory    - Directory to scan (default: current)");
        print.indentedLine("output       - Output file path");
        print.indentedLine("format       - Output format: csv, json, html (default: csv)");
        print.indentedLine("extensions   - File extensions to scan");
        print.indentedLine("recursive    - Scan subdirectories (default: true)");
        print.indentedLine("verbose      - Show detailed progress");
        print.line();
        
        print.yellowLine("EXAMPLES:");
        print.indentedLine("box iescanner");
        print.indentedLine("box iescanner directory=""C:\myapp""");
        print.indentedLine("box iescanner scan format=html output=report.html");
        print.indentedLine("box iescanner scan directory=""."" verbose=true");
        print.line();
        
        print.yellowLine("PATTERNS DETECTED:");
        print.indentedLine("• document.all (JavaScript)");
        print.indentedLine("• attachEvent/detachEvent (JavaScript)");
        print.indentedLine("• ActiveXObject (ActiveX)");
        print.indentedLine("• CF UI tags (cfform, cfgrid, cftree, etc.)");
        print.indentedLine("• CF AJAX components");
        print.indentedLine("• IE conditional comments");
        print.indentedLine("• CSS filters");
        print.line();
        
        print.yellowLine("SEVERITY LEVELS:");
        print.boldRedLine("  CRITICAL - Must fix (ActiveX)");
        print.redLine("  HIGH     - Should fix (CF UI tags, attachEvent)");
        print.yellowLine("  MEDIUM   - Consider fixing (IE conditionals)");
        print.greenLine("  LOW      - Nice to fix (minor compatibility)");
        print.line();
    }
}
