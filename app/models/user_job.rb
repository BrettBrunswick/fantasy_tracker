# == Schema Information
#
# Table name: user_jobs
#
#  id           :bigint           not null, primary key
#  completed_at :datetime
#  job_type     :string
#  message      :text
#  started_at   :datetime
#  status       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  job_id       :string
#  user_id      :bigint           not null
#
# Indexes
#
#  index_user_jobs_on_job_id              (job_id) UNIQUE
#  index_user_jobs_on_user_id             (user_id)
#  index_user_jobs_on_user_id_and_status  (user_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserJob < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending running completed failed].freeze

  scope :active, -> { where(status: %w[pending running]) }
  scope :recent, -> { order(created_at: :desc).limit(10) }

  def running?
    status == "running"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def active?
    %w[pending running].include?(status)
  end

  def finish!(message: nil)
    update!(status: "completed", completed_at: Time.current, message: message)
  end

  def fail!(message:)
    update!(status: "failed", completed_at: Time.current, message: message)
  end
end
