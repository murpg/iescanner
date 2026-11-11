# IEScanner - CommandBox Module

A CommandBox module that scans ColdFusion applications to identify Internet Explorer-specific code patterns that need to be updated for modern browser compatibility.

> NEW in v1.2.0: IEScanner now ships a bundled patterns file for ColdFusion deprecated and removed tags, functions, and algorithms — ready for auditing a CF2023 codebase ahead of a ColdFusion 2025 upgrade. See [Bundled CF2023 -> CF2025 Migration Patterns](#bundled-cf2023---cf2025-migration-patterns).

## WARNING: Internet Explorer Mode EOL in 2029

**Your IE-dependent applications will completely stop working in 2029. This is not optional - there will be no fallback.**

### The Timeline

- **June 2022**: Internet Explorer 11 desktop application was retired
- **Windows Server 2019**: IE-dependent sites still function today across multiple browsers
- **Windows Server 2022 / 2025**: IE-dependent sites will not run in Chrome or Firefox at all. Microsoft Edge in IE Mode is the only browser capable of rendering them on these operating systems. There is no other workaround.
- **Now (2026)**: IE Mode in Edge is the only viable path for IE-dependent code on any modern OS
- **2029**: IE Mode will be completely removed from Microsoft Edge — no fallback will exist on any platform

### What This Means For Your Applications

**On Windows Server 2022 and Windows Server 2025 right now:**

- Chrome and Firefox cannot render IE-dependent sites at all
- Microsoft Edge in IE Mode is the only browser that works
- This is already the reality for any team that has upgraded their OS

**After 2029 on any OS:**

- No IE browser will exist on any Windows system
- No compatibility mode will be available in any browser
- ActiveX controls will not run anywhere
- IE-specific JavaScript will fail with errors
- Legacy applications will completely stop functioning

### Why This Is A Crisis

Many organizations don't realize they're sitting on a time bomb:

1. **OS upgrades trigger the problem now — not in 2029** - Moving from Windows Server 2019 to 2022 or 2025 immediately breaks IE-dependent sites in Chrome and Firefox. Edge IE Mode becomes the only option the moment that upgrade happens. Organizations planning infrastructure upgrades face this problem today, not in three years.
2. **IE Mode masks the problem** - Sites appear to work in Edge IE Mode today, creating false confidence that nothing needs to change
3. **Dependencies are hidden** - IE-specific code is buried in:
   - Legacy ColdFusion components
   - Old JavaScript libraries
   - Third-party components
   - CSS with IE-specific hacks
   - Intranet applications
4. **Binary failure in 2029** - When IE Mode is removed from Edge, applications will not degrade gracefully; they will simply stop working in every browser on every OS

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

### The Remediation Timeline

**The urgency is not only 2029 — it is your next OS upgrade.**

Any migration from Windows Server 2019 to 2022 or 2025 immediately drops Chrome and Firefox support for IE-dependent sites. If an OS upgrade is on the roadmap, remediation must be completed before that upgrade occurs, regardless of the 2029 deadline.

- **Now (2026)**: Discovery and assessment using IEScanner
- **Year 2 (2027)**: Development and remediation
- **Year 3 (2028)**: Testing and deployment
- **Year 4 (2029)**: Final deadline — IE Mode removed from Edge on all platforms

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
- [Beyond IE Detection](#beyond-ie-detection)

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

```
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

> NOTE: All examples below assume you are already inside the CommandBox shell. If you are running from your OS command line, prefix each command with `box `.

### Basic Syntax

```
iescanner [directory=path] [format=csv|json|html] [output=filepath] [verbose=true|false] [reloadPatterns=true|false]
```

Parameters use `name=value` syntax with no dashes. All parameters are optional.

### Parameters

| Parameter        | Type    | Default                          | Description                                                        |
|------------------|---------|----------------------------------|--------------------------------------------------------------------|
| `directory`      | string  | `.` (current directory)          | Path to scan                                                       |
| `format`         | string  | `csv`                            | Output format: `csv`, `json`, or `html`                            |
| `output`         | string  | `ie-scan-[timestamp].[format]`   | Output file path (absolute or relative to CWD)                     |
| `extensions`     | string  | `cfm,cfc,js,html,htm`            | Comma-separated file extensions to scan, no dots                   |
| `patterns`       | string  | *(auto-locate config/patterns.json)* | Absolute path to a custom patterns JSON file                   |
| `verbose`        | boolean | `false`                          | Show each file as it is scanned                                    |
| `reloadPatterns` | boolean | `false`                          | Force reload of the default patterns.json, clearing the cache      |
| `help`           | boolean | `false`                          | Display inline help                                                |

> NOTE: When `output` is a relative path or uses the default timestamped filename, the file is written to the CommandBox working directory. Use an absolute path to control the exact location.

> NOTE: When `patterns` is provided, the pattern cache is bypassed entirely so that multiple scans in the same session can use different pattern files without interference. `reloadPatterns` only affects the default patterns.json cache.

### Available Commands

#### Scan the Current Directory

```
iescanner
```

#### Scan a Specific Directory

```
iescanner directory=C:\projects\myapp
iescanner directory=/var/www/myapp
```

#### Scan and Generate an HTML Report

```
iescanner directory=C:\projects\myapp format=html output=C:\reports\ie-report.html
```

#### Scan and Generate a JSON Report

```
iescanner directory=C:\projects\myapp format=json output=C:\reports\ie-scan.json
```

#### Scan Additional File Types

Add extensions beyond the default set. Pass a comma-separated list with no dots:

```
iescanner directory=C:\projects\myapp extensions=cfm,cfc,js,html,htm,pl,py
```

Remove extensions to narrow the scan. For example, ColdFusion source files only:

```
iescanner directory=C:\projects\myapp extensions=cfm,cfc
```

#### Use a Custom Patterns File

Point the scanner at any patterns JSON file instead of the default `config/patterns.json`.
The pattern cache is bypassed automatically when this parameter is used:

```
iescanner directory=C:\projects\myapp patterns=D:\config\solr-patterns.json format=html output=C:\reports\solr-report.html
```

#### Show Verbose File-by-File Progress

```
iescanner directory=C:\projects\myapp verbose=true
```

#### Force Reload Patterns from JSON

Use this after replacing `config/patterns.json` to clear the cached patterns:

```
iescanner directory=C:\projects\myapp reloadPatterns=true
```

#### Show Inline Help

```
iescanner help=true
```

## Configuration

### Pattern Configuration

IEScanner includes a minimal set of fallback patterns hardcoded in `commands/iescanner.cfc`. The preferred method is to use the `config/patterns.json` file. Patterns loaded from JSON take precedence over the hardcoded defaults. If `patterns.json` cannot be found, the scanner falls back to the hardcoded set automatically.

#### Using config/patterns.json (Recommended)

The file is a flat JSON array. Each element requires `pattern` (a regex string), `severity`, `description`, and `recommendation`:

```json
[
    {
        "pattern": "ActiveXObject",
        "severity": "CRITICAL",
        "description": "ActiveX object usage",
        "recommendation": "Remove ActiveX dependencies"
    },
    {
        "pattern": "document\\.all",
        "severity": "HIGH",
        "description": "IE-specific document.all",
        "recommendation": "Use document.getElementById() or querySelector()"
    },
    {
        "pattern": "attachEvent\\s*\\(",
        "severity": "HIGH",
        "description": "IE-specific attachEvent",
        "recommendation": "Use addEventListener()"
    },
    {
        "pattern": "<cfsearch",
        "severity": "CRITICAL",
        "description": "CFSEARCH tag - references a Solr collection",
        "recommendation": "Verify the named Solr collection exists in CF Admin"
    }
]
```

> NOTE: The `<` character in tag patterns such as `<cfsearch` is automatically converted internally by the scanner. You do not need to escape it.

> NOTE: All pattern matching is case-insensitive. The `(?i)` inline flag is not required.

#### Pattern Structure

| Field            | Required | Description                                                    |
|------------------|----------|----------------------------------------------------------------|
| `pattern`        | Yes      | Regular expression to match against each line of source code   |
| `severity`       | Yes      | `CRITICAL`, `HIGH`, `MEDIUM`, or `LOW`                         |
| `description`    | Yes      | Human-readable description of what the pattern detects         |
| `recommendation` | Yes      | Suggested remediation action                                   |

Severity meaning:

- **CRITICAL**: Will cause complete failure after 2029 with no fallback
- **HIGH**: Major functionality broken but may have workarounds
- **MEDIUM**: Features degraded but application remains functional
- **LOW**: Minor issues or cosmetic problems

### Using a Custom Patterns File

Pass an absolute path to any patterns JSON file using the `patterns` parameter. The scanner
will load that file directly, bypassing the default `config/patterns.json` search and the
pattern cache:

```
iescanner directory=C:\projects\myapp patterns=D:\config\solr-patterns.json format=html output=C:\reports\solr-report.html
```

Multiple scans in the same CommandBox session can each use a different patterns file without
interfering with one another. The default patterns cache is unaffected.

### Bundled CF2023 -> CF2025 Migration Patterns

As of v1.2.0, the module ships a ready-made patterns file for auditing a ColdFusion 2023
codebase ahead of an upgrade to ColdFusion 2025. It lives alongside the default patterns at
`config/cf2023-to-cf2025-patterns.json` and flags the tags, functions, attributes, and
encryption algorithms removed or deprecated in CF2025 — in both tag form (`<cftree ...>`) and
cfscript form (`cftree( ... )`).

Point the `patterns` parameter at its absolute path on disk. For example, from a local working
copy of this repository:

```
iescanner directory=C:\projects\myapp patterns=D:\projects\refactored\gitlab-personal\forgebox-module\iescanner\config\cf2023-to-cf2025-patterns.json format=html output=C:\reports\cf2025-migration.html
```

Because `patterns` bypasses the default pattern cache, this scan can run back-to-back with a
normal IE scan in the same CommandBox session without a reload.

## Pattern Detection

The IEScanner detects various Internet Explorer-specific patterns that should be removed or updated for modern browser compatibility.

### Browser Detection Patterns

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `navigator.userAgent` checks for "MSIE" or "Trident" | CRITICAL | IE is no longer supported; browser sniffing is unreliable | Use feature detection instead |
| `document.documentMode` | CRITICAL | IE-specific property | Use feature detection |
| `window.MSStream` | CRITICAL | IE-specific stream object | Not needed in modern browsers |

### DOM Manipulation Patterns

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `document.all` | HIGH | Non-standard, IE-specific collection | Use `document.getElementById()` or `querySelector()` |
| `attachEvent()` / `detachEvent()` | CRITICAL | IE-specific event handling | Use `addEventListener()` / `removeEventListener()` |
| `event.srcElement` | HIGH | IE-specific property | Use `event.target` |
| `event.returnValue` | HIGH | IE-specific property | Use `event.preventDefault()` |

### ActiveX and Proprietary Features

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `ActiveXObject` | CRITICAL | Security risk, IE-only technology | Use XMLHttpRequest, fetch, or native APIs |
| `window.clipboardData` | HIGH | IE-specific clipboard API | Use modern Clipboard API |
| `document.selection` | HIGH | IE-specific text selection | Use `window.getSelection()` |

### CSS and Styling

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `filter:` CSS property | MEDIUM | IE-specific filters | Use standard CSS3 properties |
| `behavior:` CSS property | CRITICAL | IE-specific behaviors | Use JavaScript or CSS3 |
| `expression()` in CSS | CRITICAL | Security risk, IE-only | Use modern CSS or JavaScript |
| `-ms-` prefixed properties | MEDIUM | IE-specific vendor prefix | Use standard properties or autoprefixer |

### Conditional Comments

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `<!--[if IE]>` | CRITICAL | IE conditional comments | Use feature detection or progressive enhancement |
| `@cc_on` | CRITICAL | Conditional compilation | Remove entirely, not needed |

### AJAX and Network

| Pattern | Severity | Why Remove | Modern Alternative |
|---------|----------|------------|-------------------|
| `XDomainRequest` | CRITICAL | IE-specific CORS handling | Use XMLHttpRequest with proper CORS |
| `window.XMLHttpRequest` checks | MEDIUM | Obsolete compatibility checks | XMLHttpRequest is universally supported |

## Output Formats

### Console Output

The scanner always writes a summary to the console regardless of the output format selected:

```
+==========================================+
|   IE Legacy Code Scanner - v1.1.0       |
+==========================================+

Directory : C:\projects\myapp\
Output    : ie-scan-20260330120000.csv
Format    : csv
Extensions: cfm,cfc,js,html,htm
Patterns  : config/patterns.json (default)

Searching for files...
Found 142 files to scan

Scanning files...
................................................... 100%

Report saved: ie-scan-20260330120000.csv

[SUCCESS] Scan Complete!

========================================
SUMMARY:
Files scanned    : 142
Files with issues: 23
Total issues     : 35
Scan time        : 4.21 seconds

Issues by Severity:
  CRITICAL: 12
  HIGH    : 8
  MEDIUM  : 10
  LOW     : 5
========================================
```

### CSV Output (Default)

Columns: `File`, `Line`, `Severity`, `Description`, `Recommendation`

```
File,Line,Severity,Description,Recommendation
"js/legacy.js",45,HIGH,"IE-specific attachEvent","Use addEventListener()"
"js/legacy.js",78,HIGH,"IE-specific document.all","Use document.getElementById() or querySelector()"
"css/old-styles.css",12,MEDIUM,"IE CSS filter","Use CSS3 opacity"
```

### JSON Output

```json
{
    "scanDate": "2026-03-30 12:00:00",
    "totalIssues": 35,
    "issues": [
        {
            "file": "js/legacy.js",
            "line": 45,
            "severity": "HIGH",
            "description": "IE-specific attachEvent",
            "recommendation": "Use addEventListener()"
        }
    ]
}
```

### HTML Output

Generates a self-contained HTML report with a summary, severity stat cards, and a full issues table. Open the file directly in any browser.

## Examples

### Example 1: Basic Scan of Current Directory

```
iescanner
```

### Example 2: Scan a Specific Directory, CSV Output

```
iescanner directory=C:\projects\myapp
```

The CSV report is saved to the CommandBox working directory with a timestamped filename such as `ie-scan-20260330120000.csv`.

### Example 3: HTML Report Saved to an Absolute Path

```
iescanner directory=C:\projects\myapp format=html output=C:\reports\ie-report.html
```

### Example 4: JSON Report Saved to Desktop

```
iescanner directory=C:\projects\myapp format=json output=C:\Users\george.murphy.ctr\Desktop\ie-scan.json
```

### Example 5: Add File Types to the Scan

Extend the default set to also catch Perl and Python files:

```
iescanner directory=C:\projects\myapp extensions=cfm,cfc,js,html,htm,pl,py
```

### Example 6: Narrow the Scan to ColdFusion Files Only

```
iescanner directory=C:\projects\myapp extensions=cfm,cfc
```

### Example 7: Use a Custom Patterns File

Scan for Solr collection references using a dedicated patterns file:

```
iescanner directory=C:\projects\myapp patterns=D:\config\solr-patterns.json format=html output=C:\reports\solr-report.html
```

### Example 8: Run Two Different Scans Back-to-Back in the Same Session

Because `patterns` bypasses the cache, each scan loads its own file independently:

```
iescanner directory=C:\projects\myapp patterns=D:\config\ie-patterns.json format=html output=C:\reports\ie-report.html
iescanner directory=C:\projects\myapp patterns=D:\config\solr-patterns.json format=html output=C:\reports\solr-report.html
```

### Example 9: Verbose Scan Showing Each File

```
iescanner directory=C:\projects\myapp verbose=true
```

### Example 10: Force Reload the Default Patterns After Editing patterns.json

```
iescanner directory=C:\projects\myapp reloadPatterns=true
```

## Beyond IE Detection

While IEScanner was built to find IE-specific code, the pattern engine is general-purpose. Any text pattern expressible as a regular expression can be dropped into `config/patterns.json` and scanned across your entire ColdFusion codebase. This makes the tool useful for a broad range of code audits beyond browser compatibility.

> NOTE: The scanner searches `*.cfm`, `*.cfc`, `*.js`, `*.html`, and `*.htm` files. It will not walk into directories containing only `.pl`, `.swf`, or other non-web-source files. The patterns below detect references to those technologies within your ColdFusion source — for example, a `<cfinclude>` that pulls in a Perl script, an `<object>` tag embedding a SWF, or a path string pointing to a `.pl` endpoint.

### Use Case Examples

#### Legacy Plugin and Technology Audit

Find references to deprecated or end-of-life technologies embedded in your source:

```json
[
    {
        "pattern": "\\.swf[\"'\\s>]",
        "severity": "CRITICAL",
        "description": "Adobe Flash SWF reference",
        "recommendation": "Flash reached end-of-life December 2020. Remove all SWF embeds and replace with HTML5 equivalents."
    },
    {
        "pattern": "\\.pl[\"'\\s?]",
        "severity": "HIGH",
        "description": "Perl script reference (.pl)",
        "recommendation": "Identify whether this Perl endpoint is still active. Consider migrating to ColdFusion or a supported language."
    },
    {
        "pattern": "\\.cgi[\"'\\s?]",
        "severity": "HIGH",
        "description": "CGI script reference",
        "recommendation": "CGI scripts are a legacy execution model. Migrate to ColdFusion components or a modern API."
    },
    {
        "pattern": "classid\\s*=",
        "severity": "CRITICAL",
        "description": "ActiveX classid attribute (object embed)",
        "recommendation": "ActiveX object embeds are IE-only and non-functional in all modern browsers. Remove entirely."
    },
    {
        "pattern": "application/x-shockwave-flash",
        "severity": "CRITICAL",
        "description": "Flash MIME type reference",
        "recommendation": "Flash is end-of-life. Remove all Flash MIME references and replace with HTML5 media."
    }
]
```

#### Deprecated ColdFusion Tag Audit

Find ColdFusion UI tags deprecated in CF2021 and removed in CF2025:

> NOTE: For a complete, ready-to-run version of this audit, use the bundled
> `config/cf2023-to-cf2025-patterns.json` file described under
> [Bundled CF2023 -> CF2025 Migration Patterns](#bundled-cf2023---cf2025-migration-patterns).
> The five-tag snippet below is a minimal illustration; the bundled file covers the full set of
> CF2025 removals and deprecations in both tag and cfscript form.

```json
[
    {
        "pattern": "<cfform",
        "severity": "HIGH",
        "description": "CFFORM tag - deprecated ColdFusion UI",
        "recommendation": "Replace with a standard HTML form."
    },
    {
        "pattern": "<cfgrid",
        "severity": "HIGH",
        "description": "CFGRID tag - deprecated ColdFusion UI",
        "recommendation": "Replace with a modern JavaScript grid such as AG-Grid or DataTables."
    },
    {
        "pattern": "<cftree",
        "severity": "HIGH",
        "description": "CFTREE tag - deprecated ColdFusion UI",
        "recommendation": "Replace with a JavaScript tree component such as jsTree."
    },
    {
        "pattern": "<cfwindow",
        "severity": "HIGH",
        "description": "CFWINDOW tag - deprecated ColdFusion UI",
        "recommendation": "Replace with a CSS/JavaScript modal library."
    },
    {
        "pattern": "<cfajaxproxy",
        "severity": "HIGH",
        "description": "CFAJAXPROXY tag - deprecated ColdFusion AJAX",
        "recommendation": "Replace with the fetch API or XMLHttpRequest."
    }
]
```

#### Solr Collection Audit

Find all code that references ColdFusion Solr collections to verify they exist in CF Admin:

```json
[
    {
        "pattern": "<cfcollection",
        "severity": "CRITICAL",
        "description": "CFCOLLECTION tag - references a Solr collection",
        "recommendation": "Verify the named Solr collection exists in CF Admin. If no collection is configured, this will fail at runtime."
    },
    {
        "pattern": "<cfsearch",
        "severity": "CRITICAL",
        "description": "CFSEARCH tag - executes a Solr collection search",
        "recommendation": "Verify the target Solr collection exists in CF Admin. If no collection is configured, all searches will throw a runtime error."
    },
    {
        "pattern": "<cfindex",
        "severity": "CRITICAL",
        "description": "CFINDEX tag - indexes content into a Solr collection",
        "recommendation": "Verify the target Solr collection exists in CF Admin. If no collection is configured, indexing operations will fail."
    },
    {
        "pattern": "collectionSearch\\s*\\(",
        "severity": "CRITICAL",
        "description": "collectionSearch() CFScript function - searches a Solr collection",
        "recommendation": "Verify the named Solr collection exists in CF Admin."
    },
    {
        "pattern": "collectionIndex\\s*\\(",
        "severity": "CRITICAL",
        "description": "collectionIndex() CFScript function - indexes content into a Solr collection",
        "recommendation": "Verify the target Solr collection exists in CF Admin."
    },
    {
        "pattern": "collectionCreate\\s*\\(",
        "severity": "HIGH",
        "description": "collectionCreate() CFScript function - creates a Solr collection programmatically",
        "recommendation": "Confirm this call is intentional and that CF Admin has Solr configured."
    }
]
```

#### Hard-coded Credential and Sensitive Value Audit

Find patterns commonly associated with hard-coded credentials or environment-specific values left in source:

```json
[
    {
        "pattern": "password\\s*=\\s*[\"'][^\"']+[\"']",
        "severity": "CRITICAL",
        "description": "Possible hard-coded password value",
        "recommendation": "Move credentials to environment variables or a secrets manager. Never hard-code passwords in source."
    },
    {
        "pattern": "datasource\\s*=\\s*[\"'][^\"']+[\"']",
        "severity": "MEDIUM",
        "description": "Hard-coded datasource name",
        "recommendation": "Consider centralizing datasource names in Application.cfc or a config component rather than scattering them across files."
    },
    {
        "pattern": "192\\.168\\.|10\\.0\\.|172\\.16\\.",
        "severity": "MEDIUM",
        "description": "Hard-coded private IP address",
        "recommendation": "Replace with a named hostname or environment variable to avoid environment-specific failures."
    }
]
```

### Tips for Writing Custom Patterns

- **Keep patterns specific.** A pattern that is too broad, such as matching `password` anywhere, will produce a high volume of false positives. Anchor or qualify patterns where possible.
- **Use `severity` to prioritize.** Run with `CRITICAL` and `HIGH` first, fix those, then address `MEDIUM` and `LOW` in a follow-up pass.
- **One concern per pattern.** Separate patterns are easier to read in reports and easier to maintain than a single complex regex that catches multiple things.
- **Test regex before committing.** CF uses Java-compatible regex. Tools such as regex101.com with the Java flavor selected are useful for validating patterns before adding them to the JSON file.
- **Remember the cache.** After updating `patterns.json`, run with `reloadPatterns=true` on the first scan of the session or the old patterns will be used.

## Troubleshooting

### Common Issues

1. **Scanner not finding files**: Ensure the path exists and you have read permissions. Check which extensions are being scanned — use `extensions=cfm,cfc,js,html,htm` to confirm the default, or expand it to include additional types.
2. **Report saved to unexpected location**: If `output` is a relative path or uses the default timestamped name, the file is written to the CommandBox working directory, not the scanned directory. Use an absolute path.
3. **Default pattern changes not taking effect**: The scanner caches the default `patterns.json` for the session. Run with `reloadPatterns=true` after editing it.
4. **Custom patterns file not loading**: Verify the path passed to `patterns=` is absolute and the file exists. The scanner will print an error and exit if the file cannot be found.
5. **Pattern not matching**: Check regex escaping in the JSON file. Remember that `<` in tag patterns such as `<cfsearch` is automatically converted internally — you do not need to escape it.

## Contributing

Contributions are welcome. Please submit pull requests with:

1. Updated patterns in `config/patterns.json`
2. Test cases for new patterns
3. Documentation updates

## License

This module is open source and available under the MIT License.

## Support

For issues, questions, or suggestions, please visit: https://github.com/murpg/iescanner

## Changelog

### Version 1.2.1

- Fixed the console banner to report the correct version (was still printing v1.1.0)
- Excluded scanner output reports (`ie-scan-*.csv`, `ie-scan-*.json`, `ie-scan-*.html`) from the published package

### Version 1.2.0

- Added a bundled `config/cf2023-to-cf2025-patterns.json` patterns file for auditing a ColdFusion 2023 codebase ahead of an upgrade to ColdFusion 2025 (64 patterns)
- Covers tags, functions, attributes, and encryption algorithms removed or deprecated in CF2025, in both tag form (`<cftree ...>`) and cfscript form (`cftree( ... )`)
- Documented usage under "Bundled CF2023 -> CF2025 Migration Patterns" with a cross-reference from the Deprecated ColdFusion Tag Audit example

### Version 1.1.0

- Added `extensions` parameter — comma-separated list of file extensions to scan with no dots (default: `cfm,cfc,js,html,htm`)
- Added `patterns` parameter — absolute path to a custom patterns JSON file, bypasses default search and pattern cache
- Refactored pattern loading into `findDefaultPatternsFile()` and `loadPatternsFromFile()` for cleaner separation
- Console output now shows active extensions and patterns file on every run
- Help text updated to reflect all parameters

### Version 1.0.0

- Initial release
- Core pattern detection for IE-specific code
- Multiple output formats (CSV, JSON, HTML)
- Configurable patterns via `config/patterns.json` with hardcoded fallback
- Recursive directory scanning for `.cfm`, `.cfc`, `.js`, `.html`, `.htm`
- Case-insensitive pattern matching via `reFindNoCase()`
- Pattern cache with `reloadPatterns` flag to force refresh