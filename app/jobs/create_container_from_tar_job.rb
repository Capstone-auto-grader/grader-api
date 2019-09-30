class CreateContainerFromTarJob < ApplicationJob
  queue_as :default

  def perform(container_id)
    puts "STARTING CONTAINER JOB"
    container = Container.find(container_id)
    item_uri = S3_BUCKET.object(container.config_uri).presigned_url(:get, expires_in: 60)
    puts container.config_uri
    puts item_uri
    
    image = Docker::Image.build_from_tar(open(item_uri))
    puts "IMAGE", image
    container.uid = image.id
    container.save!
    # Do something later
    puts "CONTAINER SAVED"
  end
end
