class TestController < ApplicationController

  def runtests
    unless Submission.where(proj_id: params[:proj_id]).empty?
      render json: {already_submitted: true}.to_json, status: 418
      return
    end
    # puts params
    subm = Submission.create(proj_id: params[:proj_id], image_name: params[:image_name])
    RunUnitTestJob.perform_later subm.id, params[:proj_zip], params[:test_zip], params[:image_name], params[:student_name]
    #  Initialize worker method here with params[:proj_zip] and params[:test_zip]
    render json: {already_submitted: false}.to_json, status: :accepted
  end

  def batchfile
    puts "STARTING"
    RecombineAndUploadJob.perform_later(params[:image_name], params[:zip_name], params[:uris], params[:assignment_id], params[:ta_id])
    puts "CONTINUING"
    render json: {}.to_json, status: :accepted
  end
end
