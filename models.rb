
  scope :pending_or_approved, -> {
    pending.or(approved)
  }

  scope :order_by_start_date, -> {
    order(:start_date)
  }

  scope :order_by_end_date, -> {
    order(:end_date)
  }

  scope :current_or_upcoming, -> {
    where(TimeOff.arel_table[:end_date].gteq(Date.today))
  }

  scope :upcoming, -> {
    time_offs = TimeOff.arel_table[:start_date]

    where(
      time_offs.gt(Date.today).and(
        time_offs.lt(Date.today + 2.weeks)
      )
    )
  }

scope :current, -> {
  time_offs = TimeOff.arel_table

  where(
    time_offs[:start_date].lteq(Date.today).and(
      time_offs[:end_date].gteq(Date.today)
    )
  )
}

def birthday_in_this_year
  date_of_birth.change(year: Date.today.year)
end

def birthday_in_next_year
  date_of_birth.change(year: Date.today.year.next)
end

def days_until_birthday
  return unless date_of_birth

  if birthday_passed?
    (birthday_in_next_year - Date.today).to_i
  else
    (birthday_in_this_year - Date.today).to_i
  end
end

def birthday_today?
  return unless date_of_birth

  Date.today == birthday_in_this_year
end

def birthday_passed?
  return unless date_of_birth

  Date.today > birthday_in_this_year
end

def birthday_will_be?
  return unless date_of_birth

  Date.today < birthday_in_this_year
end