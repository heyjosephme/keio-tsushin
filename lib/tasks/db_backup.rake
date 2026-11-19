# Back up the SQLite database that holds users and enrollments.
#
#   bin/rails db:backup                      # snapshot into storage/backups/
#   bin/rails db:backup BACKUP_DIR=~/Backups # somewhere else, e.g. a synced folder
#   bin/rails db:backup KEEP=30              # how many snapshots to keep (default 10)
#   bin/rails db:backups                     # list the snapshots
#
# It is safe to run while the server is up: VACUUM INTO writes a consistent copy
# without blocking the app. To restore, stop the server and copy a snapshot over
# storage/<environment>.sqlite3.
namespace :db do
  desc "Snapshot the SQLite database into storage/backups (BACKUP_DIR=, KEEP=)"
  task backup: :environment do
    connection = ActiveRecord::Base.connection
    source = Pathname(connection.pool.db_config.database).expand_path(Rails.root)
    abort "db:backup only supports SQLite" unless connection.adapter_name.match?(/sqlite/i)
    abort "No database at #{source}" unless source.exist?

    directory = backup_directory
    directory.mkpath
    target = directory.join("#{source.basename(".sqlite3")}-#{Time.now.strftime("%Y%m%d-%H%M%S")}.sqlite3")

    connection.execute("VACUUM INTO #{connection.quote(target.to_s)}")

    # Never prune on the strength of a snapshot that can't be opened
    check = SQLite3::Database.new(target.to_s, readonly: true)
    result = check.get_first_value("PRAGMA integrity_check")
    users, enrollments = %w[users enrollments].map { |table| check.get_first_value("SELECT COUNT(*) FROM #{table}") }
    check.close
    abort "Backup failed its integrity check (#{result}): #{target}" unless result == "ok"

    puts "Backed up #{source.basename} to #{target} (#{users} users, #{enrollments} enrollments, #{target.size / 1024} KB)"

    keep = Integer(ENV.fetch("KEEP", 10))
    snapshots = directory.glob("#{source.basename(".sqlite3")}-*.sqlite3").sort
    snapshots.first([ snapshots.size - keep, 0 ].max).each do |old|
      old.delete
      puts "Removed old backup #{old.basename}"
    end
  end

  desc "List database snapshots made by db:backup"
  task backups: :environment do
    snapshots = backup_directory.glob("*.sqlite3").sort
    puts "No backups in #{backup_directory}" if snapshots.empty?
    snapshots.each { |file| puts "#{file.mtime.strftime("%Y-%m-%d %H:%M")}  #{(file.size / 1024).to_s.rjust(6)} KB  #{file}" }
  end

  def backup_directory
    Pathname(ENV.fetch("BACKUP_DIR", Rails.root.join("storage/backups").to_s)).expand_path
  end
end
