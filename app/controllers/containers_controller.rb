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
    params = container_params
    CreateContainerFromTarJob.perform_later(params[:config_uri], params[:container_name])
    render json: @container, status: :created, location: @container
  end

  # PATCH/PUT /containers/1
  def update
    params = container_params
    CreateContainerFromTarJob.perform_later(params[:config_uri], params[:container_name])
  end

  # DELETE /containers/1
  def destroy
    @container.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_container
      @container = Container.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def container_params
      params.require(:container).permit(:container_name, :config_uri)
    end
end
