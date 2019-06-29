require 'aws-sdk'

# Aws.config.update({
#     region: 'us-east-1',
#     access_key_id: ENV['ACCESS_KEY'],
#     secret_access_key: ENV['SECRET_KEY'],
# })


S3_BUCKET = Aws::S3::Resource.new.bucket('auto-grader-capstone')
ECR_CLIENT = Aws::ECR::Client.new
ECR_BASE_URI = '772137347529.dkr.ecr.us-east-2.amazonaws.com'

@token = ECR_CLIENT.get_authorization_token.authorization_data.first
def get_docker_auth
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
