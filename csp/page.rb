# [solicms] page.rb
# Author: Olivier BONNAURE

file = "home" # Default page must be defined
@lang = "en" # Default language must be defined too

t1 = Time.now # measuring time

@site_path = ENV["PATH_TRANSLATED"].split("/")[0..-2].join("/")
@www = "#{@site_path}/www/"
k = ""
@params = {}

# Get arguments
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
@params["page"] ||= 1
@layout = ""

# analyze_template(filename)
def analyze_template(filename)
  tmp = ""
  collect = { :data => false, :css => false, :js => false }
  item = ""
  name = "application"
  load = { :css => true, :js => true }
  
  load[:css] = !File.exists?("#{@www}#{name}.css")
  load[:js] = !File.exists?("#{@www}#{name}.js")
  
  if not File.exists? filename
    filename = "#{@www}home.#{@lang}.soli"
    #exit 404
  end
  IO.readlines(filename).each do |line|
    if line[0..6] == ":layout"
      analyze_template "#{@www}#{line[7..-1].strip}"
    end
    if line[0..4] == ":page"
      @layout = IO.read "#{@www}#{line[5..-1].strip}" rescue ""
    end
    if line[0..4] == ":name"
      name = line[5..-1].strip
      load[:css] = !File.exists?("#{@www}#{name}.css")
      load[:js] = !File.exists?("#{@www}#{name}.js")
    end
    
    if ["#", ":", "@"].include?(line[0])
      unless item == ""
        #
        @layout.gsub!("<!-- #{item} -->", tmp)
        item  = ""
        tmp   = ""
      end
      if collect[:css]
        Dir.mkdir "#{@www}cache/" rescue nil
        IO.write "#{@www}cache/#{name}.css", tmp unless File.exists? "#{@www}cache/#{name}.css"
        @layout.gsub!("<!-- :css -->", "<link rel='stylesheet' type='text/css' href='/cache/#{name}.css' />")
        tmp = ""
        collect[:css] = false
      end
      if collect[:js]
        Dir.mkdir "#{@www}cache/" rescue nil
        IO.write "#{@www}cache/#{name}.js", tmp unless File.exists? "#{@www}cache/#{name}.js"
        @layout.gsub!("<!-- :js -->", "<script src='/cache/#{name}.js'></script>")
        tmp = ""
        collect[:js] = false
      end
    end
    
    if line[0..3] == ":css"
      collect[:css] = true
    end

    if line[0..2] == ":js"
      collect[:js] = true
    end
    
    if line[0] == "#"
      item = line.strip
      collect[:data] = true
    end

    if not ["#", ":", "@"].include?(line[0]) and collect[:data]
      tmp += line
    end
    if not ["#", ":", "@"].include?(line[0]) and (collect[:css] or collect[:js]) and line.strip.size > 0
      tmp += IO.read "#{@www}#{line.strip}" rescue ""
      tmp += "\n"
    end
  end
end

def convert_inclusions
  reload = false
  @layout.scan(/{{(.+)}}/i).each do |i|
    if(i[0].split(" ").first == "load")
      @layout.gsub!("{{#{i[0]}}}", IO.read(@www + i[0].split(" ").last)) if File.exists?(@www + i[0].split(" ").last)
      reload = true
    end
    if(i[0] == "date")
      @layout.gsub!("{{#{i[0]}}}", Time.now.to_s)
    end
    if(i[0].split(" ").first == "active")
      @layout.gsub!("{{#{i[0]}}}", "active") if i[0].split(" ").last == @filename
    end
    if(i[0].split(" ").first == "lang")
      @layout.gsub!("{{#{i[0]}}}", @lang)
    end
  end
  convert_inclusions if reload
end

def convert_widget
  widgets = @layout.scan /{{widget\s+([\w|=\d;@]+)}}/i
  widgets.each do |w|
    widget = IO.read "#{@www}widgets/#{w[0].split("|").first}.soli"
    options = {}
    w[0].split("|").last.to_s.split(";").each do |o|
      #puts o
      o = o .split "="
      options[o.first] = o.last
    end
    html = ""
    options["limit"] ||= 100
    offset = (@params["page"].to_i - 1) * options["limit"].to_i
    template = ""
    widget.split("\n").each do |l|
      if l[0] == ":"
        options[l.split(" ").first.gsub(":","")] = l.split(" ")[1..-1].join(" ")#.last.strip
      else
        template += l.strip
      end
    end

    if options["source"].to_s != ""
      docs = []
      
      if options["source"][0] == "$"
        options["source"] = @params[options["source"].gsub("$", "")].gsub("%2F","/") + "@online"
      end
      
      basic_filter = "*@online*"
      basic_filter = "*.jpg" if @params["album"] # don't filter if album parameter is present

      if options["filter"] and options["filter"] != "off"
        docs = Dir.glob("#{@www}#{options["source"]}/#{basic_filter}").map{|l| l if l =~ /#{@params[options["filter"]]}/ }.compact
      else
        docs = Dir.glob("#{@www}#{options["source"]}/#{basic_filter}")
      end
      
      docs.sort.reverse[offset..(offset + options["limit"].to_i - 1)].each_with_index do |path, i|
        html += generate_template(template, path, options, i)
      end
      html += options["after"].to_s
      html += paginate(options, docs.size)
    else
      path = Dir.glob("#{@www}#{options["path"]}/#{@params[options['data'].gsub("@", "")]}*").first
      html += generate_template(template, path, options, 0) if options['data']
      html += options["after"].to_s
    end
    widget = html
    # add pagination

    #widget = analyze_widget widget, options
    @layout.gsub!("{{widget #{w[0]}}}", widget) 
  end
end

def generate_template(template, path, options, index)
  collect = {}
  rub = ""
  content = ""
  html = ""

  debug = []
  options["items"] ||= 10
  html += options["after"] if options["after"] and index % options["items"].to_i == 0 and index > 0
  html += options["before"] if options["before"] and index % options["items"].to_i == 0
  html += template if File.exists?(path) and File.directory?(path)
  html += template unless @params["album"].nil?
  
  if File.exists?(path) and File.file?(path) and @params["album"].nil?
    IO.readlines(path).each do |line|
      if line[0] == ":"
        if content != "" and rub != ""
          collect[rub] = content
          content = ""
        end
        rub = line.gsub(":", "").strip
      else
        content += line
      end
    end
    if content != "" and rub != ""
      collect[rub] = content
    end
    by = @params[options["tag"]]
    #puts by.inspect
    by = nil if(options["filter"] == "off")
    html = template.dup if by and collect["tags"].split(",").map{|l| l.downcase.strip}.include?(by)
    html = template.dup if by.to_s == ""
    y, m, d, h, min = path.split("/").last.split(".").first.split('-').first.scan(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/).first
    html.gsub! "{{date}}", Time.new(y,m,d,h,min).to_s 
  end


  if File.exists?(path) and File.directory?(path)
    if File.exists?(path + "/info.txt")
      IO.readlines(path+"/info.txt").each do |line|
        if line[0] == ":"
          if content != "" and rub != ""
            collect[rub] = content
            content = ""
          end
          rub = line.gsub(":", "").strip
        else
          content += line
        end
      end
    end
  end
  if content != "" and rub != ""
    collect[rub] = content
  end

  template.scan(/{{text\s+([\w\.|\(\)\d;]+)}}/i).each do |a|
    text = collect[a[0].split("|").first.gsub("#{options["model"]}.", "")]
    text = apply_transform(text, a[0].split("|").last) if a[0].split("|").size == 2
    html.gsub! "{{text #{a[0]}}}", text.to_s
  end
  template.scan(/{{imgSrc\s+([\w\.=<>|#]+)}}/i).each do |a|
    text = collect[a[0].split("|").first.gsub("#{options["model"]}.", "")]
    imgOptions = {}
    text.split("|").last.to_s.split(";").each do |o|
      o = o .split "="
      imgOptions[o.first] = o.last
    end

    #if imgOptions["size"].to_s != ""
      #if !File.exists? img + ".lnk"
      #  img = "#{@www.gsub("#", "\\#")}#{text.split("|").first}".gsub("//","/")
      #  system("convert  #{img} -resize '#{imgOptions["size"].split("#").first}' #{img}")
      #end
    #end
    html.gsub! "{{imgSrc #{a[0]}}}", text.to_s.split("|").first
  end
  template.scan(/{{markdown\s+([\w\.|\(\)\d]+)}}/i).each do |a|
    text = collect[a[0].split("|").first.gsub("#{options["model"]}.", "")]
    text = apply_transform(text, a[0].split("|").last) if a[0].split("|").size == 2
    html.gsub! "{{markdown #{a[0]}}}", text.to_s
  end

  template.scan(/{{tags\s+([\w\.|\(\)\d;]+)}}/i).each do |a|
    text = []
    collect[a[0].split("|").first.gsub("#{options["model"]}.", "")].split(",").each do |l|
      text << "<a href='/!page/#{@lang}/tags/by/#{l.downcase.strip}'>#{l}</a>"
    end
    html.gsub! "{{tags #{a[0]}}}", text.join(", ")
  end

  template.scan(/{{linkTo}}/i).each do |a|
    html.gsub! "{{linkTo}}", "/!page/#{@lang}/#{options["model"]}/#{options["action"]}/#{path.split("/").last.split("@").first}"
  end

  template.scan(/{{load\s+([\w\-_\.]+)}}/i).each do |a|
    html.gsub!("{{load #{a[0]}}}", IO.read(a[0])) if File.exists? a[0]
  end

  template.scan(/{{gallery\s+([\w\.|\(\)\d;|\^=\:]+)}}/i).each_with_index do |a, i|
    imgOpts = {}
    a[0].split("|").last.to_s.split(";").each do |o|
      o = o .split "="
      imgOpts[o.first] = o.last
    end
    key = a[0].split("|").first.gsub("#{options["model"]}.", "")
    text = collect[key].to_s.strip
    text = path.dup if text == ""
    text.gsub!("{{path}}", path)
    src = text.dup
    text.gsub!(@www, "/")
    
    if imgOpts["format"] and ["jpg","png"].include? text.split(".").last
      s, t = imgOpts["format"].split(":")
      # Create directory if needed
      p = src.split("/")[0..-2].join("/") + "/#{t}"
      f = src.split("/").last
      dest = "#{p}/#{f}"
      Dir.mkdir p unless Dir.exists? p
      if s[s.length - 1] == "^"
        s = "-thumbnail '#{s}' -gravity center -crop #{s.gsub("^","")}+0+0 +repage"
      else
        s = "-resize '#{s}'"
      end
      p = p.gsub("$", "\\$").gsub("#", "\\#")
      src = src.gsub("$", "\\$").gsub("#", "\\#")
      
      system("convert #{src} #{s} #{p}/#{f}") unless File.exists? dest
      text.gsub!(f, "#{t}/#{f}")
    end

    text = text[1..-1].gsub("@online","").gsub("/","%2F") if key == "name"

  
    html.gsub! "{{gallery #{a[0]}}}", text.to_s
  end

  html
end

def paginate(options, length)
  html = ""
  if options["paginate"]
    html += options["paginate_before"].to_s
    tmp = options["paginate"].dup
    html += tmp.gsub("{{nb}}", "&laquo;").gsub("{{page}}", "#{@params["page"].to_i - 1}").gsub("{{active}}", @params["page"].to_i == 1 ? "disabled" : "")
    maxpage = 0
    (0..(length.to_i / options["limit"].to_i)).each do |page|
      html += tmp.gsub("{{nb}}", "#{page.to_i + 1}").gsub("{{page}}", "#{page.to_i + 1}").gsub("{{active}}", (page + 1) == @params["page"].to_i ? "active" : "")
      maxpage = page
    end
    html += tmp.gsub("{{nb}}", "&raquo;").gsub("{{page}}", "#{@params["page"].to_i + 1}").gsub("{{active}}", @params["page"].to_i == maxpage + 1 ? "disabled" : "")
    
  end
  html += options["paginate_after"].to_s
  html
end

def apply_transform(text, options)
  options.split(";").each do |o|
    o.scan(/truncate\((\d+)\)/i).each do |r|
      t = text[0..(r[0].to_i)]
      t += "..." if r[0].to_i > text.length
      text = t
    end
  end
  text
end

def archive_list(folder)
  # only return uniq date
  Dir.glob("#{@www}#{folder}/*").map {|l| l.split("/").last[0..5]}.uniq.sort.reverse
end

["en", "fr", "es", "de"].each do |l| # languages must be defined in config file
  if @params[l]
    @lang = l
    file = @params[l]
  end
end
if @params["reset"]
  system "rm -Rf #{@www}cache/*"
end
@filename = file.dup

usecache = true
fileargs = @params.keys.map{|k| "#{k}-#{@params[k]}"}.join("-")
if usecache and File.exists?("#{@www}cache/#{file}.#{@lang}-#{fileargs}.html.#{@params["page"]}")
  @layout = IO.read "#{@www}cache/#{file}.#{@lang}-#{fileargs}.html.#{@params["page"]}"
else
  analyze_template "#{@www}#{file}.#{@lang}.soli"
  convert_inclusions
  convert_widget
  Dir.mkdir "#{@www}cache/" rescue nil
  f = "#{@www}cache/#{file}.#{@lang}-#{fileargs}.html.#{@params["page"]}"
  IO.write f, @layout if usecache
  #system("htmlminify -o #{f} #{f} &")
end

@layout.gsub! "<!-- #title -->", "soliCMS - #{@filename}"
@layout.gsub! "<!-- #debug -->", "Page Generated in : <strong>#{((Time.now - t1) * 1000 * 1000).round(2)} micro seconds</strong> - soliCMS powered \\o/ #{@params.inspect} - #{Time.now} -"
puts @layout# + (params.inspect)

#puts "<p>#{params.inspect} #{ENV.inspect}  #{ENV["PATH_TRANSLATED"]}</p>"
exit 200
