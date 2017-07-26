<#   
.SYNOPSIS   
<Estre script foi criado para encontrar o IPV4, Marca, Modelo , RAM, CPU, Numero de Serie, Utilizador Corrente e Estatísticas de Disco, de uma maquina através do seu nome. 
Também limpará o disco de ficheiros de lixo caso o utilizador o considere necessário e apresentará o espaço recuperado.>  
.DESCRIPTION 
<O Script através do nome da maquina irá pingar a maquina e depois irá recolher a informação da maquina e depois apresenta-a. A informação que este Script dará é:  
O nome do utilizador ligado na altura da verificação.  
O Nome do Fabricante.  
O Modelo da Maquina.  
O IPV4.
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
   IPv4  
   Numero de Serie  
   Nome do CPU  
   Nome do Sistema Operativo  
   Fabricante  
   Modelo  
   Utilizador currente  
   RAM  
   Tamanho de C e D  
   Espaço Ocupado e Livre de C e D
   Espaço Recuperado após a limpeza caso esta seja escolhida>  
.NOTES 
Version: 4  
Author: <João Aelxandre Garica Correia>  
Creation Date: <07/05/2017>  
Purpose/Change: Network Scouting and Remote Disk Cleaning 
#>  

function RDiskCleanCmd #disk cleaning script
{  
   #remote call of the cleaning script
   psexec \\$pcname "C:\Windows\System32\CleanPC.cmd"
   #second scan of disks and compatrison with the first
   $diskscan = Get-WmiObject Win32_logicaldisk -ComputerName $pcname
   $cnt = 0
   foreach ($dskobj in $diskscan) 
   {
      if ($dskobj.VolumeName -eq $null ) {}
      else 
      {
         Write-Host $dskobj.deviceid
         $max2 = $dskobj.Size/1024/1024/1024
         $free2 = $dskobj.FreeSpace/1024/1024/1024
         $full2 = $max2 - $free2
         $dif = $dskobj.FreeSpace - $recArray[$cnt]
         Write-Host "Espaço Total em Disco"$dskobj.deviceid":" ([math]::Round($max2, 2)) "GB"
         Write-Host "Espaço Ocupado em Disco"$dskobj.deviceid":" ([math]::Round($full2, 2)) "GB"
         Write-Host "Espaço Livre em Disco"$dskobj.deviceid":" ([math]::Round($free2, 2)) "GB"
         Write-Host "Recovered Space" ([math]::round($dif/1024/1024, 3)) "MB"
         $cnt++
      }
   } 
}
#end disk cleaning script

#Codigo central ao script
While (!$pcname) #se não tiver inserido nome
   {      
      $pcname = Read-Host -Prompt "Insira o nome do pc para obter informção"
   }   
$contest = Test-Connection -ComputerName $pcname -count 1 -Quiet #Teste para saber se o pc está ligado
if ($contest -eq 1 )  # se estiver recolhe o endereço de ip
   {   
      $iv4 = Test-Connection -ComputerName $pcname -count 1 -ErrorAction Stop| select-object IPV4Address #Recolha do IPv4 de $pcname
      Write-Host "IPv4: "$iv4.Ipv4address   
      Write-Host
   } 

if ($contest -eq 1 ) #se estiver ligado executa o script em si
{        
   Try {
         #Recolha de informação geral
         $colItems = Get-wmiobject -ErrorAction Stop -class Win32_ComputerSystem -namespace "root\CIMV2" -computername $pcname #Recolha de uma variadade de informação e deteção de erros com terminação de script caso exeções sejam encontradas
         $osname = Get-WmiObject -ComputerName $pcname -Class Win32_OperatingSystem | Select-Object caption  #Nome do Sistema Operativo 
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
         
         Write-Host
         Write-Host "Procurando discos..." #A recolha de informação de discos pode demorar
         Write-Host
         $diskspace = Get-WmiObject Win32_logicaldisk -ComputerName $pcname #Recolha de informação de disco
         $recArray = [System.Collections.ArrayList]@() #array para onde salvar $free para poder ser comparado mais tarde
         
         #Inicio display de dados de disco
         foreach ($dskitem in $diskspace) 
         {
            if ($dskitem.VolumeName -eq $null ) {}
            else {
                    Write-Host $dskitem.deviceid
                     $max = $dskitem.Size/1024/1024/1024   
                     $free = $dskitem.FreeSpace/1024/1024/1024
                     $pass = $dskitem.FreeSpace
                     $recArray.Add($pass)
                     $full = $max - $free    
                     Write-Host "Espaço Total em Disco"$dskitem.deviceid":" ([math]::Round($max, 2))"GB"
                     Write-Host "Espaço Ocupado em Disco"$dskitem.deviceid":" ([math]::Round($full, 2))"GB"
                     Write-Host "Espaço Livre em Disco"$dskitem.deviceid":" ([math]::Round($free, 2))"GB"
                     Write-Host 
                    }
           } 

         #Prompt de limpeza
         $op = Read-Host -Prompt "Deseja Fazer a limpeza remota de disco (S/N or Y/N)"  
         if ($op -ne $null -Or "n") #Se não introduzir vazio ou n (N)
         {
            switch ($yn) #para funcionar um y ou s (pt/en)
            {
               "y"{RDiskCleanCmd}
               "s"{RDiskCleanCmd}
            }
         }
         else {}
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
