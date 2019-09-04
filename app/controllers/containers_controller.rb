class ContainersController < ApplicationController
  before_action :set_container, only: [:show, :update, :destroy]

  # GET /containers
  def index
    @containers = Container.all

    render json: @containers
  end

  # GET /containers/1
  def show
    render json: @container
  end

  # POST /containers
  def create
    @container = Container.new(container_params)

    if @container.save
      CreateContainerFromTarJob.perform_later(@container.id)
      render json: @container, status: :created, location: @container
    else
      render json: @container.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /containers/1
  def update
    if @container.update(container_params)
      CreateContainerFromTarJob.perform_later(@container.id)
      render json: @container
    else
      render json: @container.errors, status: :unprocessable_entity
    end
  end

  # DELETE /containers/1
  def destroy
    @container.destroy
  end

  def get_id_from_name
    name = params[:name]
    container = Container.where(name: name).first
    puts container
    render json: container
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_container
      @container = Container.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def container_params
      puts params
      params.require(:container).permit(:config_uri, :name)
    end
end
