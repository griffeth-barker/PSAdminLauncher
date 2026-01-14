# Changelog

All notable changes to **PSAdminLauncher** will be documented in this file.  
This project adheres to **Semantic Versioning** (SemVer) and follows the spirit of **Keep a Changelog**.

## Unreleased

- Add status bar.
- Add light/dark theme toggle.

## [0.2.0] - 2026-01-13

### Added
- Modern Settings (ms-settings) Column: Implemented a fourth UI column that dynamically discovers and launches modern Windows Settings URIs.

- C# Scanner: Integrated an in-memory C# class using the Boyer-Moore-Horspool algorithm to instantly extract URIs from SystemSettings.dll for modern Windows settings.
  - Full credit for this goes to Helmut Wagensonner (see [Understanding Windows Settings URIs and How to Use Them in Enterprise Environments](https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/understanding-windows-settings-uris-and-how-to-use-them-in-enterprise-environmen/4481486))

- RSAT Name Mapping: Expanded the friendly name dictionary to include nearly 50 administrative snap-ins, covering Active Directory, DHCP, DNS, WDS, WSUS, and Cluster Management.

- Enhanced Discovery Filtering: Modified the MMC discovery loop to automatically exclude redundant or legacy items (like iis.msc) that are now handled more effectively by the Deep Tasks column.

- Expanded Workspace: Increased the default window width to 1550px to provide a comfortable viewing area for the new four-column architecture.

### Fixed
- Session Persistence Fix: Added a type-guard check for the MsSettingsScanner class to prevent TYPE_ALREADY_EXISTS errors when running the script multiple times in the same PowerShell session (this was not actually an issue in the prior version, but cosmetically annoying during development).

- Launch Logic for URIs: Refactored the Start-Tool function to detect ms-settings: protocols and launch them via the shell rather than attempting to pass them as executable arguments.

- IEnumerable Conversion Error: Wrapped all list filtering results in the array sub-expression operator @() to prevent WPF binding crashes when a search filter returned exactly one result.

- Path Resolution: Hardcoded absolute paths for MMC snap-ins to ensure reliability when the application is launched from non-standard working directories.

- Recursive Selection Loop: Added a script-level boolean guard ($isUpdatingSelection) to prevent infinite event loops when programmatically clearing selections across multiple columns.

## [0.1.0] – 2026-01-05

### Added
- Triple-Column Interface: Implemented a wide-format WPF dashboard featuring dedicated lists for MMC Snap-ins, Control Panel Applets, and "God Mode" Deep Tasks.

- Dynamic Tool Discovery: Developed a real-time scanning engine that enumerates .msc and .cpl files directly from System32, ensuring the launcher remains environment-aware.

- Master Control Panel (God Mode) Integration: Integrated the Windows Master Control Panel via COM shell objects, providing unfiltered access to over 200+ deep-link administrative tasks.

- Smart Name Resolution: Added a multi-tier naming logic that resolves cryptic filenames (e.g., dsa.msc) into human-readable titles using manual mapping and binary file metadata (File Description).

- Enhanced Re-Authentication: Created a "New PS (Any User)" feature that uses Get-Credential and -LoadUserProfile to spawn fresh PowerShell sessions in a different local security context, resolving common "Directory name is invalid" errors on hardened servers.

- Unified Search Engine: Implemented a real-time, global filter at the bottom of the UI that simultaneously updates all three tool columns as the user types.

- Identity Context Awareness: Added a persistent status indicator displaying the current user context in DOMAIN\username format, color-coded for instant verification.

- Exclusive Selection Logic: Developed a custom event handler to manage cross-column selection, ensuring only one tool is staged for launch at any given time.

- Dark Mode UI: Designed a high-contrast dark theme utilizing a custom XAML resource dictionary for better usability in server room environments.

- PS2EXE Optimization: Refined all modal windows and credential prompts to use GUI-based handlers (CREDUIPROMPT), ensuring full compatibility when wrapped as a standalone executable.

[0.2.0]: https://github.com/griffeth-barker/PSAdminLauncher/releases/tag/v0.2.0  
[0.1.0]: https://github.com/griffeth-barker/PSAdminLauncher/releases/tag/v0.1.0  