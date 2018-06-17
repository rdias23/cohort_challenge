class HomeController < ApplicationController
  def index
  	max_weeks_back_needed = yield_max_weeks_back_needed
  	@week_options_for_select = (1..max_weeks_back_needed).to_a

    params["cohort_weeks_requested"].blank? ? @weeks_back_requested = 8 : @weeks_back_requested = params["cohort_weeks_requested"].to_i

    @cohort_info_hsh_arr = []

    (1..@weeks_back_requested).each do |week_num|
      cohort_info_hsh = self.yield_blank_cohort_info_hsh

      # prunes the week_blocks down to only the ones requested
      cohort_info_hsh[:week_blocks] = Hash[cohort_info_hsh[:week_blocks].sort_by { |k,v| (k.to_s.sub(/week_/,"").to_i) }[0...@weeks_back_requested]]
      cohort_info_hsh[:name] = self.get_cohort_name(week_num)

      cohort_users = get_user_signups_for_week(week_num)
      cohort_info_hsh[:user_count] = cohort_users.length
      # Hashes are ordered since Ruby 1.9 but not on older Rubies.
      cohort_info_hsh[:week_blocks].each_with_index do |(k,v),index|
      	if (index + 1) > week_num
          cohort_info_hsh[:week_blocks][k] = nil
      	else
          cohort_user_orders = get_user_orders_for_week((index + 1),cohort_users.ids)

          uniq_users_who_ordered_num = cohort_user_orders.map(&:csv_user_id).uniq.length
          first_cohort_user_orders_num = cohort_user_orders.select { |order| order.csv_order_num == 1 }.length

          cohort_info_hsh[:week_blocks][k][:num_users_ordered] = uniq_users_who_ordered_num
          cohort_info_hsh[:week_blocks][k][:num_users_ordered_first_time] = first_cohort_user_orders_num
          unless cohort_users.length == 0
            cohort_info_hsh[:week_blocks][k][:percent_users_ordered] = ((uniq_users_who_ordered_num * 100.0) / cohort_users.length).round(2)
            cohort_info_hsh[:week_blocks][k][:percent_users_ordered_first_time] = ((first_cohort_user_orders_num * 100.0) / cohort_users.length).round(2)
          end
        end
      end
      cohort_info_hsh[:week_blocks].delete_if { |k, v| v.blank? }

      @cohort_info_hsh_arr << cohort_info_hsh

    end

  end

  protected

  def get_cohort_name(week_num)
  	first_cohort_second = self.yield_limit_second_for_first_cohort_inclusion.to_f - (self.yield_seconds_in_a_week * week_num.to_f)
  	last_cohort_second = self.yield_limit_second_for_first_cohort_inclusion.to_f - (self.yield_seconds_in_a_week * (week_num.to_f - 1))

  	begin_time = Time.find_zone("Pacific Time (US & Canada)").at(first_cohort_second)
  	end_time = Time.find_zone("Pacific Time (US & Canada)").at(last_cohort_second - 1.second)

  	cohort_name = begin_time.strftime('%m/%d').split("/").map { |num| num.to_i.to_s }.join("/") +
  	                "-" +
  	                  end_time.strftime('%m/%d').split("/").map { |num| num.to_i.to_s }.join("/")

  	return cohort_name
  end

  def get_user_signups_for_week(week_num)
  	first_cohort_second = self.yield_limit_second_for_first_cohort_inclusion.to_f - (self.yield_seconds_in_a_week * week_num.to_f)
  	last_cohort_second = self.yield_limit_second_for_first_cohort_inclusion.to_f - (self.yield_seconds_in_a_week * (week_num.to_f - 1))

  	users = User.where(:csv_created_at => Time.at(first_cohort_second)..Time.at(last_cohort_second))

  	return users
  end

  def get_user_orders_for_week(week_num,user_id_arr)
  	first_cohort_second = self.yield_limit_second_for_first_cohort_inclusion.to_f - (self.yield_seconds_in_a_week * week_num.to_f)
  	last_cohort_second = self.yield_limit_second_for_first_cohort_inclusion.to_f - (self.yield_seconds_in_a_week * (week_num.to_f - 1))

  	orders = Order.joins(:user).where("users.id" => user_id_arr).where(:csv_created_at => Time.at(first_cohort_second)..Time.at(last_cohort_second))
  	return orders
  end

  def yield_blank_cohort_info_hsh
    {:name => nil, :user_count => nil, :week_blocks => self.yield_week_block_hsh_for_cohort_info_hsh}
  end

  def yield_week_block_hsh_for_cohort_info_hsh
  	max_weeks_back_needed = self.yield_max_weeks_back_needed
  	hsh = {}
  	(1..max_weeks_back_needed).each do |n|
      hsh[("week_" + n.to_s).to_sym] = self.yield_week_block_stats_hsh
    end

    return hsh
  end

  def yield_week_block_stats_hsh
    {:percent_users_ordered => nil, :num_users_ordered => nil, :percent_users_ordered_first_time => nil, :num_users_ordered_first_time => nil}
  end

  def yield_max_weeks_back_needed
  	# we take the stroke of midnight ending the day on July 7th 2013 (the final second!)...
  	# in the Pacific Time Zone...
  	# as the end point of our most recent week-long group, or cohort... Cohorts are 1 week blocks,
  	# counting back from there!
  	limit_second_for_first_cohort_inclusion = self.yield_limit_second_for_first_cohort_inclusion
  	max_weeks_back_needed = ((limit_second_for_first_cohort_inclusion - User.all.order("csv_created_at DESC").last.csv_created_at.to_i) / 60.0 / 60.0 / 24.0 / 7.0).ceil
  	return max_weeks_back_needed
  end

  def yield_limit_second_for_first_cohort_inclusion
    (Time.find_zone("Pacific Time (US & Canada)").local(2013,7,8)).to_i
  end

  def yield_seconds_in_a_week
    (7 * 24 * 60 * 60).to_f
  end
end
