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
Version: 6  
Author: <João Aelxandre Garica Correia>  
Creation Date: <07/05/2017>  
Purpose/Change: Network Scouting and Remote Disk Cleaning 
#>  

########################################################
# Header Functions
########################################################
<#
Scans disk
Arguments: Empty Array ($var = [System.Collections.ArrayList]@() ), PcName
Output: To screen (needs fix)
#>
function RDiskScan([System.Collections.ArrayList] $array, [String] $name)
{
    $diskscan = Get-WmiObject Win32_logicaldisk -ComputerName $name
    $cnt = 0
    if($array[0] -eq $null) {$rw = "w"} else {$rw = "r"}
        foreach ($diskobj in $diskscan)
        {
            if($diskobj.DriveType -eq 3) 
            {
                Write-Host $diskobj.deviceid
                $max2 = $diskobj.Size/1024/1024/1024
                $free2 = $diskobj.FreeSpace/1024/1024/1024
                $full2 = $max2 - $free2
                if ($rw -eq "w")
                {
                    $null = $array.Add($diskobj.FreeSpace)
                }
                else
                {
                    $dif = $diskobj.FreeSpace - $array[$cnt]
                }
                Write-Host "Espaço Total em Disco"$diskobj.deviceid":" ([math]::Round($max2, 2)) "GB"
                Write-Host "Espaço Ocupado em Disco"$diskobj.deviceid":" ([math]::Round($full2, 2)) "GB"
                Write-Host "Espaço Livre em Disco"$diskobj.deviceid":" ([math]::Round($free2, 2)) "GB"
                if ($rw -eq "r")
                {
                    Write-Host "Recovered Space" ([math]::round($dif/1024/1024, 3)) "MB"
                    $cnt++
                }
            }
        }
}

#Disk cleaning script
#Calls psexec and RDiskScan
#No arguments
function RDiskClean 
{  
   #remote call of the cleaning script
   #psexec \\$pcname "C:\Windows\System32\CleanPC.cmd"
   RDiskScan $recArray $pcname
}

#Fetches network device information
#Argument: Pc Name
#Outpupt: Array of objects
#Properties: Description, IPv4, IPv6, MAC(address), Gateway
function GetNet ([string] $name)
{
    # $outarray = [System.Collections.ArrayList]@() -> outarray is not necessary, remove declaration
    $eth0 = Get-WmiObject win32_networkadapterconfiguration -ComputerName $name 
    foreach ($ethobj in $eth0)
    {
        if ($ethobj.DHCPEnabled -eq "True"-and $ethobj.IPAddress -ne $null)
        {
             $pass = @{
             Description = $ethobj.Description
             MAC = $ethobj.MACAddress
             Gateway = $ethobj.DefaultIPGateway
             IPv4 = $ethobj.IPAddress[0]
             IPv6 = Try {$ethobj.IPAddress[1] } catch {return $null}
             }
             $out = New-Object psobject -Property $pass
             # $outarray.Add($out) - > Unessesary, there is one object out of the $eth0 array worth getting.
        }
    }
    return $out # old name: $outarray
}
########################################################
# Header Functions End
########################################################

#Codigo central ao script
While (!$pcname) #se não tiver inserido nome
   {      
      $pcname = Read-Host -Prompt "Insira o nome do pc para obter informção"
   }   
$contest = Test-Connection -ComputerName $pcname -count 1 -Quiet #Teste para saber se o pc está ligado
if ($contest -eq 1 )  # se estiver recolhe o endereço de ip
   {   
      $net = GetNet $pcname 
      Write-Host "`nNome de placa de rede: "$net.Description
      Write-Host "IPv4: "$net.IPv4
      Write-Host "IPv6: "$net.IPv6
      Write-Host "MAC: "$net.MAC
      Write-Host "Gateway: "$net.Gateway  
   } 

if ($contest -eq 1 ) #se estiver ligado executa o script em si
{        
   Try {
         #Recolha de informação geral
         $colItems = Get-wmiobject Win32_ComputerSystem -computername $pcname -ErrorAction Stop #Recolha de uma variadade de informação e deteção de erros com terminação de script caso exeções sejam encontradas
         $osname = Get-WmiObject Win32_OperatingSystem -ComputerName $pcname | Select-Object caption  #Nome do Sistema Operativo
         $cpuname = Get-WmiObject Win32_processor -ComputerName $pcname | Select-Object name #Nome CPU   
         $serial = Get-WmiObject win32_bios -ComputerName $pcname | Select-Object SerialNumber  #numero de serie 
         $displayGB = [math]::round($colItems.TotalPhysicalMemory/1024/1024/1024, 0) #Formatação de RAM para GB
         
         #Inicio de display de resultados gerais 
         Write-Host "Fabricante: " $colItems.Manufacturer #Nome de Fabricante     
         write-host "Modelo: " $colItems.Model #Nome de Modelo 
         Write-Host "Numero de Serie:" $serial.SerialNumber    
         Write-Host "CPU: " $cpuname.name  #Nome do CPU output
         write-host "RAM: " $displayGB "GB"  #RAM em GB output
         Write-Host "OS: " $osname.caption #Sistema Operativo output
         Write-Host "Username: " $colItems.UserName #Nome de utilizador   
         #fim do display de resultados gerais
         
         Write-Host "`nProcurando discos...`n" #A recolha de informação de discos pode demorar

         $recArray = [System.Collections.ArrayList]@() #array para onde salvar $free para poder ser comparado mais tarde
         RDiskScan $recArray $pcname

         #Prompt de limpeza
         $op = Read-Host -Prompt "Deseja Fazer a limpeza remota de disco (S/N or Y/N)"  
         if ($op -ne $null -Or "n") #Se não introduzir vazio ou n (N)
         {
            switch ($op) #para funcionar um y ou s (pt/en)
            { 
               "y" {RDiskClean}
               "s" {RDiskClean}
            }
         }
         
   } #Fim de Try
   
   #Exeções
   catch [System.Runtime.InteropServices.COMException] { Write-Host "Servidor RPC não disponivel" }
   catch [System.Net.NetworkInformation.PingException] { Write-Host "Servidor RPC não disponivel" }
   Catch [System.UnauthorizedAccessException] { Write-Host "Acesso Negado à recolha de informação do PC"}   
   #limpeza de variaveis
   Finally 
      { 
         try 
            { 
               Remove-Variable -ErrorAction Stop pcname , colItems , osname , cpuname , serial , diskspace, recArray, yn
            } #Limpeza de variavéis (imperativo a limpesa de $pcname, pois o script verifica no inicio se a variavel é nula, não apagar a variavel fará o resto dos script executar com a introdução prévia)
         catch [System.Management.Automation.ItemNotFoundException] {} #para caso a variavel não esteja iniciada ele não quebre o script
        }
} #Fim de If
Else #Caso o pc não esteja ligado
   { 
      Write-Host "Computador desligado ou não existente"
      try 
         { 
            Remove-Variable -ErrorAction Stop pcname , contest
         }
      catch [System.Management.Automation.ItemNotFoundException] {} 
      }
#Fim
