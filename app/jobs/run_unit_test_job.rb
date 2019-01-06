# require 'docker'
require 'nokogiri'
require 'json'
require 'net/http'

# Note-- the precondition here is that there is going to be an image with the given image_id pre-existing on the computer.
# Image building is not within the scope of this job, for purposes of efficiency
#
# Note-- docker  thread = Thread.new { container.attach { |stream, chunk| puts "#{chunk}" } }
class RunUnitTestJob < ApplicationJob
  queue_as :default
  SECRET_KEY = ENV['SECRET_KEY']
  ACCESS_KEY = ENV['ACCESS_KEY']
  def perform(submission_id, project_uri, test_uri, image_name)
    submission = Submission.find(submission_id)
    # puts project_uri
    # puts test_uri
    Docker.options[:read_timeout] = 7200
    img = Container.find_by(name: image_name)
    # puts img
    container = Docker::Container.create('Image' => img.uid,
                                         'Env' => ["AWS_SECRET_ACCESS_KEY=#{SECRET_KEY}", "AWS_ACCESS_KEY_ID=#{ACCESS_KEY}"],
                                         'Cmd' => ['./unzip-and-grade.sh', project_uri, test_uri],
                                         'Tty' => true)
    submission.update_attribute(:container_id, container.id)
    container.tap(&:start).attach(tty: true)
    xml = container.logs(stdout: true)
    # puts xml
    # TODO: CHECK EXIT STATUS
    a = Nokogiri::XML(xml)

    testsuite = a.at_xpath('//testsuite')
    testcases = a.xpath('//testcase')
    if testsuite.nil?
      json_str = {'status' => 'failure', 'id' => submission.proj_id   }
      # puts json_str
      submission.update_attribute(:result, json_str)
      uri = URI.parse('http://localhost:3000/grades')
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
      req.body = json_str.to_json
      res = http.request req
    return
    end
    json_hash = {
        'status' => 'ok',
        'id' => submission.proj_id,
        'number_of_tests' => testsuite.attribute('tests').text.to_i,
        'number_of_failures' => testsuite.attribute('failures').text.to_i,
        'number_of_errors' => testsuite.attribute('errors').text.to_i
    }


    failures = testcases.select {|c| !c.children.empty?}.map do |t|
      ret = []
      if t.at_xpath('//failure')
        ret << [:failure, t.at_xpath('//failure').attribute('message').at_xpath('text()') ? t.at_xpath('//failure').attribute('message').text : t.at_xpath('//failure/text()').text  ] unless t.at_xpath('//failure').attribute('message').nil?
      end
      if t.at_xpath('//error')
        ret << [:error, t.at_xpath('//error').text]
      end
      [t.attribute('name').text , ret.to_h]
    end
    # json_hash[:failures] = failures.to_h

    json_str = json_hash.to_json
    # puts json_str
    submission.update_attribute(:result, json_str)
    uri = URI.parse('http://localhost:3000/grades')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    req.body = json_str
    #req = Net::HTTP.post uri, json_str, 'Content-Type' => 'application/json'
    # begin
    res = http.request req
    # puts res
    # rescue => e
     #  puts e
    # end

  end
end
