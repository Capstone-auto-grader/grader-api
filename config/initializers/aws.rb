require 'aws-sdk'

Aws.config.update({
    region: 'us-east-1',
    access_key_id: ENV['ACCESS_KEY'],
    secret_access_key: ENV['SECRET_KEY'],
})


S3_BUCKET = Aws::S3::Resource.new.bucket('auto-grader')
ECR_CLIENT = Aws::ECR::Client.new
ECR_BASE_URI = '772137347529.dkr.ecr.us-east-2.amazonaws.com'


def get_docker_auth
  @token = ECR_CLIENT.get_authorization_token(registry_ids: ['772137347529']).authorization_data.first
  # puts "TOKEN", @token
  if @token.expires_at.to_date.past?
    @token = ECR_CLIENT.get_authorization_token.authorization_data.first
  end
  return @token
end

def login_docker
  token = get_docker_auth
  ecr_repo_url = token.proxy_endpoint.gsub('https://', '')
  user_pass_token = Base64.decode64(token.authorization_token).split(':')
  Docker.authenticate!('username' => user_pass_token.first,
                       'password' => user_pass_token.last,
                       'email' => 'none',
                       'serveraddress' => ecr_repo_url)
end
