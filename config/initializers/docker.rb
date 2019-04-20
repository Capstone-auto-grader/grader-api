require 'docker'
Docker.url = ENV['DOCKER_URL']
Excon.defaults[:write_timeout] = 10000
Excon.defaults[:read_timeout] = 10000
