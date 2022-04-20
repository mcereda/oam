# Windows PowerShell

## TL;DR

```powershell
# print the value of the PATH environment variable
Write-Output $env:PATH

# calculate the hash of a file
CertUtil -hashfile path/to/file sha256

# get super user privileges
powershell Start-Process powershell -Verb runAs
```

## Further readings

- [How to print environment variables to the console in PowerShell?]
- [Running PowerShell as Administrator with the Command Line]

[how to print environment variables to the console in powershell?]: https://stackoverflow.com/questions/50861082/how-to-print-environment-variables-to-the-console-in-powershell#50861113
[running powershell as administrator with the command line]: https://adamtheautomator.com/powershell-run-as-administrator/
