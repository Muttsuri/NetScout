<#   
.SYNOPSIS   
<Este script foi criado para encontrar o IPV4, Marca, Modelo , RAM, CPU, Numero de Serie, Utilizador Corrente e Estatísticas de Disco, de uma maquina através do seu nome. 
Também limpará o disco de ficheiros de lixo caso o utilizador o considere necessário e apresentará o espaço recuperado.>  
.DESCRIPTION 
<O Script através do nome da maquina irá pingar a maquina e depois irá recolher a informação da maquina e depois apresenta-a. A informação que este Script dará é:  
   O nome do utilizador ligado na altura da verificação.  
   O Nome do Fabricante.  
   O Modelo da Maquina.  
   O IPv4
   O IPv6
   O Endereço MAC
   O Gateway
   O Dispositivo que está a conectar à internet
   O Nome do CPU.
   O Nome do Sistema Operativo.
   O Numero de Serie.
   O Utilizador Corrente.
   O Tamanho dos discos C e D.
   O Espaço Ocupado dos discos C e D.
   O Espaço Livre dos discos C e D.
   Após isso ele dará ao utilizador a escolha de correr uma função de limpeza baseada num script por Nuno Almeida.
E apresentará o espaço Recuperado pelo script de limpeza.>  
.PARAMATER
<Nome do PC>  
.INPUTS 
<Nome do pc que será perguntado pelo script. Este script não tem argumentos>  
.OUTPUTS
<Output aparece na consola:   
   IPv4, IPv6, MAC, Gateway, Dispositivo de internet a ser usado  
   Numero de Serie  
   Nome do CPU  
   Nome do Sistema Operativo  
   Fabricante  
   Modelo  
   Utilizador corrente
   RAM  
   Tamanho dos discos
   Espaço Ocupado e Livre dos discos em questão
   Espaço Recuperado após a limpeza caso esta seja escolhida>  
.NOTES 
Version: 7  
Author: <João Alexandre Garcia Correia>  
Creation Date: <07/05/2017>  
Purpose/Change: Network Scouting and Remote Disk Cleaning 
#>  

########################################################
# Header Functions
########################################################
<#
Scans Disks
Output: Array of Hashtables
Keys: ID (C:, D: etc.), Name (OS, DATA, etc.), TotalSpace (in GB), FreeSpace (in GB), OcupiedSpace (in GB)
NOTE: Numbers come in full so they may need to be formated, but that is done outside the function.
#>
function DiskScan () {

    # Create dynamic array (ArrayList)
    $out = [System.Collections.ArrayList]@()

    # Get logical disks via CIM
    $disklist = Get-CimInstance -ClassName Win32_LogicalDisk -CimSession $global:cim_session

    foreach ($disk in $disklist) {

        # Only fixed disks (DriveType 3)
        if ($disk.DriveType -eq 3) {

            $max = $disk.Size / 1GB
            $free = $disk.FreeSpace / 1GB
            $full = $max - $free

            # Build hashtable object
            $obj = @{
                ID         = $disk.DeviceID
                Name       = $disk.VolumeName
                TotalSpace = $max
                FreeSpace  = $free
                FullSpace  = $full
            }

            # Add to ArrayList
            $null = $out.Add($obj)
        }
    }

    return $out
}

<#
Compares two scans of different times and returns the diferences of them
Arguments: 1st scan, 2nd scan
Output: Array of Hashtables
Keys: ID(C:, D: etc.), The size in MB of the diference (this reflects gained space)
NOTE: Numbers come in full so they may need to be formated, but that is done outside the function.
#>
function CompareDisks ([System.Collections.ArrayList] $before, [System.Collections.ArrayList] $after) {
    # Filters out unnecessary information, could be done with map but powershell doesn't have it
    function Shape([System.Collections.ArrayList] $scan) {
        $out = [System.Collections.ArrayList]@()
        foreach ($disk in $scan) {
            $obj = @{ 
                ID        = $disk.ID
                FullSpace = $disk.FullSpace 
            }

            $null = $out.Add($obj)
        }
        return $out
    }

    $scan1 = Shape $before 
    $scan2 = Shape $after 
    $out = [System.Collections.ArrayList]@()
    for ($cnt = 0; $cnt -lt $before.Count; $cnt++) {
        $obj = @{ 
            ID        = $before[$cnt].ID
            Diference = (($scan1[$cnt].FullSpace - $scan2[$cnt].FullSpace) * 1024) 
        }
        $null = $out.Add($obj)
    }
    return $out
}
<#
Disk cleaning script
Calls: psexec
No arguments
Return: Bool 
Description: $true = succcess; $false = falure (normaly missing psexec)
Need to find a non 3rd party dependent method
#>
function RDiskClean($target) {

    # Check PsExec is available
    if (-not (Get-Command psexec.exe -ErrorAction SilentlyContinue)) {
        Write-Error "PsExec not found in PATH. Please install Sysinternals PsExec and ensure it is in your system PATH."
        return $false
    }

    # Run remote script
    psexec \\$target "C:\Windows\System32\CleanPC.cmd"
 
    # Check exit code from remote script
    if ($LASTEXITCODE -eq 0) {
        return $true
    }
    else {
        return $false
    }
}


<#
Fetches network device information
Output: A Hashtable
Keys: Description, IPv4, IPv6, MAC(address), Gateway
#>
function GetNet () {

    # Get only active network adapters with IP enabled
    $cfgList = Get-CimInstance Win32_NetworkAdapterConfiguration `
        -CimSession $global:cim_session `
        -Filter "IPEnabled = True"

    # Get adapter metadata (MAC, physical info)
    $nicList = Get-CimInstance Win32_NetworkAdapter -CimSession $global:cim_session
    Write-Debug "Found $($nicList.Count) network adapters and $($cfgList.Count) configurations."
    foreach ($cfg in $cfgList) {

        # Match configuration to adapter by Index
        $nic = $nicList | Where-Object { $_.Index -eq $cfg.Index }

        if ($cfg.DHCPEnabled -and
            $null -ne $cfg.IPAddress -and
            $null -ne $cfg.DNSDomain) {

            return @{
                Description = $cfg.Description
                MAC         = $nic.MACAddress
                Gateway     = $cfg.DefaultIPGateway
                IPv4        = $cfg.IPAddress[0]
                IPv6        = if ($cfg.IPAddress.Count -gt 1) { $cfg.IPAddress[1] } else { $null }
            }
        }
    }
}


function GetUser() {
    $UserAccountsList = Get-CimInstance -class Win32_UserAccount -CimSession $global:cim_session

    foreach ($user in $UserAccountsList) {
        if ($user.FullName -ne "") {
            return $user.name
        }
    }
}

<#
Initiates CIM Session
Argument: Pc Name
Output: Bool
Description: Success = $true, Failure = $false
#>
function Global_CimSessionInit([String] $pcname) {
    try {
        # DOCOM is more compatible because of course new standards don't implement half the stuff
        $global:cim_session = New-CimSession -ComputerName $pcname -SessionOption (New-CimSessionOption -Protocol "Dcom") -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to create CIM session to $pcname :\n $($PSItem.Exception.Message)"
        return $false
    }
    
    if (-not $global:cim_session) {
        Write-Error "CIM session object is null — creation failed."
        return $false
    }
    return $true
}

function Global_CimSessionClose() {
    Remove-CimSession -CimSession $global:cim_session
    try { Remove-Variable -ErrorAction Stop global:cim_session } 
    catch [System.Management.Automation.ItemNotFoundException] {}
}

function VariableCleanup() {
    try { Remove-Variable -ErrorAction Stop pcname , colItems , osname , cpuname , serial , before, after, comparison, yn } 
    # Limpeza de variavéis (imperativo a limpesa de $pcname, se não na proxima execução ele vai reconhecer a entrada prévia)
    catch [System.Management.Automation.ItemNotFoundException] {} #para caso a variavel não esteja iniciada ele não quebre o script
}

########################################################
# Header Functions End
########################################################

# Codigo central ao script
function main() {
    # Se não tiver inserido nome
    While (!$pcname) { $pcname = Read-Host -Prompt "Insira o nome do pc para obter informação" }   

    
    #Teste para saber se o pc está ligado ([Bool]$contest)
    $contest = Test-Connection -ComputerName $pcname -count 1 -Quiet 
    if ($contest) {
        $net = GetNet 
        Write-Host "`nNome de placa de rede: "$net.Description
        Write-Host "IPv4: "$net.IPv4
        Write-Host "IPv6: "$net.IPv6
        Write-Host "MAC: "$net.MAC
        Write-Host "Gateway: "$net.Gateway
    } 

    # Init CIM Session and check
    if (!(Global_CimSessionInit $pcname)) {
        return 
    }
    # Caso o pc não esteja ligado
    if (!$contest) {
        Write-Host "Computador desligado ou não existente"
        try { Remove-Variable -ErrorAction Stop pcname, contest }
        catch [System.Management.Automation.ItemNotFoundException] {} 
    }
    
    # Se estiver ligado executa o script em si        
    Try {
        Write-Host "`nProcurando Informação...`n"  # A recolha de tanta informação demora

        # Recolha de informação geral
        # Recolha de uma variedade de informação e deteção de erros com terminação de script caso exceções sejam encontradas
        $colItems = Get-CimInstance Win32_ComputerSystem -CimSession $global:cim_session -ErrorAction Stop
        # Nome CPU   
        $osname = Get-CimInstance Win32_OperatingSystem -CimSession $global:cim_session | Select-Object -ExpandProperty Caption
        # Nome do Sistema Operativo
        $cpuname = Get-CimInstance Win32_Processor -CimSession $global:cim_session | Select-Object -ExpandProperty Name
        # Numero de serie 
        $serial = Get-CimInstance Win32_BIOS -CimSession $global:cim_session | Select-Object -ExpandProperty SerialNumber

        $displayGB = [math]::round($colItems.TotalPhysicalMemory / 1024 / 1024 / 1024, 0)                     #Formatação de RAM para GB
        $username = GetUser $pcname

        # Inicio de display de resultados gerais 
        Write-Host "Fabricante: " $colItems.Manufacturer   # Nome de Fabricante     
        write-host "Modelo: " $colItems.Model              # Nome de Modelo 
        Write-Host "Numero de Serie:" $serial.SerialNumber # Numero de Serie  
        Write-Host "CPU: " $cpuname.name                   # Nome do CPU output
        write-host "RAM: " $displayGB "GB"                 # RAM em GB output
        Write-Host "OS: " $osname.caption                  # Sistema Operativo output
        Write-Host "Username: " $username                  # Nome de utilizador   
        # Fim do display de resultados gerais

        $before = DiskScan $pcname
        # Parsing the object array
        foreach ($disk in $before) {
            Write-Host "Disco: " $disk.ID
            Write-Host "Espaço Total: " ([math]::Round($disk.TotalSpace, 2)) "GB"
            Write-Host "Espaço Ocupado: " ([math]::Round($disk.FullSpace, 2)) "GB"
            Write-Host "Espaço Livre"  ([math]::Round($disk.FreeSpace, 2)) "GB" `n
        }
        # Prompt de limpeza
        $op = Read-Host -Prompt "Deseja Fazer a limpeza remota de disco (S/N or Y/N)"  
        if ( ($op -eq "y") -or ($op -eq "s")) {
            RDiskClean $pcname                        # Clean Disks
            $after = DiskScan $pcname                 # Post cleaning scan
            $comparison = CompareDisks $before $after #Comparting scans
            # Seeing how much space has been recovered
            foreach ($disk in $comparison) {
                Write-host "ID: " $disk.ID
                Write-Host "Diference = " ([math]::Round($disk.Diference, 2)) "MB" `n
            }
        }
            
    } # Fim de Try

    # Exeções
    catch [System.Runtime.InteropServices.COMException] { Write-Host "Servidor RPC não disponivel" }
    catch [System.Net.NetworkInformation.PingException] { Write-Host "Servidor RPC não disponivel" }
    Catch [System.UnauthorizedAccessException] { Write-Host "Acesso Negado à recolha de informação do PC" }   
    # Limpeza de variaveis
    Finally { 
        VariableCleanup 
    }
}

# Perfiro chamar a função em vez de ter o código solto.
main 