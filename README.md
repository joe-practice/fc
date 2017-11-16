# Takehome exercise for Funding Circle

These terraform configurations will create a vpc, network components, and two instances: 
a front end nginx server and a backend postgres.

To run terraform successfully, have an ssh key, AWS creds, and terraform installed.

Run:  terraform apply

The address of an ELB and relevant IPs will be output.

The postgres server can be reached via telnet <postgres private IP> 5432 from the nginx server, or by installing psql.
  
TODO:

add an app to write & read data from postgres
modularize terraform config

