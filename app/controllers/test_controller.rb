class TestController < ApplicationController

  def index
    unless Submission.where(proj_id: params[:proj_id]).empty?
      render json: {already_submitted: true}.to_json, status: 418
    end
    subm = Submission.create(proj_id: params[:proj_id])
    RunUnitTestJob.perform_later subm.id, params[:proj_zip], params[:test_zip]
    #  Initialize worker method here with params[:proj_zip] and params[:test_zip]
    render json: {already_submitted: false}.to_json, status: :accepted
  end
end
