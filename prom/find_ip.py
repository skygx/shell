import re

string_ip=open('/var/log/httpd/access_log','r').read()
list_ip = re.findall(r"\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b", string_ip)
result = list(set(list_ip))
ip=open('ip.txt','w')
for i in result:
    ip.write(i+'\n')

