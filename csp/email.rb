# encoding: UTF-8
require "cgi"

apikey = "<MAILGUN APIKEY>"
from = "who@you.want"

to = "who@you.want"
subject = "New Message"
body = ""

# Get arguments
k = ""
@params = {}
ARGV.each do|a|
  if a.split("=").size > 1    
    a = a.split("=")
    @params[a[0]] = a[1]
  else
    if k == ""      
      k = a
    else
      @params[k] = a
      k = ""
    end
  end
end

@params.each do |k, v|
  body += "#{k}: #{CGI::unescape(v).gsub("'", "‘")}\n"
end

#body += "\n\n #{ENV.inspect}"

if @params["fname"].to_s.strip == "" # honey pot
  command = "curl -s --user 'api:#{apikey}' \
    https://api.mailgun.net/v2/solisoft.net/messages \
    -F from='#{from}' \
    -F to=#{to} \
    -F subject='#{subject}' \
    -F text='#{body}'"
  system command
  puts "OK"
else
  puts "NOK"
end

exit 200
