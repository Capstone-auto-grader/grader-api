require 'docker'
Docker.url = ENV['DOCKER_URL']
Excon.defaults[:write_timeout] = 1000
Excon.defaults[:read_timeout] = 1000
