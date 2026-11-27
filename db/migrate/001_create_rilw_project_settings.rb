class CreateRilwProjectSettings < ActiveRecord::Migration[6.1]
  class LegacySetting < ActiveRecord::Base
    self.table_name = 'settings'
  end
  class ProjectSetting < ActiveRecord::Base
    self.table_name = 'rilw_project_settings'
  end

  def up
    unless table_exists?(:rilw_project_settings)
      table_options = connection.adapter_name.match?(/mysql|trilogy/i) ? {options: 'ENGINE=InnoDB'} : {}
      create_table :rilw_project_settings, **table_options do |t|
        t.integer :project_id, null: false
        t.boolean :enabled, null: false, default: true
        t.boolean :override_thresholds, null: false, default: false
        t.decimal :cpi_warning, precision: 8, scale: 4, null: false, default: 0.9
        t.decimal :cpi_danger, precision: 8, scale: 4, null: false, default: 0.8
        t.boolean :absolute_limit_enabled, null: false, default: false
        t.decimal :absolute_limit_threshold, precision: 10, scale: 2, null: false, default: 100
        t.boolean :due_date_enabled, null: false, default: true
        t.integer :lock_version, null: false, default: 0
        t.timestamps
      end
    end
    add_index :rilw_project_settings, :project_id, unique: true, name: 'rilw_project_unique' unless index_exists?(:rilw_project_settings, :project_id)
    add_foreign_key :rilw_project_settings, :projects, on_delete: :cascade unless foreign_key_exists?(:rilw_project_settings, :projects)
    ProjectSetting.reset_column_information
    setting = LegacySetting.find_by(name: 'plugin_redmine_issue_limits_warning')
    data = setting ? YAML.safe_load(setting.value,
      permitted_classes: [Symbol, ActiveSupport::HashWithIndifferentAccess], aliases: false) : {}
    overrides = data.is_a?(Hash) ? data['project_settings'] : nil
    return unless overrides.is_a?(Hash)
    overrides.each do |project_id, config|
      next unless config.is_a?(Hash) && Project.exists?(id: project_id)
      next if ProjectSetting.exists?(project_id: project_id)
      limit = Float(config['danger_threshold'].to_s.tr(',', '.'), exception: false)
      limit = 100 unless limit&.finite? && limit > 0 && limit <= 999
      ProjectSetting.create!(project_id: project_id,
        enabled: truthy?(config.fetch('enabled', '1')),
        due_date_enabled: truthy?(config.fetch('due_date_enabled', '1')),
        override_thresholds: truthy?(config['override_thresholds']),
        absolute_limit_threshold: limit)
    end
    # Retain the old hash for rollback. Old hour thresholds are NOT CPI thresholds.
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Preserve project settings; restore a database backup for a historical-version rollback.'
  end

  private

  def truthy?(value)
    value == true || value.to_s == '1'
  end
end
