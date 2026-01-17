module Stats
  class HeadToHeadCalculator
    def initialize(league)
      @league = league
    end

    def calculate_all
      managers = @league.managers.to_a

      managers.combination(2).each do |manager_1, manager_2|
        calculate_for_pair(manager_1, manager_2)
      end
    end

    def calculate_for_pair(manager_1, manager_2)
      stats = calculate_stats(manager_1, manager_2)

      update_record(manager_1, manager_2, stats)
      update_record(manager_2, manager_1, inverse_stats(stats))
    end

    def calculate_for_manager(manager)
      @league.managers.where.not(id: manager.id).find_each do |opponent|
        calculate_for_pair(manager, opponent)
      end
    end

    private

    def calculate_stats(manager_1, manager_2)
      teams_1 = manager_1.teams.joins(:season).where(seasons: { league_id: @league.id })
      teams_2 = manager_2.teams.joins(:season).where(seasons: { league_id: @league.id })

      team_1_ids = teams_1.pluck(:id)
      team_2_ids = teams_2.pluck(:id)

      matchups = Matchup.joins(:season).where(
        "(team_1_id IN (?) AND team_2_id IN (?)) OR (team_1_id IN (?) AND team_2_id IN (?))",
        team_1_ids, team_2_ids, team_2_ids, team_1_ids
      ).order("seasons.year DESC, matchups.week DESC")

      stats = {
        regular_season_wins: 0,
        regular_season_losses: 0,
        regular_season_ties: 0,
        playoff_wins: 0,
        playoff_losses: 0,
        current_streak: nil
      }

      streak_type = nil
      streak_count = 0

      matchups.each do |matchup|
        manager_1_team = team_1_ids.include?(matchup.team_1_id) ? matchup.team_1 : matchup.team_2
        manager_1_score = matchup.score_for(manager_1_team)
        manager_2_score = matchup.score_for(matchup.opponent_for(manager_1_team))

        next if manager_1_score.nil? || manager_2_score.nil?
        next if manager_1_score.zero? && manager_2_score.zero? # Skip unplayed games

        is_playoff = matchup.playoff? || matchup.championship? || matchup.consolation?

        if manager_1_score > manager_2_score
          is_playoff ? stats[:playoff_wins] += 1 : stats[:regular_season_wins] += 1
          if streak_type.nil?
            streak_type = :win
            streak_count = 1
          elsif streak_type == :win
            streak_count += 1
          end
        elsif manager_1_score < manager_2_score
          is_playoff ? stats[:playoff_losses] += 1 : stats[:regular_season_losses] += 1
          if streak_type.nil?
            streak_type = :loss
            streak_count = 1
          elsif streak_type == :loss
            streak_count += 1
          end
        else
          stats[:regular_season_ties] += 1 unless is_playoff
        end
      end

      stats[:current_streak] = streak_type ? "#{streak_type == :win ? 'W' : 'L'}#{streak_count}" : "-"
      stats
    end

    def inverse_stats(stats)
      streak = stats[:current_streak]
      inverted_streak = if streak == "-"
        "-"
      elsif streak&.start_with?("W")
        "L#{streak[1..]}"
      elsif streak&.start_with?("L")
        "W#{streak[1..]}"
      else
        "-"
      end

      {
        regular_season_wins: stats[:regular_season_losses],
        regular_season_losses: stats[:regular_season_wins],
        regular_season_ties: stats[:regular_season_ties],
        playoff_wins: stats[:playoff_losses],
        playoff_losses: stats[:playoff_wins],
        current_streak: inverted_streak
      }
    end

    def update_record(manager, opponent, stats)
      record = HeadToHeadRecord.find_or_initialize_by(
        manager: manager,
        opponent_manager: opponent,
        league: @league
      )

      record.update!(
        regular_season_wins: stats[:regular_season_wins],
        regular_season_losses: stats[:regular_season_losses],
        regular_season_ties: stats[:regular_season_ties],
        playoff_wins: stats[:playoff_wins],
        playoff_losses: stats[:playoff_losses],
        current_streak: stats[:current_streak]
      )

      record
    end
  end
end
