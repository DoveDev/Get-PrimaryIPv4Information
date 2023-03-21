# Get-PrimaryIPv4Information  
  
## Description
  This Module was designed to present the most essential or basic IPv4 and MAC address information to a user. The information provided is as follows;
  - InterfaceIndex
  - InterfaceAlias
  - MacAddress
  - IPv4Address
  - PrefixLength
  - SubnetMask
  - IPv4DefaultGateway
  - IPNetwork
  - SuffixOrigin
  - AddressState
  - FirstHost
  - LastHost

 ##How To use;
  - download the .psm1 file
  - open a powershell terminal
  - cd to the directory where the .psm1 file is located
  - Enter, Import-Module \Get-PrimaryIPv4Information
  - Enter, Get-PrimaryIPv4Information
    
 ##Examples;
 ###Example 1)
 > Get-PrimaryIPv4Information
 
 Results
  InterfaceIndex     : 45
  InterfaceAlias     : Ethernet
  MacAddress         : 00-11-22-33-44-55
  IPv4Address        : 169.254.83.107
  PrefixLength       : 16
  SubnetMask         : 255.255.0.0
  IPv4DefaultGateway :
  IPNetwork          : 169.254.0.0
  SuffixOrigin       : Link
  AddressState       : Preferred
  FirstHost          : 169.254.0.1
  LastHost           : 169.254.255.254
  
  --more--
  
###Example 2)
 > Get-PrimaryIPv4Information -t
   
Results
  InterfaceIndex InterfaceAlias MacAddress        IPv4Address    PrefixLength SubnetMask    IPv4DefaultGateway IPNetwork   SuffixOrigin AddressState FirstHost   LastHost
-------------- -------------- ----------        -----------    ------------ ----------    ------------------ ---------   ------------ ------------ ---------   --------
            18 Ethernet       00-11-22-33-44-55 169.254.20.122           16                                                      Link   Deprecated
            11 Wi-Fi          55-44-33-22-11-00 172.16.45.116            18 255.255.192.0 172.16.24.1        172.16.0.0          Dhcp    Preferred 172.16.0.1  172.16.63.254
            45 Ethernet #2                        169.254.83.107           16 255.255.0.0                      169.254.0.0         Link    Preferred 169.254.0.1 169.254.255.254
            
###Example 3)
 > Get-PrimaryIPv4Information -t -a
    
Results
 InterfaceIndex InterfaceAlias              MacAddress        IPv4Address    PrefixLength SubnetMask    IPv4DefaultGateway IPNetwork   SuffixOrigin AddressState FirstHost   LastHost
-------------- --------------              ----------        -----------    ------------ ----------    ------------------ ---------   ------------ ------------ ---------   --------
            15 Local Area Connection* 2                      169.254.84.7             16                                                      Link    Tentative
             9 Local Area Connection* 1                      169.254.10.153           16                                                      Link    Tentative
            18 Ethernet                    00-11-22-33-44-55 169.254.20.122           16                                                      Link   Deprecated
            11 Wi-Fi                       55-44-33-22-11-00 172.16.45.116            18 255.255.192.0 172.16.24.1        172.16.0.0          Dhcp    Preferred 172.16.0.1  172.16.63.254
            45 Ethernet #2                                     169.254.83.107           16 255.255.0.0                      169.254.0.0         Link    Preferred 169.254.0.1 169.254.255.254
             1 Loopback Pseudo-Interface 1                   127.0.0.1                 8 255.0.0.0                        127.0.0.0      WellKnown    Preferred 127.0.0.1   127.255.255.254
