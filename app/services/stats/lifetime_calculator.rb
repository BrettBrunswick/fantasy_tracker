module Stats
  class LifetimeCalculator
    def initialize(league)
      @league = league
    end

    def calculate_all
      @league.managers.find_each do |manager|
        calculate_for_manager(manager)
      end
    end

    def calculate_for_manager(manager)
      record = LifetimeRecord.find_or_initialize_by(
        manager: manager,
        league: @league
      )

      stats = calculate_stats(manager)

      record.update!(
        regular_season_wins: stats[:regular_season_wins],
        regular_season_losses: stats[:regular_season_losses],
        regular_season_ties: stats[:regular_season_ties],
        playoff_wins: stats[:playoff_wins],
        playoff_losses: stats[:playoff_losses],
        championships_won: stats[:championships_won],
        championships_lost: stats[:championships_lost],
        total_points_for: stats[:total_points_for],
        total_points_against: stats[:total_points_against]
      )

      record
    end

    private

    def calculate_stats(manager)
      teams = manager.teams.joins(:season).where(seasons: { league_id: @league.id })
      team_ids = teams.pluck(:id)

      matchups = Matchup.where("team_1_id IN (?) OR team_2_id IN (?)", team_ids, team_ids)

      stats = {
        regular_season_wins: 0,
        regular_season_losses: 0,
        regular_season_ties: 0,
        playoff_wins: 0,
        playoff_losses: 0,
        championships_won: 0,
        championships_lost: 0,
        total_points_for: 0,
        total_points_against: 0
      }

      matchups.find_each do |matchup|
        team = team_ids.include?(matchup.team_1_id) ? matchup.team_1 : matchup.team_2
        opponent_team = matchup.opponent_for(team)

        my_score = matchup.score_for(team)
        opponent_score = matchup.score_for(opponent_team)

        stats[:total_points_for] += my_score || 0
        stats[:total_points_against] += opponent_score || 0

        next if my_score.nil? || opponent_score.nil?

        case matchup.matchup_type
        when "regular_season"
          if my_score > opponent_score
            stats[:regular_season_wins] += 1
          elsif my_score < opponent_score
            stats[:regular_season_losses] += 1
          else
            stats[:regular_season_ties] += 1
          end
        when "playoff", "consolation"
          if my_score > opponent_score
            stats[:playoff_wins] += 1
          elsif my_score < opponent_score
            stats[:playoff_losses] += 1
          end
        when "championship"
          if my_score > opponent_score
            stats[:championships_won] += 1
            stats[:playoff_wins] += 1
          elsif my_score < opponent_score
            stats[:championships_lost] += 1
            stats[:playoff_losses] += 1
          end
        end
      end

      stats
    end
  end
end
