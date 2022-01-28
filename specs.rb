
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeOffSearch do
  let(:company) { build(:company) }
  let(:members) { company.members }

  let(:member) { create(:member_with_contract, company: company, first_name: 'Andrey', last_name: 'Nak') }
  let(:team) { build(:team, title: 'Front-end', company: company, members: [member]) }
  let(:project) { build(:project, company: company, members: [member]) }
  let(:time_off) {
    build(
      :time_off,
      start_date: start_date,
      end_date: end_date,
      approver_ids: approver_ids,
      status: status,
      member: member
    )
  }

  let(:start_date) { Date.today - 1.week }
  let(:end_date) { Date.today + 2.weeks }
  let(:first_approver) { create(:member_with_contract) }
  let(:status) { 'approved' }
  let(:second_approver) { create(:member_with_contract) }
  let(:approver_ids) { [first_approver.id, second_approver.id] }

  before {
    team.save
    project.save
    time_off.save
  }

  describe '#call' do
    subject { described_class.new(**search_params).call(members) }

    let(:search_params) { EMPTY_HASH }

    describe 'when time off approved' do
      let(:search_params) { { company: company, year: Date.today.year, month: Date.today.month } }

      let(:status) { 'approved' }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).to include(member)
      end
    end

    describe 'when time off pending' do
      let(:search_params) { { company: company, year: Date.today.year, month: Date.today.month } }

      let(:status) { 'pending' }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).to include(member)
      end
    end

    describe 'when select next month' do
      let(:search_params) { { company: company, year: Date.today.year, month: Date.today.month + 1 } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).not_to include(member)
      end
    end

    describe 'when select previous month' do
      let(:search_params) { { company: company, year: Date.today.year, month: Date.today.month - 1 } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).not_to include(member)
      end
    end

    describe 'when select current month' do
      let(:search_params) { { company: company, year: Date.today.year, month: Date.today.month } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).to include(member)
      end
    end

    context 'when selected available team' do
      let(:search_params) { { company: company, team_id: team.id } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).to include(member)
      end
    end

    context 'when selected  not available team' do
      let(:search_params) { { company: company, team_id: team.id + 1 } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).not_to eq(members)
      end
    end

    context 'when selected available project' do
      let(:search_params) { { company: company, project_id: project.id } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).to include(member)
      end
    end

    context 'when selected  not available project' do
      let(:search_params) { { company: company, project_id: project.id + 1 } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).not_to include(member)
      end
    end

    context 'when selected with time_off employees' do
      let(:search_params) { { company: company, status: 'with_time_off' } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).to include(member)
      end
    end

    context 'when selected current employees' do
      let(:search_params) { { company: company, status: 'current' } }

      it do
        expect(subject).to be_a(ActiveRecord::Relation)
        expect(subject).to include(member)
      end
    end

    context 'when selected invalid status' do
      let(:search_params) { { company: company, status: 'trash' } }

      it { is_expected.not_to eq(members) }
    end
  end
end


# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Member, type: :model do
  subject(:member) do
    build(:member, company: company) do |member|
      FactoryBot.build_list(:contract, 2, member: member)
    end
  end

  let(:company) { build(:company) }

  it { is_expected.to be_valid }

  describe '#locale' do
    subject { member.locale }

    it { is_expected.not_to be_nil }
    it { is_expected.to eq(I18n.default_locale.to_s) }
  end

  describe '#salary' do
    subject { member.salary }

    let(:member) { create(:member_with_contract) }

    context 'when member doesnt have gross salary amount' do
      before { member.current_contract.gross_salary_amount = nil }

      it { is_expected.to be_zero }
    end

    context 'when member doesnt have active contract' do
      before do
        member.current_contract.start_date = Date.today - 1.month
        member.current_contract.end_date = Date.today - 1.week
      end

      it { is_expected.to be_zero }
    end

    context 'when member has gross salary amount' do
      before { member.current_contract.gross_salary_amount = 1000 }

      it { is_expected.to eq(1000) }
    end
  end
end