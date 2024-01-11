$vms = Import-CSV .VM.csv  #������ƣ����ͽű���ͬһĿ¼
$templatenic = 'eth0'#�����ģ����������
$templateuser = 'root'
$templatepass = '123456'#�����ģ������

#����vCenter 
Connect-VIServer -Protocol https -User 'administrator@vsphere.local' -Password 'test1234567' -Server 192.168.1.1
 
foreach ($vm in $vms){
      $VMName = $vm.Name
	  $Network = $vm.Network
	  $Cpu = $vm.Cpu
	  $Memory = $vm.Memory
	  $Notes = $vm.Usage
	  $Disk = $vm.DISK
	  $Template = Get-Template $vm.Template
      $VMHost = Get-VMHost $vm.PhysicalHost
      $Datastore = Get-Datastore $vm.Datastore    
      #1���½�������ļ���
      New-Folder -Name $vm.Esxidir -Location VM 
      Start-Sleep -s 5  
      #2����ģ���½�����������������ơ��˿���ʹ��λ��
      New-VM -Name $VMName -Template $Template -VMHost $VMHost -NetworkName $Network -Datastore $Datastore -RunAsync -Location $vm.Esxidir
      Start-Sleep -s 15
      #3�����������cpu���ڴ棬�ͱ�ע
	  Get-VM -Name $VMName|Set-VM  -NumCPU $Cpu -MemoryGB $Memory -Notes $Notes -Confirm:$false
      Start-Sleep -s 5
      #4�����������Ӳ��
	  if ($Disk -gt 0)
       { Get-VM -Name $VMName  | New-HardDisk -CapacityGB $Disk -Persistence persistent }
     Start-Sleep -s 5
      #5�����������Դ
      Get-VM $VMName| Start-VM
      Start-Sleep -s 15   
      #6��ִ�нű����޸������ip����������
	  $vmcfg='sed -i s/IPADDR=null/IPADDR='+$vm.IPV4+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/NETMASK=null/NETMASK='+$vm.NetMask+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/GATEWAY=null/GATEWAY='+$vm.IPV4GW+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/IPV6ADDR=null/IPV6ADDR='+$vm.IPV6+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/IPV6_DEFAULTGW=null/IPV6_DEFAULTGW='+$vm.IPV6GW+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && hostnamectl set-hostname '+$VMName+' && systemctl restart network'
      Get-VM $VMName | Invoke-VMScript -ScriptText $vmcfg -GuestUser $templateuser -GuestPassword  $templatepass

}