# Season keys used to be the exam month ("202701" for the January 2027 exams). They are
# now the month the season starts, three months earlier ("202610"), so every stored
# key moves back three months and each enrollment keeps the same exams.
class ShiftSeasonKeysToSeasonStart < ActiveRecord::Migration[8.1]
  def up
    shift_season_keys(-3)
  end

  def down
    shift_season_keys(3)
  end

  private

  # Row by row from a snapshot: old and new keys overlap ("202604" becomes "202601",
  # which is itself an old key), so a key-by-key UPDATE would shift some rows twice.
  def shift_season_keys(months)
    select_rows("SELECT id, season_key FROM enrollments").each do |id, key|
      next unless key.to_s.match?(/\A\d{6}\z/)

      shifted = (Date.strptime(key, "%Y%m") >> months).strftime("%Y%m")
      execute("UPDATE enrollments SET season_key = #{quote(shifted)} WHERE id = #{quote(id)}")
    end
  end
end
