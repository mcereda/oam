# Windows PowerShell <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```ps1
# Calculate the hash of a file.
CertUtil -hashfile path/to/file sha256

# Get super user privileges.
Start-Process powershell -Verb runAs

# List available features.
Get-WindowsCapability -Online
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# Install a feature.
Add-WindowsCapability -Online -Name OpenSSH.Server
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Test a network connection.
Test-NetConnection -Port 443 -ComputerName 192.168.0.1 -InformationLevel Detailed

# Assign values to variables.
$variableName = 'value'
$response = Invoke-WebRequest -Uri 'https://jsonplaceholder.typicode.com/users'
$env:PATH += ';C:\foo'

# Print the value of the PATH environment variable.
$env:PATH
Write-Output $env:PATH
Write-Host $env:PATH

# Pipe the output of a command into another.
$users = $response | ConvertFrom-Json
$response | ConvertFrom-Json | Select-Object -Property username,email

# Access Objects' properties via dot-notation.
$users.id
(Invoke-WebRequest -Uri 'https://jsonplaceholder.typicode.com/users').Content

# Show selected Objects' properties.
$users | Select-Object -Property id,username,email
$users | select -Property id,username,email

# Show selected Objects' properties (expanded).
# Dot-notation automatically expands the output.
$users | Select-Object -Expand id,username,email
$users | select -Expand id,username,email

# Filter Objects' values.
$users | Where-Object -Property id -EQ 10
$users | where {$_.id -eq 10}
$users | where {($_.id -eq 10) -or ($_.id -lt 3)}

# Split a command on multiple lines.
Invoke-WebRequest `
  -Uri 'https://jsonplaceholder.typicode.com/users' `
  -UseBasicParsing `
| select -Expand Content `
| ConvertFrom-Json `
| Select-Object -Property id,username,email

# Filter out nodes name and their issues from K8S nodes' command output.
# Both contructions do the same operations and have the same output.
kubectl get nodes -o json `
| ConvertFrom-Json `
| Select-Object -ExpandProperty items `
| Select-Object -Property `
    @{l="Node";e={$_.metadata.name}},`
    @{l="Issues";e={$_.status.conditions `
      | Where-Object { ($_.status -ne "False") -and ($_.type -ne "Ready") } `
      | Select-Object -ExpandProperty type}}
(kubectl get nodes -o json | ConvertFrom-Json).items `
| select @{l="Node";e={$_.metadata.name}},@{l="Issues";e={`
    ($_.status.conditions | where {($_.status -ne "False") -and ($_.type -ne "Ready")}).type`
  }}
```

## Further readings

- [How to print environment variables to the console in PowerShell?]
- [Running PowerShell as Administrator with the Command Line]
- [Multiline Command]

## Sources

- [Working with JSON data in PowerShell]
- [JSON file to table]
- [Retrieve JSON object by field value]
- [Select-Object of multiple properties]
- [Multiple -and -or in PowerShell Where-Object statement]
- [Get started with OpenSSH for Windows]

<!-- microsoft's references -->
[get started with openssh for windows]: https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell

<!-- external references -->
[how to print environment variables to the console in powershell?]: https://stackoverflow.com/questions/50861082/how-to-print-environment-variables-to-the-console-in-powershell#50861113
[json file to table]: https://stackoverflow.com/questions/31415158/powershell-json-file-to-table#31415897
[multiline commands]: https://shellgeek.com/powershell-multiline-command/
[multiple -and -or in powershell where-object statement]: https://stackoverflow.com/questions/24682939/multiple-and-or-in-powershell-where-object-statement#24683254
[retrieve json object by field value]: https://stackoverflow.com/questions/16575419/powershell-retrieve-json-object-by-field-value#16580887
[running powershell as administrator with the command line]: https://adamtheautomator.com/powershell-run-as-administrator/
[select-object of multiple properties]: https://stackoverflow.com/questions/44142738/select-object-of-multiple-properties#44142777
[working with json data in powershell]: https://devblogs.microsoft.com/scripting/working-with-json-data-in-powershell/
