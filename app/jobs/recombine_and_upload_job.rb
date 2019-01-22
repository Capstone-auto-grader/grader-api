class RecombineAndUploadJob < ApplicationJob
  queue_as :default
  SECRET_KEY = ENV['SECRET_KEY']
  ACCESS_KEY = ENV['ACCESS_KEY']
  def perform(image_name, zip_name, list_of_zips, assignment_id, ta_id)
    Docker.options[:read_timeout] = 7200
    img = Container.find_by(name: image_name)
    container = Docker::Container.create('Image' => img.uid,
                                         'Env' => ["AWS_SECRET_ACCESS_KEY=#{SECRET_KEY}", "AWS_ACCESS_KEY_ID=#{ACCESS_KEY}"],
                                         'Cmd' => ['bash', 'unzip-and-recombine.sh', zip_name, 'auto-grader-capstone'] + list_of_zips)

    # thread = Thread.new { container.attach { |stream, chunk| puts "#{stream}: #{chunk}" } }
    container.start
    # thread.join
    json_str = {zip_name: zip_name, assignment_id: assignment_id, ta_id: ta_id}.to_json
    uri = URI.parse("#{ENV['GRADING_SERVER']}/batch")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    req.body = json_str
    res = http.request req
  end

end
