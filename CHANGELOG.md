# Changelog

All notable changes to **PSAdminLauncher** will be documented in this file.  
This project adheres to **Semantic Versioning** (SemVer) and follows the spirit of **Keep a Changelog**.

## [Unreleased]

- Add support for Settings (`ms-settings:\*`).
- Add status bar.
- Add light/dark theme toggle.

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

[Unreleased]: 
[0.1.0]: 