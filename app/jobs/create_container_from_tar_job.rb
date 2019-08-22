class CreateContainerFromTarJob < ApplicationJob
  queue_as :default


  def perform(config_uri, container_name)
    login_docker
    item_uri = S3_BUCKET.object(config_uri).presigned_url(:get, expires_in: 60)
    puts item_uri
    image = Docker::Image.build_from_tar(open(item_uri))
    ecr_repo = "#{ECR_BASE_URI}/auto-grader/#{container_name}"
    puts ecr_repo
    image.tag(repo: ecr_repo, tag: 'latest')
    puts "Image: #{image.id} has been tagged: #{image.info['RepoTags'].last}."
    repo_tag = "#{ecr_repo}:latest"
    # puts image.tags
    puts image.push(tag: repo_tag).to_s
    # Do something later
    puts "CONTAINER SAVED"
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
end
