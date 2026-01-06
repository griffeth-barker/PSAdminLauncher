## Troubleshooting
Launch Failed: If a tool fails to launch, a popup message will appear with the system error code. This is often due to the specific tool requiring a role (like RSAT) that is not currently enabled on the server. This shouldn't be a common error, as the tool lists are dynamically enumerated based on available tools.

Directory Name is Invalid: This error is mitigated in the current version by forcing a neutral working directory during re-authentication. If it persists, ensure the user account provided has at least read access to the C:\Windows\System32 folder.