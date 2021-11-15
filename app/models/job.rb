# frozen_string_literal: true

class Job < ApplicationRecord
  validates :name, :priority, presence: true
  validates :priority, inclusion: { in: %w[critical high low],
                                    message: '%{value} is not a valid priority' }
  validates :aasm_state, inclusion: { in: %w[waiting in_progress done failed],
                                      message: '%{value} is not a valid state' }
  has_one :movie, dependent: :destroy

  scope :get_by_priority,        -> { order(:priority) }

  scope :critical_priority_jobs, -> { where(priority: 'critical') }
  scope :high_priority_jobs,     -> { where(priority: 'high') }
  scope :low_priority_jobs,      -> { where(priority: 'low') }

  validate :triggered_at_check
  after_commit :trigger_worker, on: :create

  include AASM
  aasm whiny_transitions: false do
    # job states
    state :waiting, initial: true
    state :in_progress
    state :done
    state :failed

    event :progress do
      transitions from: :waiting, to: :in_progress, guard: :transition_can_happen?
      after %i[store_movie_title]
    end

    event :complete do
      transitions from: :in_progress, to: :done, guard: :transition_can_happen?
    end

    event :fail do
      transitions from: :waiting, to: :failed, guard: :transition_can_happen?
    end
  end

  def invoke_job
    progress! if waiting?
  end

  private

  def transition_can_happen?
    true
  end

  def triggered_at_check
    return if triggered_at.nil?

    add_error and return if persisted? && attribute_changed?(:triggered_at)

    add_error if !persisted? && triggered_at <= Time.zone.now
  end

  def trigger_worker
    return if triggered_at.nil?

    TriggerJobWorker.perform_at(triggered_at, id)
  end

  def store_movie_title
    job_movie = build_movie(title: random_movie_title)
    if job_movie.save
      complete!
    else
      fail!
    end
  end

  def random_movie_title
    (0...8).map { rand(65..90).chr }.join
  end

  def add_error
    errors.add(:triggered_at, 'must be greater than current date time or cant changed')
  end
end
