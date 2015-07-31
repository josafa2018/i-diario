class SchoolCalendarStep < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :school_calendar, except: :school_calendar_id

  belongs_to :school_calendar

  validates :start_at, :end_at, presence: true

  scope :ordered, -> { order(arel_table[:start_at]) }
  scope :started_after_and_before, lambda { |date| where(arel_table[:start_at].lteq(date)).
                                                  where(arel_table[:end_at].gteq(date)) }

  def to_s
    "#{localized.start_at} a #{localized.end_at}"
  end
end