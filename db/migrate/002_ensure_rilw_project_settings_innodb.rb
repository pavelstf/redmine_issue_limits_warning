class EnsureRilwProjectSettingsInnodb < ActiveRecord::Migration[6.1]
  def up
    return unless connection.adapter_name.match?(/mysql|trilogy/i)

    engine = connection.select_value(<<~SQL)
      SELECT ENGINE FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'rilw_project_settings'
    SQL
    unless %w[InnoDB MyISAM].include?(engine)
      raise "Unexpected storage engine for rilw_project_settings: #{engine.inspect}"
    end

    keys = connection.foreign_keys(:rilw_project_settings).select { |fk| fk.column == 'project_id' }
    valid_key = ->(fk) { fk.to_table == 'projects' && fk.primary_key == 'id' && fk.on_delete.to_s == 'cascade' }
    raise 'Unexpected project_id foreign key' unless keys.all?(&valid_key)
    return if engine == 'InnoDB' && keys.any?

    projects_engine = connection.select_value(<<~SQL)
      SELECT ENGINE FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'projects'
    SQL
    raise 'Expected the projects table to use InnoDB' unless projects_engine == 'InnoDB'
    orphan = connection.select_value(<<~SQL)
      SELECT s.project_id FROM rilw_project_settings s
      LEFT JOIN projects p ON p.id = s.project_id
      WHERE p.id IS NULL LIMIT 1
    SQL
    raise "Project settings reference an absent project (#{orphan})" if orphan

    execute 'ALTER TABLE rilw_project_settings ENGINE=InnoDB' if engine == 'MyISAM'
    add_foreign_key :rilw_project_settings, :projects, column: :project_id, on_delete: :cascade if keys.empty?
    unless connection.foreign_keys(:rilw_project_settings).any? { |fk| fk.column == 'project_id' && valid_key.call(fk) }
      raise 'Project settings foreign key was not created'
    end
  end

  def down
    return unless connection.adapter_name.match?(/mysql|trilogy/i)

    raise ActiveRecord::IrreversibleMigration, 'Keep the project settings table and its foreign key.'
  end
end
