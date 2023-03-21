Import-Module -Name NetAdapter
Import-Module -Name NetTCPIP

function ConvertFromIPToINT64(){ 
  param ($ip) 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 

function ConvertFromINT64ToIP(){ 
  param ([int64]$int) 
  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 

function Get-IPrange(){
  <# 
    .SYNOPSIS  
      Get the IP addresses in a range 
    .EXAMPLE 
    Get-IPrange -start 192.168.8.2 -end 192.168.8.20
  #>
  param( 
    [string]$start, 
    [string]$end
  ) 
  
  if ($ip) { 
    $startaddr = ConvertFromIPToINT64 -ip $networkaddr.ipaddresstostring 
    $endaddr = ConvertFromIPToINT64 -ip $broadcastaddr.ipaddresstostring 
  } else { 
    $startaddr = ConvertFromIPToINT64 -ip $start 
    $endaddr = ConvertFromIPToINT64 -ip $end 
  } 
  
  
  for ($i = $startaddr; $i -le $endaddr; $i++) { 
    ConvertFromINT64ToIP -int $i 
  }
}

function Get-PrimaryIPv4Information(){
  [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$t,

        [Parameter()]
        [switch]$a
    )
  if ($a){
    $NicObjects = Get-NetIPAddress | Where-Object {
      ($_.PrefixLength -lt 64)
    } | Select-Object InterfaceIndex,InterfaceAlias,MacAddress,IPv4Address,PrefixLength,SubnetMask,IPv4DefaultGateway,IPNetwork,SuffixOrigin,AddressState,FirstHost,LastHost

    $Alt2NicObjects = Get-NetIPConfiguration
    $Alt3NicObjects = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
      Where-Object { ($_.OperationalStatus -eq 'Up')}
  }
  else {
    $NicObjects = Get-NetIPAddress | Where-Object {
        ($_.InterfaceAlias -notlike 'vEthernet*') -and 
        ($_.InterfaceAlias -notlike 'Loopback*') -and
        ($_.InterfaceAlias -notlike 'Npcap*') -and
        ($_.InterfaceAlias -notlike 'Local Area Connection*') -and
        ($_.PrefixLength -lt 64)
    } | Select-Object InterfaceIndex,InterfaceAlias,MacAddress,IPv4Address,PrefixLength,SubnetMask,IPv4DefaultGateway,IPNetwork,SuffixOrigin,AddressState,FirstHost,LastHost

    $Alt2NicObjects = Get-NetIPConfiguration
    $Alt3NicObjects = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
    Where-Object { ($_.OperationalStatus -eq 'Up') -and
            ($_.Name -notlike '*vEthernet*') -and
            ($_.Name -notlike '*Loopback*') -and
            ($_.Name -notlike '*Npcap*') -and
            ($_.Name -notlike '*Local Area Connection*')}
  }
  
  Foreach ($Alt3NicObject in $Alt3NicObjects){
    [System.Net.NetworkInformation.IPInterfaceProperties] $adapterProperties  = $Alt3NicObject.GetIPProperties()
    Foreach ($NicObject in $NicObjects){
      Foreach ($unicastAddress in $adapterProperties.UnicastAddresses){
        if (($unicastAddress.PrefixLength -lt 64) -and ($unicastAddress.Address.IPAddressToString -eq $NicObject.IPv4Address)){
          #Obtain Subnet Mask
          $SubnetMask = $unicastAddress.IPv4Mask.IPAddressToString
          $NicObject.SubnetMask = $SubnetMask
          $SubnetMaskIP = [Net.IPAddress]::Parse($NicObject.SubnetMask)
          #Obtain IPv4 IP Address
          $IPAddress = $NicObject.IPv4Address
          $IPAddressArray = $IPAddress -split '\.' | Foreach-Object{[System.Convert]::ToString($_)}
          $SubnetMaskArray = $SubnetMask -split '\.' | Foreach-Object{[System.Convert]::ToString($_)}
          #Calculate IP Network
          $IPNetwork = '0','0','0','0'
          Foreach ($IPAOctet in $IPAddressArray){
            $i = $IPAddressArray.IndexOf($IPAOctet)
            $IPNetwork[$i] = ($IPAOctet -band $SubnetMaskArray[$i])
          }
          $NicObject.IPNetwork = $IPNetwork -join '.' | Write-Output
          $IPNetworkIP = [Net.IPAddress]::Parse($NicObject.IPNetwork)
          #Calculate First Host in Subnet
          $FirstHostOctetsI64Array = $IPNetwork | Foreach-Object{[System.Convert]::ToInt64($_)}
          #$FirstHostOctetsArray | Write-Host
          if($NicObject.PrefixLength -ne 32){
            $FirstHostI64 = [int64]([int64]$FirstHostOctetsI64Array[0]*16777216 +
                                    [int64]$FirstHostOctetsI64Array[1]*65536 +
                                    [int64]$FirstHostOctetsI64Array[2]*256 +
                                    ([int64]$FirstHostOctetsI64Array[3]+1))
          }
          else {
            $FirstHostI64 = [int64]([int64]$FirstHostOctetsI64Array[0]*16777216 +
                                    [int64]$FirstHostOctetsI64Array[1]*65536 +
                                    [int64]$FirstHostOctetsI64Array[2]*256 +
                                    ([int64]$FirstHostOctetsI64Array[3]))
          }             
          $FirstHostIP = ConvertFromINT64ToIP($FirstHostI64)
          $NicObject.FirstHost = $FirstHostIP | Write-Output
          #Calculate Last Host in Subnet
          $NetworkBroadcastIPv4Address = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $SubnetMaskIP.address -bor $IPNetworkIP.address))
          $NetworkBroadcastIPv4AddressString = [System.Convert]::ToString($NetworkBroadcastIPv4Address)
          $LastHostOctetsArray = $NetworkBroadcastIPv4AddressString -split "\." | Foreach-Object{[System.Convert]::ToInt64($_)}
          if($NicObject.PrefixLength -ne 32){
            $LastHostI64 = [int64]([int64]$LastHostOctetsArray[0]*16777216 +
                            [int64]$LastHostOctetsArray[1]*65536 +
                            [int64]$LastHostOctetsArray[2]*256 +
                            ([int64]$LastHostOctetsArray[3]-1))
          }
          else {
            $LastHostI64 = [int64]([int64]$LastHostOctetsArray[0]*16777216 +
                            [int64]$LastHostOctetsArray[1]*65536 +
                            [int64]$LastHostOctetsArray[2]*256 +
                            ([int64]$LastHostOctetsArray[3]))
          }            
          $LastHostIP = ConvertFromINT64ToIP($LastHostI64)
          $NicObject.LastHost = $LastHostIP | Write-Output
        }
      }
      $Alt2NicObjects = Get-NetIPConfiguration
      Foreach ($Alt2NicObject in $Alt2NicObjects){
        if ($NicObject.InterfaceIndex -eq $Alt2NicObject.InterfaceIndex){
          #Obtain Default Gateway
          $IPv4DefaultGateway = Get-NetRoute | Where-Object -FilterScript {$_.ifIndex -eq $NicObject.InterfaceIndex} | Where-Object -FilterScript {$_.NextHop -Ne "::"} | Where-Object -FilterScript { $_.NextHop -Ne "0.0.0.0" }  | Where-Object -FilterScript { ($_.NextHop.SubString(0,6) -Ne 
            "fe80::") } | Select-Object NextHop
          $NicObject.IPv4DefaultGateway = $IPv4DefaultGateway.NextHop
          #Obtain MacAddress
          $MacAddress = Get-NetAdapter | Where-Object -FilterScript {$_.ifIndex -eq $NicObject.InterfaceIndex} | Select-Object MacAddress
          $NicObject.MacAddress = $MacAddress -replace '.*=' -replace '}.*'
      }
    }
  }
}
if ($t){
###Print a formatted output for all Interfaces
  $NicObjects | Format-Table InterfaceIndex,InterfaceAlias,MacAddress,IPv4Address,PrefixLength,SubnetMask,IPv4DefaultGateway,IPNetwork,SuffixOrigin,AddressState,FirstHost,LastHost -AutoSize | Out-String -Width 4096
}
else {
  return $NicObjects
}


<###Select a single Interface to print a formatted output
  Write-Host "Menu : Please Select from the following"
  Write-Host "e.g. 1"
  Foreach ($NicObject in $NicObjects){
      $j=($NicObjects.IndexOf($NicObject))+1
      Write-Host "$($j): $($NicObject.InterfaceAlias)"
  }
  [uInt16]$k=Read-Host -Prompt "Enter a number to select"
  if ($k -gt 0){$k--}
  $NicObjects[$k] | Format-Table InterfaceIndex,InterfaceAlias,MacAddress,IPv4Address,PrefixLength,SubnetMask,IPv4DefaultGateway,IPNetwork,SuffixOrigin,AddressState,FirstHost,LastHost -AutoSize | Out-String -Width 4096
#>
}

#Main Script Starts From Here
Export-ModuleMember -Function Get-PrimaryIPv4Information
#Get-PrimaryIPv4Information -t -a