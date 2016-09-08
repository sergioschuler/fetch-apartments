require 'mechanize'
require 'pry'

urls = [
	'http://www.vivareal.com.br/aluguel/santa-catarina/florianopolis/bairros/agronomica/apartamento_residencial/',
	'http://www.vivareal.com.br/aluguel/santa-catarina/florianopolis/bairros/trindade/apartamento_residencial/',
	'http://www.vivareal.com.br/aluguel/santa-catarina/florianopolis/bairros/itacorubi/apartamento_residencial/',
	'http://www.vivareal.com.br/aluguel/santa-catarina/florianopolis/bairros/centro/apartamento_residencial/'
	]
max_rent_price = 1300
min_square_meters = 40

def scrape_index_pages(url, max_rent_price, min_square_meters, page=1)
	scrape_all_properties_in_page(url, max_rent_price, min_square_meters)

	agent = Mechanize.new
	agent.get(url)
	page = (page + 1).to_s
	next_url = agent.page.links_with(text: page)
	if next_url != []
		next_url = next_url.last.click
		puts "Scraping next page: #{next_url.uri}"
		scrape_index_pages(next_url.uri, max_rent_price, min_square_meters, page.to_i)
	end
end

def scrape_all_properties_in_page(url, max_rent_price, min_square_meters)

	agent = Mechanize.new
	agent.get(url)
	agent.page.links_with(text: "VER TODOS OS DETALHES").each do |link|
		link.click
		property_url = link.resolved_uri.to_s
		property_title = agent.page.search(".//span[@class='property-title__name']")&.text
		property_address = agent.page.search(".//span[@class='property-title__location-address js-titleLocation']")&.text
		property_neighborhood = agent.page.search(".//span[@class='property-title__location-neighborhood property-title__view-map js-titleLocation']")&.text
		property_rent_price = agent.page.search(".//dd[@class='property-information__item-description property-information--price']")&.text&.strip&.gsub(/[^\d]/, '')
		property_condominio = agent.page.search(".//dl[@class='property-information__item property-information--prices property-information__sub-price']")&.children&.last&.text&.gsub(/[^\d]/, '')
		property_type = agent.page.search(".//dl[@class='property-information__item icon-building']")&.children&.last&.text
		property_square_meters = agent.page.search(".//dl[@class='property-information__item icon-area']")&.children&.last&.text&.gsub(/[^\d]/, '')
		property_number_of_rooms = agent.page.search(".//dl[@class='property-information__item icon-room']")&.children&.last&.text&.gsub(/[^\d]/, '')
		property_number_of_bathrooms = agent.page.search(".//dl[@class='property-information__item icon-bathroom']")&.children&.last&.text&.gsub(/[^\d]/, '')
		property_number_of_garage_spots = agent.page.search(".//dl[@class='property-information__item icon-garage']")&.children&.last&.text&.gsub(/[^\d]/, '')
		property_code = agent.page.search(".//dl[@class='property-information__item icon-ribbon']")&.children&.last&.text
		property_description = agent.page.search(".//p[@class='property-description__detail']")&.text&.split("\n")&.join
		property_features = agent.page.search(".//ul[@class='property-description__features']")&.children&.map {|i| i&.text&.gsub(/<li>|<\/li>/, '')}
		real_state_agent = agent.page.search(".//div[@class='publisher__logo-container']")&.at("img")["alt"]
		real_state_agent_phone = agent.page.search(".//div[@class='publisher__telephone-wrapper']")&.children[2]&.text&.strip

		if property_rent_price.to_i <= max_rent_price && property_square_meters.to_i >= min_square_meters

			if File.file?("apartments.csv") == false
				File.open("apartments.csv", "a") do |w|
					w.write "URL; Título; Rua; Bairro; Aluguel;	Condominio;	Tipo; M²; Quartos; Banheiros; Vagas; Código; Descrição;	Extras;	Imobiliária; Fone\n"
				end
			end

			File.open("apartments.csv", "a") do |w|
				w.write "#{property_url}; #{property_title}; #{property_address}; #{property_neighborhood};	#{property_rent_price}; #{property_condominio};	#{property_type}; #{property_square_meters}; #{property_number_of_rooms}; #{property_number_of_bathrooms}; #{property_number_of_garage_spots};	#{property_code}; #{property_description}; #{property_features}; #{real_state_agent}; #{real_state_agent_phone}\n"
			end
		end
	end

end

#binding.pry
urls.each do |url|
	scrape_index_pages(url, max_rent_price, min_square_meters)
end