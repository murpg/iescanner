# IEScanner - CommandBox Module

A CommandBox module that scans ColdFusion applications to identify Internet Explorer-specific code patterns that need to be updated for modern browser compatibility.

## ⚠️ CRITICAL: Internet Explorer Mode EOL in 2029

**Your IE-dependent applications will completely stop working in 2029. This is not optional - there will be no fallback.**

### The Timeline
- **June 2022**: Internet Explorer 11 desktop application was retired
- **Now (2025)**: IE mode in Edge is the only way to run IE-dependent code
- **2029**: IE mode will be completely removed from Microsoft Edge

### What This Means For Your Applications

When IE mode reaches end-of-life in 2029:
- **No IE browser will exist** on any Windows system
- **No compatibility mode** will be available
- **ActiveX controls will not run** anywhere
- **IE-specific JavaScript will fail** with errors
- **Legacy applications will completely stop functioning**

### Why This Is A Crisis

Many organizations don't realize they're sitting on a time bomb:

1. **IE Mode masks the problem** - Your apps "still work" today, creating false security
2. **Dependencies are hidden** - IE-specific code is buried in:
   - Legacy ColdFusion components
   - Old JavaScript libraries
   - Third-party components
   - CSS with IE-specific hacks
   - Intranet applications

3. **Binary failure** - Applications won't degrade gracefully; they'll simply stop working

### Real-World Impact

```javascript
// After 2029, this will throw "ActiveXObject is not defined" error
var xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");  // COMPLETE FAILURE

// This will return undefined, breaking all dependent logic
if (document.all) {  // WILL NOT EXECUTE
    // Critical business logic here will never run
}

// This will throw errors, breaking event handling
element.attachEvent('onclick', handler);  // COMPLETE FAILURE
```

### The 4-Year Remediation Timeline

**Starting now (2025) is crucial:**

- **Year 1 (2025-2026)**: Discovery and assessment using IEScanner
- **Year 2 (2026-2027)**: Development and remediation
- **Year 3 (2027-2028)**: Testing and deployment
- **Year 4 (2028-2029)**: Buffer for issues and final migration

### Business Consequences of Inaction

Organizations that don't remediate before 2029 will face:
- Complete application failure with no workaround
- Emergency remediation at 10x the cost
- Critical business systems going offline
- Potential compliance and regulatory failures
- Security vulnerabilities from hasty patches

**This is why IEScanner exists** - to help you identify and fix these issues before your applications catastrophically fail in 2029.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Pattern Detection](#pattern-detection)
- [Output Formats](#output-formats)
- [Examples](#examples)
- [API Reference](#api-reference)

## Prerequisites

### CommandBox Installation

IEScanner requires CommandBox CLI to be installed. CommandBox is available for all major operating systems:

- **Windows** - Native executable (box.exe)
- **Mac** - Homebrew installation or manual binary
- **Linux** - apt-get (Debian/Ubuntu), yum (RedHat/CentOS), or manual installation
- **Unix** - Manual binary installation
- **Raspberry Pi** - Supported via Debian installation method

For detailed installation instructions for your operating system, visit: https://commandbox.ortusbooks.com/setup/installation

Quick install commands:
- **Mac (Homebrew)**: `brew install commandbox`
- **Ubuntu/Debian**: `sudo apt-get install commandbox`
- **RedHat/CentOS**: `sudo yum install commandbox`
- **Windows**: Download and extract box.exe

## Installation

Install the module via CommandBox:

```bash
box install iescanner
```

Or add it to your `box.json` dependencies:

```json
{
    "dependencies": {
        "iescanner": "^1.0.0"
    }
}
```

## Usage

The IEScanner module provides a simple command-line interface for scanning your ColdFusion codebase for Internet Explorer-specific patterns.

### Basic Syntax

When using the CommandBox CLI, you can run the scanner directly:

```bash
iescanner directory <path>
```

You don't need to prefix commands with `box` when you're already in the CommandBox shell.

### Available Commands

#### Scan a Directory

Scan a specific directory for IE-specific patterns:

```bash
iescanner directory /path/to/your/project
```

Or using a Windows path:

```bash
iescanner directory C:\Documents\projects
```

#### Scan Current Directory

If no directory is specified, the scanner will use the current working directory:

```bash
iescanner directory
```

#### Specify Output Format

Generate different output formats for the scan results:

```bash
iescanner directory /path/to/project --output=json
iescanner directory /path/to/project --output=html
iescanner directory /path/to/project --output=csv
```

#### Save Output to File

Direct the output to a specific file:

```bash
iescanner directory /path/to/project --output=json --file=results.json
iescanner directory /path/to/project --output=html --file=report.html
```

## Configuration

### Pattern Configuration

While the IEScanner module includes default patterns embedded in the `iescanner.cfc` object, the **preferred method** is to use the `config/patterns.json` file for pattern configuration. This approach provides better maintainability and allows for easy customization without modifying the core module code.

#### Using config/patterns.json (Recommended)

Create or modify the `config/patterns.json` file in your module root:

```json
{
    "patterns": [
        {
            "name": "ActiveXObject",
            "pattern": "new\\s+ActiveXObject",
            "description": "ActiveX object instantiation",
            "severity": "critical",
            "replacement": "Use modern alternatives like XMLHttpRequest or fetch API"
        },
        {
            "name": "document.all",
            "pattern": "document\\.all",
            "description": "IE-specific document.all usage",
            "severity": "high",
            "replacement": "Use document.getElementById() or querySelector()"
        },
        {
            "name": "attachEvent",
            "pattern": "attachEvent\\s*\\(",
            "description": "IE-specific event attachment",
            "severity": "critical",
            "replacement": "Use addEventListener() instead"
        },
        {
            "name": "msPrefix",
            "pattern": "-ms-",
            "description": "IE vendor prefix in CSS",
            "severity": "medium",
            "replacement": "Use standard CSS properties or autoprefixer"
        }
    ]
}
```

#### Pattern Structure

Each pattern in the configuration should include:

- **name**: Unique identifier for the pattern
- **pattern**: Regular expression pattern to match
- **description**: Human-readable description of what this pattern detects
- **severity**: Impact level (`critical`, `high`, `medium`, `low`)
  - **critical**: Will cause complete failure - no fallback after 2029
  - **high**: Major functionality broken but may have workarounds
  - **medium**: Features degraded but application remains functional
  - **low**: Minor issues or cosmetic problems
- **replacement**: Suggested modern alternative

### Global Settings

You can configure global scanner settings via CommandBox config:

```bash
# Set default output format
config set modules.iescanner.defaultOutput=json

# Set default file extensions to scan
config set modules.iescanner.extensions=".cfm,.cfc,.js,.html"

# Enable/disable recursive scanning
config set modules.iescanner.recursive=true

# Set scan depth limit
config set modules.iescanner.maxDepth=10
```

## Pattern Detection

The IEScanner detects various Internet Explorer-specific patterns that should be removed or updated for modern browser compatibility. Here are the main categories:

### Browser Detection Patterns

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `navigator.userAgent` checks for "MSIE" or "Trident" | Critical | IE is no longer supported; browser sniffing is unreliable | Use feature detection instead |
| `document.documentMode` | Critical | IE-specific property | Use feature detection |
| `window.MSStream` | Critical | IE-specific stream object | Not needed in modern browsers |

### DOM Manipulation Patterns

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `document.all` | High | Non-standard, IE-specific collection | Use `document.getElementById()` or `querySelector()` |
| `attachEvent()` / `detachEvent()` | Critical | IE-specific event handling | Use `addEventListener()` / `removeEventListener()` |
| `event.srcElement` | High | IE-specific property | Use `event.target` |
| `event.returnValue` | High | IE-specific property | Use `event.preventDefault()` |

### ActiveX and Proprietary Features

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `ActiveXObject` | Critical | Security risk, IE-only technology | Use XMLHttpRequest, fetch, or native APIs |
| `window.clipboardData` | High | IE-specific clipboard API | Use modern Clipboard API |
| `document.selection` | High | IE-specific text selection | Use `window.getSelection()` |

### CSS and Styling

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `filter:` CSS property | Medium | IE-specific filters | Use standard CSS3 properties |
| `behavior:` CSS property | Critical | IE-specific behaviors | Use JavaScript or CSS3 |
| `expression()` in CSS | Critical | Security risk, IE-only | Use modern CSS or JavaScript |
| `-ms-` prefixed properties | Medium | IE-specific vendor prefix | Use standard properties or autoprefixer |

### Conditional Comments

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `<!--[if IE]>` | Critical | IE conditional comments | Use feature detection or progressive enhancement |
| `@cc_on` | Critical | Conditional compilation | Remove entirely, not needed |

### AJAX and Network

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `XDomainRequest` | Critical | IE-specific CORS handling | Use XMLHttpRequest with proper CORS |
| `window.XMLHttpRequest` checks | Medium | Obsolete compatibility checks | XMLHttpRequest is universally supported |

## Output Formats

### Console Output (Default)

```
IEScanner Results
=================
Scanning directory: /path/to/project
Files scanned: 142
Issues found: 23

File: /path/to/project/js/legacy.js
  Line 45: ActiveXObject usage detected
  Line 78: document.all reference found
  Line 102: attachEvent() usage detected

File: /path/to/project/css/old-styles.css
  Line 12: IE-specific filter property
  Line 34: -ms- vendor prefix detected

Summary:
  Critical severity: 12 issues
  High severity: 8 issues
  Medium severity: 10 issues
  Low severity: 5 issues
```

### JSON Output

```json
{
    "scanDate": "2025-09-29T10:30:00Z",
    "directory": "/path/to/project",
    "filesScanned": 142,
    "totalIssues": 23,
    "results": [
        {
            "file": "/path/to/project/js/legacy.js",
            "issues": [
                {
                    "line": 45,
                    "column": 12,
                    "pattern": "ActiveXObject",
                    "code": "var xhr = new ActiveXObject('Microsoft.XMLHTTP');",
                    "severity": "high",
                    "suggestion": "Use XMLHttpRequest instead"
                }
            ]
        }
    ],
    "summary": {
        "critical": 12,
        "high": 8,
        "medium": 10,
        "low": 5
    }
}
```

### HTML Output

```html
<!DOCTYPE html>
<html>
<head>
    <title>IEScanner Report</title>
    <style>
        .high { color: red; }
        .medium { color: orange; }
        .low { color: yellow; }
    </style>
</head>
<body>
    <h1>IE Compatibility Scan Report</h1>
    <p>Scan Date: September 29, 2025</p>
    <table>
        <thead>
            <tr>
                <th>File</th>
                <th>Line</th>
                <th>Issue</th>
                <th>Severity</th>
                <th>Recommendation</th>
            </tr>
        </thead>
        <tbody>
            <tr class="high">
                <td>/path/to/project/js/legacy.js</td>
                <td>45</td>
                <td>ActiveXObject usage</td>
                <td>High</td>
                <td>Replace with XMLHttpRequest</td>
            </tr>
        </tbody>
    </table>
</body>
</html>
```

### CSV Output

```csv
File,Line,Pattern,Severity,Code,Suggestion
"/path/to/project/js/legacy.js",45,"ActiveXObject","high","var xhr = new ActiveXObject('Microsoft.XMLHTTP');","Use XMLHttpRequest instead"
"/path/to/project/js/legacy.js",78,"document.all","medium","if (document.all) {","Use document.getElementById() or querySelector()"
```

## Examples

### Example 1: Basic Directory Scan

Scan your current project for IE-specific patterns:

```bash
cd /path/to/your/project
iescanner directory
```

### Example 2: Scan with JSON Output

Generate a JSON report for CI/CD integration:

```bash
iescanner directory /var/www/myapp --output=json --file=ie-scan-results.json
```

### Example 3: Scan Specific File Types

Scan only JavaScript and CSS files:

```bash
iescanner directory /path/to/project --extensions=".js,.css"
```

### Example 4: Non-Recursive Scan

Scan only the top-level directory:

```bash
iescanner directory /path/to/project --recursive=false
```

### Example 5: Custom Pattern Configuration

Using a custom patterns file:

```bash
iescanner directory /path/to/project --patterns=/path/to/custom-patterns.json
```

### Example 6: Verbose Output

Get detailed information during scanning:

```bash
iescanner directory /path/to/project --verbose=true
```

### Example 7: Exclude Directories

Scan while excluding certain directories:

```bash
iescanner directory /path/to/project --exclude="node_modules,vendor,dist"
```

### Example 8: Generate HTML Report

Create an HTML report for team review:

```bash
iescanner directory C:\projects\legacy-app --output=html --file=ie-report.html
```

## API Reference

### iescanner.scan()

Programmatically use the scanner in your ColdFusion code:

```cfscript
// Get the scanner instance
scanner = getInstance("iescanner@iescanner");

// Configure scan options
options = {
    directory: "/path/to/scan",
    recursive: true,
    extensions: [".cfm", ".cfc", ".js", ".css", ".html"],
    exclude: ["node_modules", "vendor"],
    patterns: "config/patterns.json"
};

// Perform scan
results = scanner.scan(options);

// Process results
for (result in results.files) {
    writeOutput("File: #result.path# - Issues: #result.issues.len()#<br>");
}
```

### Custom Pattern Loader

```cfscript
// Load custom patterns
patterns = getInstance("PatternLoader@iescanner");
customPatterns = patterns.load("/path/to/patterns.json");

// Add custom pattern dynamically
patterns.add({
    name: "customCheck",
    pattern: "myCustomPattern",
    severity: "medium",
    description: "Custom IE pattern check"
});
```

## Troubleshooting

### Common Issues

1. **Scanner not finding files**: Ensure the path exists and you have read permissions
2. **Pattern not matching**: Check regex escaping in patterns.json
3. **Output file not created**: Verify write permissions in the target directory
4. **Performance issues**: Use `--exclude` to skip large directories like node_modules

### Debug Mode

Enable debug output for troubleshooting:

```bash
iescanner directory /path/to/project --debug=true
```

## Contributing

Contributions are welcome! Please submit pull requests with:

1. Updated patterns in config/patterns.json
2. Test cases for new patterns
3. Documentation updates

## License

This module is open source and available under the MIT License.

## Support

For issues, questions, or suggestions, please visit: https://github.com/murpg/iescanner

## Changelog

### Version 1.0.0
- Initial release
- Core pattern detection for IE-specific code
- Multiple output formats (console, JSON, HTML, CSV)
- Configurable patterns via config/patterns.json
- Recursive directory scanning
- File extension filtering