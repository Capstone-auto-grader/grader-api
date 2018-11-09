require 'docker'
require 'nokogiri'
require 'json'
require 'net/http'

# Note-- the precondition here is that there is going to be an image with the given image_id pre-existing on the computer.
# Image building is not within the scope of this job, for purposes of efficiency
#
# TODO: This is not working yet, it needs to be run as an administrator.
class RunUnitTestJob < ApplicationJob
  queue_as :default
  SECRET_KEY = ENV['SECRET_KEY']
  ACCESS_KEY = ENV['ACCESS_KEY']
  IMAGE_ID = '9009ac181796'
  def perform(submission_id, project_uri, test_uri)
    submission = Submission.find(submission_id)
    container = Docker::Container.create('Image' => IMAGE_ID,
                                         'Env' => ["AWS_SECRET_ACCESS_KEY=#{SECRET_KEY}", "AWS_ACCESS_KEY_ID=#{ACCESS_KEY}"],
                                         'Cmd' => ['./unzip-and-grade.sh', project_uri, test_uri],
                                         'Tty' => true)
    submission.update_attribute(:container_id, container.id)
    container.tap(&:start).attach(tty: true)
    xml = container.logs(stdout: true)
    # TODO: CHECK EXIT STATUS
    a = Nokogiri::XML(xml)

    testsuite = a.at_xpath('//testsuite')
    testcases = a.xpath('//testcase')

    json_hash = {
        'number-of-tests' => testsuite.attribute('tests').text.to_i,
        'number-of-failures' => testsuite.attribute('failures').text.to_i,
        'number-of-errors' => testsuite.attribute('errors').text.to_i
    }


    failures = testcases.select {|c| !c.children.empty?}.map do |t|
      ret = []
      if t.at_xpath('//failure')
        ret << [:failure, t.at_xpath('//failure').attribute('message').at_xpath('text()') ? t.at_xpath('//failure').attribute('message').text : t.at_xpath('//failure/text()').text  ]
      end
      if t.at_xpath('//error')
        ret << [:error, t.at_xpath('//error').text]
      end
      [t.attribute('name').text , ret.to_h]
    end
    json_hash[:failures] = failures.to_h

    json_str = json_hash.to_json
    submission.update_attribute(:result, json_str)
    uri = URI 'localhost:3000'
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    begin
      res = http.request req
      puts res
    rescue => e
      puts e
    end
  end
end
