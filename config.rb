require 'json'
require 'net/http'
require 'nokogiri'

###
# Compass
###
set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true

activate :directory_indexes



# retrieve program information
programs_req_url = URI.parse("http://localhost:9000/programs")
programs_req = Net::HTTP.get_response(programs_req_url)
@programs = JSON.parse(programs_req.body)
@programs.each do |programPreview|
  program_req_url = URI.parse("http://localhost:9000/programs/#{programPreview['shortname']}")
  program_req = Net::HTTP.get_response(program_req_url)
  program = JSON.parse(program_req.body)
  proxy "/#{programPreview['shortname']}.html", "/templates/program.html", :locals => { :program => program, :title => program["name"] },:ignore => true
  proxy "/#{programPreview['shortname']}/feed.xml", "/templates/feed.html", :locals => { :program => program },:ignore => true, :directory_index => false, :layout => false
end



page "*.md", :layout => "markdown"
# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (https://middlemanapp.com/advanced/dynamic_pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Methods defined in the helpers block are available in templates
 helpers do
   def generatefeed(program)
     feed = Nokogiri::XML::Builder.new do |xml|
			 xml.rss('xmlns:itunes' => "http://www.itunes.com/dtds/podcast-1.0.dtd") do
				 xml.channel do
				   xml.title program["name"]
				   xml.link "http://wjrh.org/#{program["shortname"]}"
					 xml.copyright program["copyright"]
					 xml['itunes'].subtitle program["subtitle"]
					 xml['itunes'].author program["creators"].join(", ")
					 if not program['description'].nil?
						 xml['itunes'].summary {
							 xml.cdata Tilt['markdown'].new { program['description'] }.render
						 }
						 xml.description {
							 xml.cdata Tilt['markdown'].new { program['description'] }.render
						 }
					 end
					 xml['itunes'].image('href' => "http://wjrh.org/vbb/logo2.jpg")
					 program['episodes'].each do |episode|
						 xml.item do
							 xml.title episode['name']
							 xml['itunes'].author program['creators'].join(", ")
							 if not episode['description'].nil?
						 		 xml['itunes'].subtitle {
									xml.cdata Tilt['markdown'].new { episode['description'] }.render
						 	 	 }
						 		 xml['itunes'].summary {
							 		xml.cdata Tilt['markdown'].new { episode['description'] }.render
							   }
					 		 end
							 xml['itunes'].image("href" => episode['image'])
							 episode["medias"].each do |media|
								 xml.enclosure("url" => media["url"], "length" => media["length"], "type" => media["type"])
							 end
							 xml.guid episode["guid"] ||= episode["id"]
							 xml.pubDate Time.parse(episode["pubdate"]).rfc2822
							 xml['itunes'].duration episode['medias'][0]['length']
						 end
					 end 
				 end
			 end
		 end
		 return feed.to_xml
   end
 end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Enable cache buster
  # activate :asset_hash

  # Use relative URLs
  activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"

end
