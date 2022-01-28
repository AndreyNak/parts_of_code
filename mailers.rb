# frozen_string_literal: true

class MemberMailer < ApplicationMailer
  def fill_out_profile
    @member = params[:member]

    mail to: @member.email, subject: 'Please fill in your profile'
  end
end


namespace :mails do
  task members_fill_out_profile: :environment do
    Member.not_filled_profiles.each do |member|
      MemberMailer.with(member: member).fill_out_profile.deliver_now
    end
  end
end