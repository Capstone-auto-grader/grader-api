class CreateContainerFromTarJob < ApplicationJob
  queue_as :default

  def perform(container_id)
    container = Container.find(container_id)
    item_uri = S3_BUCKET.object(container.config_uri).presigned_url(:get, expires_in: 60)
    image = Docker::Image.build_from_tar(open(item_uri))
    container.uid = image.id
    container.save!
    # Do something later
  end
end
