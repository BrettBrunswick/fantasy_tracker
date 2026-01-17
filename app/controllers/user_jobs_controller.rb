class UserJobsController < ApplicationController
  before_action :require_login

  def status
    @active_jobs = current_user.user_jobs.active
    @recent_completed = current_user.user_jobs.where(status: %w[completed failed])
      .where("completed_at > ?", 30.seconds.ago)
      .order(completed_at: :desc)

    render json: {
      active: @active_jobs.map { |j| job_json(j) },
      recent: @recent_completed.map { |j| job_json(j) }
    }
  end

  def dismiss
    job = current_user.user_jobs.find(params[:id])
    job.update!(message: nil) # Clear message so it won't show again
    head :ok
  end

  private

  def job_json(job)
    {
      id: job.id,
      job_type: job.job_type,
      status: job.status,
      message: job.message,
      started_at: job.started_at&.iso8601,
      completed_at: job.completed_at&.iso8601
    }
  end
end
