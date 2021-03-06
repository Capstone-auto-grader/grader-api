class RunMossJob < ApplicationJob
  queue_as :default

  SECRET_KEY = ENV['SECRET_KEY']
  ACCESS_KEY = ENV['ACCESS_KEY']
  MOSS_KEY = ENV['MOSS_KEY']
  def perform(assignment_id, image_name, files, base_uri)
    puts base_uri
    image = Container.find_by(name: image_name)
    puts image.uid
    container = Docker::Container.create('Image' => image.uid,
                                         'Env' => ["AWS_SECRET_ACCESS_KEY=#{SECRET_KEY}", "AWS_ACCESS_KEY_ID=#{ACCESS_KEY}", "MOSS_KEY=#{MOSS_KEY}"],
                                         'Cmd' => ['ruby', 'moss.rb'] + [base_uri] +  files,
                                         'Tty' => true)
    container.tap(&:start).attach(:tty => true)
    url = container.logs(stdout: true)
    puts url
    uri = URI.parse("#{ENV['GRADING_SERVER']}/moss")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    req.body = {assignment_id: assignment_id, moss_url: url.squish}.to_json
    res = http.request req
  end
end
