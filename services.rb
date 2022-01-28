# frozen_string_literal: true

class TimeOffSearch < ApplicationSearch
  option :status, optional: true, default: proc { :with_time_off }
  option :team_id, optional: true
  option :project_id, optional: true
  option :year, optional: true, default: proc { Date.today.year }
  option :month, optional: true, default: proc { Date.today.month }

  def call(members)
    @query = members
    @query = reduce_by_time_off if status
    @query = reduce_by_team if team_id
    @query = reduce_by_project if project_id
    @query
  end

  private

  def reduce_by_team
    @query.joins(:teams).where(teams: team_id)
  end

  def reduce_by_project
    @query.joins(:projects).where(projects: project_id)
  end

  def reduce_by_time_off
    searches = {
      with_time_off: @query.joins(:time_offs).merge(
        TimeOff.within_month(Date.new(year.to_i, month.to_i)).pending_or_approved
      ).distinct,
      current: @query.joins(:contracts).merge(Contract.active)
    }

    searches.fetch(status.to_sym, {})
  end
end


#========================
# frozen_string_literal: true

class StartersLeaversReport < ApplicationReport
  option :members
  option :start_date, default: proc { Date.today - 1.year }, type: proc(&:to_date)
  option :end_date, default: proc { Date.today }, type: proc(&:to_date)

  def to_chart_data
    {
      labels: raw_data[0],
      datasets: [
        {
          label: I18n.t('reports.label.leavers'),
          data: raw_data[1],
          backgroundColor: '#F87171'
        },
        {
          label: I18n.t('reports.label.starters'),
          data: raw_data[2],
          backgroundColor: '#2DD4BF'
        }
      ]
    }
  end

  def to_table_data
    hash = {}

    raw_data[0].each_with_index do |date, index|
      hash[date] = { leavers_count: raw_data[1][index], starters_count: raw_data[2][index] }
    end

    hash
  end

  private

  def raw_data
    dates = create_dates

    @raw_data = [
      dates.map { |m| "#{Date::MONTHNAMES[m.last]} #{m.first}" },
      leavers_or_starters(dates, :fired_date, members.leavers_between(start_date, end_date)),
      leavers_or_starters(dates, :hired_date, members.starters_between(start_date, end_date))
    ]
  end

  def create_dates
    current_date = start_date
    last_date = end_date.change(day: -1)

    date_tuples = []

    while current_date <= last_date
      date_tuples.push([current_date.year, current_date.month])
      current_date = current_date.next_month
    end

    date_tuples
  end

  def leavers_or_starters(dates, type_of_date, members)
    hash = dates.map { |date| [date, 0] }.to_h
    members.pluck(type_of_date).each do |date|
      next if hash[[date&.year, date&.month]].nil?
      hash[[date&.year, date&.month]] += 1
    end
    hash.values
  end
end
