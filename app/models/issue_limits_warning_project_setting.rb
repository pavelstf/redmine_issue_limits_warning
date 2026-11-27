class IssueLimitsWarningProjectSetting < ActiveRecord::Base
  self.table_name = 'rilw_project_settings'
  belongs_to :project
  validates :project_id, uniqueness: true
  validates :cpi_warning, :cpi_danger, numericality: {greater_than: 0, less_than_or_equal_to: 1}
  validates :absolute_limit_threshold, numericality: {greater_than: 0, less_than_or_equal_to: 999}
  validate :ordered_cpi_thresholds
  before_validation :normalize_decimal_inputs

  def settings_hash
    RedmineIssueLimitsWarning::Settings::PROJECT_KEYS.to_h do |key|
      value = public_send(key)
      [key, value == true ? '1' : value == false ? '0' : value.to_s]
    end
  end

  private

  def normalize_decimal_inputs
    %w[cpi_warning cpi_danger absolute_limit_threshold].each do |key|
      self[key] = RedmineIssueLimitsWarning::Settings.number(read_attribute_before_type_cast(key))
    end
  end

  def ordered_cpi_thresholds
    if cpi_warning && cpi_danger && cpi_danger > cpi_warning
      errors.add(:base, I18n.t(:error_rilw_cpi_thresholds))
    end
  end
end
