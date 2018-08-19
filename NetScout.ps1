<#   
.SYNOPSIS   
<Estre script foi criado para encontrar o IPV4, Marca, Modelo , RAM, CPU, Numero de Serie, Utilizador Corrente e Estatísticas de Disco, de uma maquina através do seu nome. 
Também limpará o disco de ficheiros de lixo caso o utilizador o considere necessário e apresentará o espaço recuperado.>  
.DESCRIPTION 
<O Script através do nome da maquina irá pingar a maquina e depois irá recolher a informação da maquina e depois apresenta-a. A informação que este Script dará é:  
   O nome do utilizador ligado na altura da verificação.  
   O Nome do Fabricante.  
   O Modelo da Maquina.  
   O IPv4
   O IPv6
   O Enderesso MAC
   O Gateway
   O Dispositivo que está a conectar à internet
   O Nome do CPU.
   O Nome do Sistema Operativo.
   O Numero de Serie.
   O Utilizador Currente.
   O Tamanho dos discos C e D.
   O Espaço Ocupado dos discos C e D.
   O Espaço Livre dos discos C e D.
   Após isso ele dará ao utilizador a escolha de correr uma função de limpeza baseada num script por Nuno Almeida.
E apresentará o espaço Recupeado pelo script de limpeza.>  
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
   Utilizador currente  
   RAM  
   Tamanho dos discos
   Espaço Ocupado e Livre dos discos em questão
   Espaço Recuperado após a limpeza caso esta seja escolhida>  
.NOTES 
Version: 7  
Author: <João Aelxandre Garica Correia>  
Creation Date: <07/05/2017>  
Purpose/Change: Network Scouting and Remote Disk Cleaning 
#>  

########################################################
# Header Functions
########################################################
<#
Scans Disks
Arguments: PcName
Outpupt: Array of Hashtables
Keys: ID (C:, D: etc.), Name (OS, DATA, etc.), TotalSpace (in GB), FreeSpace (in GB), OcupiedSpace (in GB)
NOTE: Numbers come in full so they may need to be formated, but that is done outside the function.
#>
function DiskScan ([String] $name) 
{   
    # Create dynamic sized array (Array.List more acurally) [since static wouldn't permit Add()]
    $out = [System.Collections.ArrayList]@()
    # Get the information of all drives
    $disklist = Get-WmiObject Win32_logicaldisk -ComputerName $name
        foreach ($disk in $disklist)
        {
            
            # I am only interested in disk/data drives (DriveType 3), as such it will catch usb, I'm ok with that
            if($disk.DriveType -eq 3 ) 
            {
                $max = $disk.Size/1024/1024/1024
                $free = $disk.FreeSpace/1024/1024/1024
                $full = $max - $free
                # Formating the processed data in a hashtable
                $obj = @{ 
                        ID = $disk.deviceid
                        Name = $disk.VolumeName
                        TotalSpace = $max
                        FreeSpace = $free
                        FullSpace = $full }
                
                # Redirecting array index output of Array.Add() to Null (aka, ignoring it), it still adds the entry to the list        
                $null = $out.Add($obj)
            } 
        }
    return $out
}

<#
Compares two scans of diferent times and retuns the diferences of them
Arguments: 1st scan, 2nd scan
Output: Array of Hashtables
Keys: ID(C:, D: etc.), The size in MB of the difernece (this reflects gained space)
NOTE: Numbers come in full so they may need to be formated, but that is done outside the function.
#>
function CompareDisks ([System.Collections.ArrayList] $scan1, [System.Collections.ArrayList] $scan2)
{
    # Filters out uncessary information, could be done with map but powershell doesn't have it
    function Shape([System.Collections.ArrayList] $scan)
    {
        $out = [System.Collections.ArrayList]@()
        foreach($disk in $scan)
        {
            $obj = @{ 
                    ID = $disk.ID
                    FullSpace = $disk.FullSpace }

            $null = $out.Add($obj)
        }
        return $out
    }

    $scan1 = Shape $disk1 
    $scan2 = Shape $disk2  
    $out = [System.Collections.ArrayList]@()
    for ($cnt = 0; $cnt -lt $before.Count; $cnt++)
    {
        $obj = @{ 
                ID = $before[$cnt].ID
                Diference = (($scan1[$cnt].FullSpace - $scan2[$cnt].FullSpace)*1024) }
        $null = $out.Add($obj)
    }
    return $out
}
<#
Disk cleaning script
Calls psexec
No arguments
Need to find a non 3rd party dependent method
#>
function RDiskClean($target)
{  
   # Remote call of the cleaning script
   psexec \\$target "C:\Windows\System32\CleanPC.cmd"
}

<#
Fetches network device information
Argument: Pc Name
Outpupt: A Hashtable
Keys: Description, IPv4, IPv6, MAC(address), Gateway
#>
function GetNet ([string] $name)
{
    # $outarray = [System.Collections.ArrayList]@() -> outarray is not necessary, remove declaration
    $eth0 = Get-WmiObject win32_networkadapterconfiguration -ComputerName $name 
    foreach ($ethobj in $eth0)
    {
        if ($ethobj.DHCPEnabled -eq "True"-and $ethobj.IPAddress -ne $null)
        {
            return @{
                    Description = $ethobj.Description
                    MAC = $ethobj.MACAddress
                    Gateway = $ethobj.DefaultIPGateway
                    IPv4 = $ethobj.IPAddress[0]
                    IPv6 = Try {$ethobj.IPAddress[1] } catch {return $null} }
        }
    }
}

function GetUser([String] $name)
{
    $UserAccountsList = Get-WmiObject Win32_UserAccount
    foreach ($user in $UserAccountsList)
    {
        if ($user.FullName -ne "")
        {
            return $user.name
        }
    }
}

########################################################
# Header Functions End
########################################################

# Codigo central ao script

# Se não tiver inserido nome
While (!$pcname) { $pcname = Read-Host -Prompt "Insira o nome do pc para obter informção" }   

#Teste para saber se o pc está ligado ([Bool]$contest)
$contest = Test-Connection -ComputerName $pcname -count 1 -Quiet 
if ($contest -eq 1 )  
{   
    $net = GetNet $pcname 
    Write-Host "`nNome de placa de rede: "$net.Description
    Write-Host "IPv4: "$net.IPv4
    Write-Host "IPv6: "$net.IPv6
    Write-Host "MAC: "$net.MAC
    Write-Host "Gateway: "$net.Gateway    
} 

if ($contest -eq 1 ) # Se estiver ligado executa o script em si
{        
   Try 
   {
        Write-Host "`nProcurando Informação...`n"  # A recolha de tanta informação demora

        # Recolha de informação geral
        $colItems = Get-Wmiobject Win32_ComputerSystem -computername $pcname -ErrorAction Stop          #Recolha de uma variadade de informação e deteção de erros com terminação de script caso exeções sejam encontradas
        $osname = Get-WmiObject Win32_OperatingSystem -ComputerName $pcname | Select-Object caption     # Nome do Sistema Operativo
        $cpuname = Get-WmiObject Win32_processor -ComputerName $pcname | Select-Object name             # Nome CPU   
        $serial = Get-WmiObject win32_bios -ComputerName $pcname | Select-Object SerialNumber           # Numero de serie 
        $displayGB = [math]::round($colItems.TotalPhysicalMemory/1024/1024/1024, 0)                     #Formatação de RAM para GB
        $username = GetUser $pcname

        # Inicio de display de resultados gerais 
        Write-Host "Fabricante: " $colItems.Manufacturer   # Nome de Fabricante     
        write-host "Modelo: " $colItems.Model              # Nome de Modelo 
        Write-Host "Numero de Serie:" $serianl.SerialNumber # Numero de Serie  
        Write-Host "CPU: " $cpuname.name                   # Nome do CPU output
        write-host "RAM: " $displayGB "GB"                 # RAM em GB output
        Write-Host "OS: " $osname.caption                  # Sistema Operativo output
        Write-Host "Username: " $username                  # Nome de utilizador   
        # Fim do display de resultados gerais

        $before = DiskScan $pcname
        # Parsing the object array
        foreach ($disk in $before)
        {
            Write-Host "Disco: " $disk.ID
            Write-Host "Espaço Total: " ([math]::Round($disk.TotalSpace, 2)) "GB"
            Write-Host "Espaço Ocupado: " ([math]::Round($disk.FullSpace, 2)) "GB"
            Write-Host "Espaço Livre"  ([math]::Round($disk.FreeSpace, 2)) "GB" `n
        }
        # Prompt de limpeza
        $op = Read-Host -Prompt "Deseja Fazer a limpeza remota de disco (S/N or Y/N)"  
        if ( ($op -eq "y") -or ($op -eq "s")) 
        {
            RDiskClean $pcname                        # Clean Disks
            $after = DiskScan $pcname                 # Post cleaning scan
            $comparison = CompareDisks $before $after #Comparting scans
            # Seeing how much space has been recovered
            foreach ($disk in $comparison)
            {
                Write-host "ID: " $disk.ID
                Write-Host "Diference = " ([math]::Round($disk.Diference, 2)) "MB" `n
            }
        }
            
    } # Fim de Try

    # Exeções
    catch [System.Runtime.InteropServices.COMException] { Write-Host "Servidor RPC não disponivel" }
    catch [System.Net.NetworkInformation.PingException] { Write-Host "Servidor RPC não disponivel" }
    Catch [System.UnauthorizedAccessException] { Write-Host "Acesso Negado à recolha de informação do PC"}   
    # Limpeza de variavéis
    Finally 
    { 
        try { Remove-Variable -ErrorAction Stop pcname , colItems , osname , cpuname , serial , before, after, comparison, yn } 
        # Limpeza de variavéis (imperativo a limpesa de $pcname, se não na proxima execução ele vai reconhecer a entrada prévia)
        catch [System.Management.Automation.ItemNotFoundException] {} #para caso a variavel não esteja iniciada ele não quebre o script
    }
} # Fim de If
# Caso o pc não esteja ligado
Else 
{ 
    Write-Host "Computador desligado ou não existente"
    try { Remove-Variable -ErrorAction Stop pcname , contest }
    catch [System.Management.Automation.ItemNotFoundException] {} 
}