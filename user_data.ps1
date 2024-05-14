<powershell>
##############################################################
### Configure azure instance and install required software ### 
##############################################################
$transcriptDate = (Get-Date -Format "MM-dd-yyyy--HH-mm-ss")
Start-Transcript -Path "C:\log-$transcriptDate.txt" -NoClobber

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force

Set-ExecutionPolicy Bypass -Scope Process -Force

#Install choco
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install gitlab-runner /Service  -y 

# Registrar runner
$Env:RUNNER_NAME                = "DevopsTraining"
$Env:REGISTRATION_TOKEN         = 'GR1348941sHnLsCqMyx4RLGwsL7Cs' #Use projects token here
$Env:CI_SERVER_URL              = 'https://gitlab.com/'
$Env:RUNNER_TAG_LIST            = 'Devops'        #comma separated list of tags

#$Env:CONFIG_FILE                = "$PSScriptRoot\config.toml"
$Env:REGISTER_RUN_UNTAGGED      = 'false'
$Env:REGISTER_LOCKED            = $false    #lock runner to current project 
$Env:RUNNER_EXECUTOR            = 'shell'
$Env:RUNNER_SHELL               = 'powershell'

$Env:RUNNER_REQUEST_CONCURRENCY = 1
$Env:RUNNER_BUILDS_DIR          = ''
$Env:RUNNER_CACHE_DIR           = ''

gitlab-runner register --non-interactive

Stop-Transcript
<powershell>