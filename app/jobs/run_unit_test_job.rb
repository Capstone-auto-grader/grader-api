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
  XML_HEADER = '<?xml version="1.0" encoding="UTF-8" ?>'
  def perform(submission_id, project_uri, test_uri, image_name, student_name, security_string)
    submission = Submission.find(submission_id)
    # puts project_uri
    # puts test_uri
    Docker.options[:read_timeout] = 7200
    img = Container.find_by(name: image_name)
    # puts img
    container = Docker::Container.create('Image' => img.uid,
                                         'Env' => ["AWS_SECRET_ACCESS_KEY=#{SECRET_KEY}", "AWS_ACCESS_KEY_ID=#{ACCESS_KEY}", 'MAVEN_OPTS="-Xmx2048m"','_JAVA_OPTIONS="-Xms1024m  -XX:MaxPermSize=512m"' ],
                                         'Cmd' => ['./unzip-and-grade.sh', project_uri, test_uri, student_name],
                                         'Tty' => true)
    submission.update_attribute(:container_id, container.id)
    container.tap(&:start).attach(tty: true)
    xml = container.logs(stdout: true)
    # puts xml
    xml_arr = split_output_to_xmls(xml)
    hash_arr = xml_arr.map { |elem| single_xml_string_to_hash(elem) }
    final_hash = aggregate_json_hashes(submission,hash_arr, security_string)
    puts final_hash
    post_results_to_webserver(submission, final_hash)

    # puts "XML"
    # puts xml
    # TODO: CHECK EXIT STATUS
    # a = Nokogiri::XML(xml)
    #
    # testsuite = a.at_xpath('//testsuite')
    # testcases = a.xpath('//testcase')
    # if testsuite.nil?
    #   json_str = {'status' => 'failure', 'id' => submission.proj_id   }
    #   # puts "STR"
    #   # puts json_str
    #   submission.update_attribute(:result, json_str)
    #   uri = URI.parse('http://localhost:3000/grades')
    #   http = Net::HTTP.new(uri.host, uri.port)
    #   req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    #   req.body = json_str.to_json
    #   res = http.request req
    # return
    # end
    # json_hash = {
    #     'status' => 'ok',
    #     'id' => submission.proj_id,
    #     'number_of_tests' => testsuite.attribute('tests').text.to_i,
    #     'number_of_failures' => testsuite.attribute('failures').text.to_i,
    #     'number_of_errors' => testsuite.attribute('errors').text.to_i
    # }
    #
    #
    # failures = testcases.select {|c| !c.children.empty?}.map do |t|
    #   ret = []
    #   if t.at_xpath('//failure')
    #     if ! t.at_xpath('//failure').attribute('message').nil?
    #     ret << [:failure, t.at_xpath('//failure').attribute('message').at_xpath('text()') ? t.at_xpath('//failure').attribute('message').text : t.at_xpath('//failure/text()').text  ]
    #
    #     else
    #       ret << [:failure, t.at_xpath('//failure').attribute('type').text]
    #     end
    #   end
    #   if t.at_xpath('//error')
    #     ret << [:error, t.at_xpath('//error').text]
    #   end
    #   [t.attribute('name').text , ret.to_h]
    # end
    # json_hash[:failures] = failures.to_h
    #
    # json_str = json_hash.to_json
    # # uts json_str
    # submission.update_attribute(:result, json_str)
    # uri = URI.parse('http://localhost:3000/grades')
    # http = Net::HTTP.new(uri.host, uri.port)
    # req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    # req.body = json_str
    # #req = Net::HTTP.post uri, json_str, 'Content-Type' => 'application/json'
    # # begin
    # res = http.request req
    # # puts res
    # # rescue => e
    #  #  puts e
    # # end

  end

  def aggregate_json_hashes(submission, hashes, sec_string)
    if hashes.empty?
      return {'status' => 'failure', 'id' => submission.proj_id, 'sec'=> sec_string }
    end
    failures = hashes.map {|hash| hash[:failures]}.inject &:merge
    number_of_failures = hashes.inject(0) { |accum, hash| accum + hash['number_of_failures']}
    number_of_tests = hashes.inject(0) { |accum, hash| accum + hash['number_of_tests']}
    number_of_errors =hashes.inject(0) { |accum, hash| accum + hash['number_of_errors']}
    return {
        'status' => 'ok',
        'id' => submission.proj_id,
        'sec' => sec_string,
        'number_of_tests' => number_of_tests,
        'number_of_failures' => number_of_failures,
        'number_of_errors' => number_of_errors,
        'failures' => failures
    }
  end

  def single_xml_string_to_hash(xml_string)
    xml_doc = Nokogiri::XML(xml_string)
    testsuite = xml_doc.at_xpath('//testsuite')
    testcases = xml_doc.xpath('//testcase')
    if testsuite.nil?
      return {'status' => 'failure' }
    end
    json_hash = {
        'status' => 'ok',
        'number_of_tests' => testsuite.attribute('tests').text.to_i,
        'number_of_failures' => testsuite.attribute('failures').text.to_i,
        'number_of_errors' => testsuite.attribute('errors').text.to_i
    }
    failures = testcases.select {|c| !c.children.empty?}.map do |t|
      ret = []
      if t.at_xpath('//failure')
        if ! t.at_xpath('//failure').attribute('message').nil?
          ret << [:failure, t.at_xpath('//failure').attribute('message').at_xpath('text()') ? t.at_xpath('//failure').attribute('message').text : t.at_xpath('//failure/text()').text  ]

        else
          ret << [:failure, t.at_xpath('//failure').attribute('type').text]
        end
      end
      if t.at_xpath('//error')
        ret << [:error, t.at_xpath('//error').text]
      end
      [t.attribute('name').text , ret.to_h]
    end
    json_hash[:failures] = failures.to_h
    json_hash
  end


  def split_output_to_xmls(output)
    return output.split(XML_HEADER).map {|elem| XML_HEADER + elem }.drop(1)
  end

  def post_results_to_webserver(submission, xml_hash)
    json_str = xml_hash.to_json
    submission.update_attribute(:result, json_str)
    uri = URI.parse("#{ENV['GRADING_SERVER']}/grades")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    req.body = json_str
    res = http.request req
  end
end
