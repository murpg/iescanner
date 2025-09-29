/**
 * Main IE Scanner Command - run.cfc
 * This is the default command when user types: box iescanner
 * It delegates to the scan subcommand by default
 */
component {
    
    /**
     * @directory.hint Directory to scan
     * @output.hint Output file path  
     * @format.hint Output format (csv, json, html)
     * @extensions.hint File extensions to scan
     * @recursive.hint Scan subdirectories
     * @verbose.hint Show detailed output
     * @help.hint Show help information
     */
    function run(
        string directory = getCWD(),
        string output = "",
        string format = "csv",
        string extensions = "cfm,cfc,js,html,htm",
        boolean recursive = true,
        boolean verbose = false,
        boolean help = false
    ) {
        
        // If help requested, show help
        if (arguments.help) {
            return runCommand("iescanner help");
        }
        
        // Default output filename if not provided
        if (!len(arguments.output)) {
            var timestamp = dateFormat(now(), "yyyymmdd") & "-" & timeFormat(now(), "HHmmss");
            arguments.output = "ie-scan-#timestamp#.#arguments.format#";
        }
        
        // Delegate to scan command
        return runCommand("iescanner scan")
            .params(
                directory = arguments.directory,
                output = arguments.output,
                format = arguments.format,
                extensions = arguments.extensions,
                recursive = arguments.recursive,
                verbose = arguments.verbose
            )
            .run();
    }
}
