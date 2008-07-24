#!/usr/bin/env ruby
# Figures out the URLs for the Wikipedia biography pages of Representatives and Senators

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'name'
require 'people'
require 'mechanize_proxy'
require 'configuration'

# Check that there is an OpenAustralia link on the Wikipedia page. If not, display a warning
def check_wikipedia_page(title, agent)
  url = "http://en.wikipedia.org/w/index.php?title=#{title}&action=edit"
  text = agent.get(url).parser.to_s
  unless text =~ /\{\{OpenAustralia(\|.*)?\}\}/
    puts "WARNING: No OpenAustralia link on http://en.wikipedia.org/wiki/#{title}"
  end
end

def extract_links_from_wikipedia(doc, people, links, agent)
  doc.search("//table").first.search("tr").each do |row|
    link = row.search('td a')[0]
    if link
      name = Name.title_first_last(link.inner_html)
      person = people.find_person_by_name(name)
      if person
        if link.get_attribute("href").match(/^\/wiki\/(.*)$/)
          title = $~[1]
        else
          throw "Unexpected link format"
        end
        url = "http://en.wikipedia.org/wiki/#{title}"
        if links.has_key?(person.id) && links[person.id] != url
          puts "WARNING: URL for #{name.full_name} has multiple different values"
        else
          links[person.id] = url
        end
        check_wikipedia_page(title, agent)
      else
        puts "WARNING: Could not find person with name #{name.full_name}" 
      end 
    end
  end
  links
end

def write_links(links, filename)
  xml = File.open(filename, 'w')
  x = Builder::XmlMarkup.new(:target => xml, :indent => 1)
  x.instruct!  
  x.publicwhip do
    links.each { |link| x.personinfo(:id => link[0], :wikipedia_url => link[1]) }
  end
  xml.close
end

conf = Configuration.new

puts "Reading member data..."
people = people = PeopleCSVReader.read_members

agent = MechanizeProxy.new
# Slightly naughty because Wikipedia specifically blocks Ruby Mechanize but I'm justifying it because we
# are using the html_cache here so that will mean there is a very small amount of traffic generally
agent.user_agent_alias = 'Mac Safari'
agent.cache_subdirectory = "wikipedia"

if conf.write_xml_representatives
  puts "Wikipedia links for Representatives..."
  links = {}
  #["1980", "1983", "1984", "1987", "1990", "1993", "1996", "1998", "2001", "2004", "2007", "2010"].each_cons(2) do |pair|
  # Only going to get wikipedia links going back to 2004 for the time being
  ["2004", "2007", "2010"].each_cons(2) do |pair|
    puts "Analysing years #{pair[0]}-#{pair[1]}"
    url = "http://en.wikipedia.org/wiki/Members_of_the_Australian_House_of_Representatives%2C_#{pair[0]}-#{pair[1]}"
    extract_links_from_wikipedia(agent.get(url).parser, people, links, agent)
  end
  write_links(links, "#{conf.members_xml_path}/wikipedia-commons.xml")
end
if conf.write_xml_senators
  puts "Wikipedia links for Senators..."
  links = {}
  url = "http://en.wikipedia.org/wiki/Members_of_the_Australian_Senate%2C_2005-2008"
  extract_links_from_wikipedia(agent.get(url).parser, people, links, agent)
  write_links(links, "#{conf.members_xml_path}/wikipedia-lords.xml")
end

system(conf.web_root + "/twfy/scripts/mpinfoin.pl links")