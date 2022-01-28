def index
  authorize! Member

  search_params = params.slice(:status, :search, :team_id, :project_id).to_unsafe_hash
  members = MembersSearch.new(**search_params).call(members_collection)

  respond_to do |format|
    format.html {
      render locals: {
        members: members,
        teams: teams_collection,
        projects: current_company.projects
      }
    }
  end
end



def starters_leavers
  authorize! current_company, to: :manage_reports?

  search_params = params.slice(
    :start_date,
    :end_date
  ).to_unsafe_hash.merge(members: current_company.members.ordered_by_full_name)
  report = StartersLeaversReport.new(**search_params)

  render locals: {
    chart_data: report.to_chart_data,
    list: report.to_table_data
  }
end



def salary
  authorize! current_company, to: :manage_financial_reports?

  report = ProjectsTeamsReport.new(
    name_relation: params['type'],
    relation: relations(params['type']),
    param: :total_salary
  )
  render locals: {
    chart_data: report.to_chart_data,
    collection: report.to_table_data,
    name: report.name
  }
end
