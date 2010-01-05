require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'tzinfo'

configure :production do
  # Configure stuff here you'll want to only be run at Heroku at boot.
  # TIP:  You can get you database information
  #       from ENV['DATABASE_URI'] (see /env route below)
end

helpers do
  def get_melbourne_time
    time_now = TZInfo::Timezone.get('Australia/Melbourne').now
    # Testing: time_now = Time.local(2010, "jan", 10, 11, 10, 00)
  end

  def get_service_info
    time_now = get_melbourne_time()

    svc_start = time_now

    svc_start += 60*60*24 while svc_start.wday != 0
    svc_start -= 1 while svc_start.sec != 0
    svc_start -= 60 while svc_start.min != 0
    svc_start -= 60*60 while svc_start.hour != 0
    svc_start += 60*60*11 # 11.00 AM
    svc_end = svc_start + 5400 # 12:30 PM

    if time_now < svc_start # The service hasn't started yet.
      ret_on_now = false
      ret_next_svc_start = svc_start
    elsif time_now > svc_end # The service has ended.
      ret_on_now = false
      ret_next_svc_start = svc_start + 60*60*24*7
    else # The service is on now.
      ret_on_now = true
      ret_next_svc_start = svc_start + 60*60*24*7
    end

    return [ret_on_now, ret_next_svc_start]
  end

  def get_time_diff(time)
    ret_days = ret_hours = ret_mins = 0

    time_now = get_melbourne_time()

    time_diff = time - time_now

    t_diff_secs  = time_diff.to_int
    t_diff_mins  = t_diff_secs / 60
    t_diff_hours = t_diff_mins / 60
    t_diff_days  = t_diff_hours / 24

    ret_days = t_diff_days if t_diff_days > 0
    ret_hours = t_diff_hours % 24 if t_diff_hours > 0
    ret_mins = t_diff_mins % 60 if t_diff_mins > 0

    return [ret_days, ret_hours, ret_mins]
  end
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

not_found do
  haml :notfound
end

error do
  haml :error
end
 
get '/' do
  @title = 'Is the Service at LSCC on now?'
  @mtime = get_melbourne_time()

  info = get_service_info()
  @is_service_on_now = info[0]
  @next_service_time = info[1]

  time_diff = get_time_diff(info[1])
  @next_service_days = time_diff[0]
  @next_service_hours = time_diff[1]
  @next_service_mins = time_diff[2]

  haml :index
end
 
# Test at <appname>.heroku.com
# You can see all your app specific information this way.
# IMPORTANT! This is a very bad thing to do for a production
# application with sensitive information.
 
# get '/env' do
#   ENV.inspect
# end
