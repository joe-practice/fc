# Takehome exercise for <>

These terraform configurations will create a vpc, network components, and two instances: 
a front-end nginx and a backend postgres.

To run terraform successfully, have an ssh key, AWS creds, and terraform installed.

Once the prerequisites are in place, update vars.tf with your public IP which will be used to configure the security groups.

Run:  ```terraform apply```

The address of an ELB and relevant IPs will be shown in the output.

The postgres server can be reached via telnet <postgres private IP> 5432 from the nginx server, or by installing psql.
  
ToDo:

add an app to write & read data from postgres

modularize terraform config

centralized logging, security, containerize, etc.

