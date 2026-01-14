## User Guide
### Launching the Application
To launch the application, simply double-click the executable. Because the application is compiled as a GUI app, no console window will appear. Alternatively, you can call the application from a PowerShell terminal:

```PowerShell
Start-Process -FilePath 'C:\path\to\PSAdminLauncher.exe'
```

Upon launch, the application dynamically scans your system for management consoles, control panel applets, and shell tasks. This discovery process is nearly instantaneous, ensuring the UI is ready for use immediately.

### Main Window
![](/images/screenshot-main-window.png)  

The main window is divided into three distinct columns to help you quickly locate the correct administrative tool:  
  - MMC Snap-ins: Displays all .msc files found in the system directory (e.g., Computer Management, Event Viewer, Active Directory).
  - Control Panel: Displays standard .cpl applets found in System32 (e.g., Network Connections, Power Options).
  - Deep Tasks (God Mode): Provides an unfiltered list of every deep-link task available in the Windows Master Control Panel namespace.
  - Modern Windows Settings: Direct links to the various pages in the Windows Settings app, dynamically loaded from the DLL.

#### Navigation Features  
  - Click: You can double-click any item in any list to launch it immediately.
  - Exclusive Selection: Clicking an item in one list will automatically clear selections in the other two columns to ensure you always know which tool is currently "active."

#### Controls & Information Bar
![](/images/screenshot-main-window-search.png)  
The bottom of the window contains the search bar, security context, and action buttons:
  - Filter: Type any string to filter all three columns simultaneously. The lists update in real-time as you type.
  - Force Admin (RunAs): When checked (default), the launcher will attempt to elevate the selected tool using the runas verb.
  - Context Indicator: Displays the current user identity in DOMAIN\username format. This text is highlighted in green for easy visibility, allowing you to confirm your current security token at a glance.
  - Launch PowerShell: Launches an authentication flow. This will prompt you for credentials and spawn a new PowerShell session in a completely fresh local security context of the provided user.
  - Launch Selected: Executes the highlighted tool from any of the three columns.
  - Exit: Closes the application.

##### Authentication Flow for Launching New PowerShell Sessions
![](/images/screenshot-launch-ps-cred-prompt.png)  
![](/images/screenshot-launch-ps-new-context.png)  
When you click the New PS (Any User) button, the following process occurs:
  1. Credential Prompt: A standard Windows Security modal appears. You can enter credentials for any domain or local account.
  2. Environment Loading: The application uses the -LoadUserProfile flag to ensure the new session has the correct registry hives and environment variables loaded.
  3. Path Resolution: The new session is automatically pointed to C:\Windows\System32 as its working directory to prevent permission errors often encountered on hardened servers.

You can use `$env:USERNAME` or `whoami` in the resulting PowerShell window to verify that the session is running under the new identity, independent of the launcher's context.
