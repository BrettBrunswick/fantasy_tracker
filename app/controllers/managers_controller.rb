class ManagersController < ApplicationController
  before_action :require_login

  def index
    @managers = Manager.all.order(:name)
  end

  def show
    @manager = Manager.find(params[:id])
    @lifetime_records = @manager.lifetime_records.includes(:league)
    @aggregated_stats = aggregate_stats(@lifetime_records)
    @head_to_head = aggregate_head_to_head(@manager)
  end

  private

  def aggregate_stats(records)
    total_wins = records.sum(&:total_wins)
    total_losses = records.sum(&:total_losses)
    total_ties = records.sum(&:regular_season_ties)
    playoff_wins = records.sum(&:playoff_wins)
    playoff_losses = records.sum(&:playoff_losses)
    champ_wins = records.sum(&:championships_won)
    champ_losses = records.sum(&:championships_lost)

    {
      total_record: format_record(total_wins, total_losses, total_ties),
      total_win_pct: calc_win_pct(total_wins, total_losses, total_ties),
      playoff_record: format_record(playoff_wins, playoff_losses, 0),
      playoff_win_pct: calc_win_pct(playoff_wins, playoff_losses, 0),
      championship_record: format_record(champ_wins, champ_losses, 0),
      championship_win_pct: calc_win_pct(champ_wins, champ_losses, 0),
      first_place: records.sum(&:first_place_finishes),
      second_place: records.sum(&:second_place_finishes),
      third_place: records.sum(&:third_place_finishes),
      total_points_for: records.sum(&:total_points_for),
      total_points_against: records.sum(&:total_points_against)
    }
  end

  def format_record(wins, losses, ties)
    ties.positive? ? "#{wins}-#{losses}-#{ties}" : "#{wins}-#{losses}"
  end

  def calc_win_pct(wins, losses, ties)
    total = wins + losses + ties
    return 0.0 if total.zero?
    (wins.to_f + ties.to_f / 2) / total
  end

  def aggregate_head_to_head(manager)
    # Get all head-to-head records grouped by opponent
    records = manager.head_to_head_records.includes(:opponent_manager, :league)

    # Aggregate by opponent across all leagues
    by_opponent = records.group_by(&:opponent_manager).map do |opponent, h2h_records|
      wins = h2h_records.sum(&:total_wins)
      losses = h2h_records.sum(&:total_losses)
      ties = h2h_records.sum(&:regular_season_ties)
      total = wins + losses + ties

      {
        opponent: opponent,
        record: format_record(wins, losses, ties),
        wins: wins,
        losses: losses,
        win_percentage: total.positive? ? (wins.to_f + ties.to_f / 2) / total : 0,
        current_streak: calculate_combined_streak(manager, opponent)
      }
    end

    by_opponent.sort_by { |h| [-h[:wins], h[:opponent].name] }
  end

  def calculate_combined_streak(manager, opponent)
    # Get all matchups between these two managers across all leagues, ordered by date
    manager_team_ids = manager.teams.pluck(:id)
    opponent_team_ids = opponent.teams.pluck(:id)

    matchups = Matchup.joins(season: :league)
      .where(
        "(team_1_id IN (?) AND team_2_id IN (?)) OR (team_1_id IN (?) AND team_2_id IN (?))",
        manager_team_ids, opponent_team_ids, opponent_team_ids, manager_team_ids
      )
      .order("seasons.year DESC, matchups.week DESC")

    streak_type = nil
    streak_count = 0

    matchups.each do |matchup|
      manager_team = manager_team_ids.include?(matchup.team_1_id) ? matchup.team_1 : matchup.team_2
      manager_score = matchup.score_for(manager_team)
      opponent_score = matchup.score_for(matchup.opponent_for(manager_team))

      next if manager_score.nil? || opponent_score.nil?
      next if manager_score.zero? && opponent_score.zero? # Skip unplayed games
      next if manager_score == opponent_score # Skip ties for streak purposes

      result = manager_score > opponent_score ? :win : :loss

      if streak_type.nil?
        streak_type = result
        streak_count = 1
      elsif streak_type == result
        streak_count += 1
      else
        break
      end
    end

    return "-" if streak_type.nil?
    streak_type == :win ? "W#{streak_count}" : "L#{streak_count}"
  end
end
