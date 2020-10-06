
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
  $NicObjects = Get-NetIPAddress | Where-Object {
      ($_.InterfaceAlias -notlike 'vEthernet*') -and 
      ($_.InterfaceAlias -notlike 'Loopback*') -and
      ($_.InterfaceAlias -notlike 'Npcap*') -and
      ($_.PrefixLength -lt 64)
  } | Select-Object InterfaceIndex,InterfaceAlias,MacAddress,IPv4Address,PrefixLength,SubnetMask,IPv4DefaultGateway,IPNetwork,SuffixOrigin,AddressState,FirstHost,LastHost

  $AltNicObjects = Get-NicAdapter # No InterfaceIndex
  Foreach ($AltNicObject in $AltNicObjects){
      Foreach ($NicObject in $NicObjects){
          if ($NicObject.IPv4Address -eq $($AltNicObject.Address.IPAddressToString)){
              $NicObject.SubnetMask = $AltNicObject.IPv4Mask.IPAddressToString

              $IPAddress = $NicObject.IPv4Address
              $IPAddressArray = $IPAddress -split '\.' | Foreach-Object{[System.Convert]::ToString($_)}
              #$IPAddressArray -join ' ' | Write-Host

              $SubnetMask = $NicObject.SubnetMask
              $SubnetMaskArray = $SubnetMask -split '\.' | Foreach-Object{[System.Convert]::ToString($_)}
              $SubnetMaskIP = [Net.IPAddress]::Parse($SubnetMask)

              #$SubnetMaskArray -join ' ' | Write-Host

              $IPNetwork = '0','0','0','0'
              Foreach ($IPAOctet in $IPAddressArray){
              $i = $IPAddressArray.IndexOf($IPAOctet)
              $IPNetwork[$i] = ($IPAOctet -band $SubnetMaskArray[$i])
              }
              #$IPNetwork -join ' ' | Write-Host
              $NicObject.IPNetwork = $IPNetwork -join '.' | Write-Output
              $IPNetworkIP = [Net.IPAddress]::Parse($NicObject.IPNetwork)
              
              $FirstHostOctetsI64Array = $IPNetwork | Foreach-Object{[System.Convert]::ToInt64($_)}
              #$FirstHostOctetsArray | Write-Host
              $FirstHostI64 = [int64]([int64]$FirstHostOctetsI64Array[0]*16777216 +
                                      [int64]$FirstHostOctetsI64Array[1]*65536 +
                                      [int64]$FirstHostOctetsI64Array[2]*256 +
                                      ([int64]$FirstHostOctetsI64Array[3]+1))

              #Write-Host "Debug : FirstHostI64 ="$FirstHostI64
              <#$FirstHostIP = (([math]::truncate($FirstHostI64/16777216)).tostring()+"."+
                              ([math]::truncate(($FirstHostI64%16777216)/65536)).tostring()+"."+
                              ([math]::truncate(($FirstHostI64%65536)/256)).tostring()+"."+
                              ([math]::truncate($FirstHostI64%256)).tostring())#>
              $FirstHostIP = ConvertFromINT64ToIP($FirstHostI64)

              #Write-Host "Debug : FirstHostIP ="$FirstHostIP
              $NicObject.FirstHost = $FirstHostIP | Write-Output
              
              $NetworkBroadcastIPv4Address = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $SubnetMaskIP.address -bor $IPNetworkIP.address))
              #Write-Host "Debug : NetworkBroadcastIPv4Address ="$NetworkBroadcastIPv4Address
              $NetworkBroadcastIPv4AddressString = [System.Convert]::ToString($NetworkBroadcastIPv4Address)
              #Write-Host "Debug : NetworkBroadcastIPv4AddressString ="$NetworkBroadcastIPv4AddressString
              $LastHostOctetsArray = $NetworkBroadcastIPv4AddressString -split "\." | Foreach-Object{[System.Convert]::ToInt64($_)}
              #Write-Host "Debug : LastHostOctetsArray ="$LastHostOctetsArray
              $LastHostI64 = [int64]([int64]$LastHostOctetsArray[0]*16777216 +
                              [int64]$LastHostOctetsArray[1]*65536 +
                              [int64]$LastHostOctetsArray[2]*256 +
                              ([int64]$LastHostOctetsArray[3]-1))
                              
              #Write-Host "Debug : LastHostI64 ="$LastHostI64
              <#$LastHostIP = (([math]::truncate($LastHostI64/16777216)).tostring()+"."+
                              ([math]::truncate(($LastHostI64%16777216)/65536)).tostring()+"."+
                              ([math]::truncate(($LastHostI64%65536)/256)).tostring()+"."+
                              ([math]::truncate($LastHostI64%256)).tostring())#>
              
              $LastHostIP = ConvertFromINT64ToIP($LastHostI64)
              #Write-Host "Debug : LastHostIP ="$LastHostIP
              $NicObject.LastHost = $LastHostIP | Write-Output
          }
      }
  }

  $Alt2NicObjects = Get-NetIPConfiguration
  Foreach ($Alt2NicObject in $Alt2NicObjects){
      Foreach ($NicObject in $NicObjects){
          if ($NicObject.InterfaceIndex -eq $Alt2NicObject.InterfaceIndex){
              $IPv4DefaultGateway = Get-NetRoute | Where-Object -FilterScript {$_.ifIndex -eq $NicObject.InterfaceIndex} | Where-Object -FilterScript {$_.NextHop -Ne "::"} | Where-Object -FilterScript { $_.NextHop -Ne "0.0.0.0" }  | Where-Object -FilterScript { ($_.NextHop.SubString(0,6) -Ne 
                  "fe80::") } | Select-Object NextHop
              $NicObject.IPv4DefaultGateway = $IPv4DefaultGateway.NextHop

              $MacAddress = Get-NetAdapter | Where-Object -FilterScript {$_.ifIndex -eq $NicObject.InterfaceIndex} | Select-Object MacAddress
              $NicObject.MacAddress = $MacAddress -replace '.*=' -replace '}.*'
          }
      }
  }

#$NicObjects | Write-Host

  Write-Host "Menu : Please Select from the following"
  Write-Host "e.g. 1"
  Foreach ($NicObject in $NicObjects){
      $j=($NicObjects.IndexOf($NicObject))+1
      Write-Host "$($j): $($NicObject.InterfaceAlias)"
  }
  [uInt16]$k=Read-Host -Prompt "Enter a number to select"
  if ($k -gt 0){$k--}
  $NicObjects[$k] | Format-Table InterfaceIndex,InterfaceAlias,MacAddress,IPv4Address,PrefixLength,SubnetMask,IPv4DefaultGateway,IPNetwork,SuffixOrigin,AddressState,FirstHost,LastHost
}

#Main Script Starts From Here
Export-ModuleMember -Function Get-PrimaryIPv4Information