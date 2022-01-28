class TeamPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    relation = relation.where(company: member.company)

    return relation if member.manager?
    if member.employee?
      return relation.joins(:members).and(Team.visible.or(Team.hidden.where(members: member))).distinct
    end

    relation.none
  end

  def show?
    if record.private?
      return same_company? && member.manager? || same_company? && have_team?
    end
    same_company? && member
  end

  def leave?
    same_company? && have_team?
  end

  protected

  def have_team?
    member.team_ids.include?(record.id)
  end

  def same_company?
    member.company_id == record.company_id
  end
end
