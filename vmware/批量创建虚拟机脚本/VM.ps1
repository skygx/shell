$vms = Import-CSV .VM.csv  #表格名称，表格和脚本在同一目录
$templatenic = 'eth0'#虚拟机模板网卡名称
$templateuser = 'root'
$templatepass = '123456'#虚拟机模板密码

#连接vCenter 
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
      #1、新建虚拟机文件夹
      New-Folder -Name $vm.Esxidir -Location VM 
      Start-Sleep -s 5  
      #2、从模板新建虚拟机，并设置名称、端口组和存放位置
      New-VM -Name $VMName -Template $Template -VMHost $VMHost -NetworkName $Network -Datastore $Datastore -RunAsync -Location $vm.Esxidir
      Start-Sleep -s 15
      #3、配置虚拟机cpu，内存，和备注
	  Get-VM -Name $VMName|Set-VM  -NumCPU $Cpu -MemoryGB $Memory -Notes $Notes -Confirm:$false
      Start-Sleep -s 5
      #4、配置虚拟机硬盘
	  if ($Disk -gt 0)
       { Get-VM -Name $VMName  | New-HardDisk -CapacityGB $Disk -Persistence persistent }
     Start-Sleep -s 5
      #5、打开虚拟机电源
      Get-VM $VMName| Start-VM
      Start-Sleep -s 15   
      #6、执行脚本（修改虚拟机ip和主机名）
	  $vmcfg='sed -i s/IPADDR=null/IPADDR='+$vm.IPV4+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/NETMASK=null/NETMASK='+$vm.NetMask+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/GATEWAY=null/GATEWAY='+$vm.IPV4GW+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/IPV6ADDR=null/IPV6ADDR='+$vm.IPV6+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && sed -i s/IPV6_DEFAULTGW=null/IPV6_DEFAULTGW='+$vm.IPV6GW+'/ /etc/sysconfig/network-scripts/ifcfg-'+$templatenic+' && hostnamectl set-hostname '+$VMName+' && systemctl restart network'
      Get-VM $VMName | Invoke-VMScript -ScriptText $vmcfg -GuestUser $templateuser -GuestPassword  $templatepass

}