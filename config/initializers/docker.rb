require 'docker'
# Docker.url = 'tcp://stravinsky.eastus.cloudapp.azure.com:2375'
Excon.defaults[:write_timeout] = 1000
Excon.defaults[:read_timeout] = 1000
