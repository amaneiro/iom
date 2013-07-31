# -*- coding: utf-8 -*-
namespace :dc do

  desc 'Create database'
  task :load_schema => %w(db:drop db:create db:migrate)

  namespace :data do

    desc 'Load all data needed for Bolivia site'
    task :load => %w(dc:data:load_settings dc:data:load_adm_world dc:data:load_adm_bolivia dc:data:load_sectors dc:data:load_organizations dc:data:load_donors dc:data:load_projects dc:data:load_donations)

    desc 'Load countries and 1st administrative level for the whole world'
    task :load_adm_world => %w(iom:data:load_countries iom:data:load_adm_levels)

    desc 'Load Bolivia administrative boundaries'
    task :load_adm_bolivia => :environment do
      DB = ActiveRecord::Base.connection

      puts "Loading adm levels for Bolivia"

      csv = CsvMapper.import("#{Rails.root}/db/data/bolivia/bolivia.csv") do
        read_attributes_from_file
      end

      csv.each do |row|
        r                  = Region.new
        r.name             = row.name
        r.level            = row.level
        r.country_id       = 17 # Bolivia
        r.center_lat       = row.lat
        r.center_lon       = row.lon
        r.the_geom         = Point.from_x_y(row.lon, row.lat)
        r.ia_name          = row.name
        r.parent_region_id = Region.where("country_id = ? AND name = ?", 17, row.parent_region).first.id
        r.save!
        r.gadm_id          = r.id
        r.save!
        puts "Level #{row.level}: created #{row.name}"
      end

    end

    desc 'Load sectors'
    task :load_sectors => :environment do
      csv = CsvMapper.import("#{Rails.root}/db/data/bolivia/sectores.csv") do
        read_attributes_from_file
      end
      csv.each do |row|
        unless sector = Sector.where("name = ?", row.sector).first
          Sector.create :name => row.sector
          puts "Sector #{row.sector}"
        end
      end
    end

    desc 'Load organizations'
    task :load_organizations => :environment do
      # TODO: load only OE organizations
      csv = CsvMapper.import("#{Rails.root}/db/data/bolivia/organizaciones.csv") do
        read_attributes_from_file
      end
      csv.each do |row|
        unless o = Organization.where("name = ?", row.name).first
          org = Organization.new
          org.name            = row.name
          org.organization_id = row.organization_id
          org.website         = row.website
          org.save!
          puts "Org: created #{row.name}"
        else
          puts "Org: already exists #{row.name}"
        end
      end
    end

    desc 'Load donors'
    task :load_donors => :environment do
      # TODO: load only donors
      csv = CsvMapper.import("#{Rails.root}/db/data/bolivia/organizaciones.csv") do
        read_attributes_from_file
      end
      csv.each do |row|
        unless o = Donor.where("name = ?", row.name).first
          donor = Donor.new
          donor.name    = row.name
          donor.website = row.website
          donor.save!
          puts "Donor: created #{row.name}"
        else
          puts "Donor: already exists #{row.name}"
        end
      end
    end

    desc 'Load donations'
    task :load_donations => :environment do
      csv = CsvMapper.import("#{Rails.root}/db/data/bolivia/donaciones.csv") do
        read_attributes_from_file
      end
      csv.each do |row|
        donation = Donation.new
        donation.project = Project.where("name = ?", row.project).first
        donation.donor   = Donor.where("name = ?", row.donor).first
        donation.amount  = row.amount
        unless donation.project.blank? or donation.donor.blank?
          donation.save!
          puts "Donations: imported #{row.amount} by #{row.donor} to project #{row.project}"
        end
      end
    end

    desc 'Load projects'
    task :load_projects => :environment do
      DB = ActiveRecord::Base.connection

      csv = CsvMapper.import("#{Rails.root}/db/data/bolivia/proyectos.csv") do
        read_attributes_from_file
      end
      csv.each do |row|
        p = Project.new
        p.name          = row.name
        p.description   = row.description.blank? ? row.name : row.description
        p.date_provided = Date.strptime(row.date_provided, "%Y-%m-%d") unless (row.date_provided.blank?)
        p.date_updated  = Date.strptime(row.date_updated, "%Y-%m-%d") unless (row.date_updated.blank?)
        p.sectors       << Sector.find_by_name(row.sector) # at this step, will only have 1 sector
        p.countries     << Country.where('id = ?', 17) # bolivia
        p.primary_organization = Organization.find_or_create_by_name(row.organization)

        # Assign dates
        if row.end_date < row.start_date
          # skip bad-formed projects
          next
        end

        p.start_date    = Date.strptime(row.start_date, "%Y-%m-%d") unless (row.start_date.blank?)
        p.end_date      = Date.strptime(row.end_date, "%Y-%m-%d") unless (row.end_date.blank?)

        # Assign regions and geom
        locations = Array.new

        regions = row.regions.split("|")
        if regions.size == 1 && regions == ['Bolivia']
          # TODO import nation wide project
          next
        end

        regions.each do |region_name|
          r = Region.where('country_id = 17 AND name = ?', region_name).first
          if r
            p.regions << r

            if locations.count<1
              r_sel = Region.find_by_id(r.id)
              lat_lon = "#{r_sel.center_lon} #{r_sel.center_lat}"
              locations << lat_lon
            end

            # also add the upper regions
            r_parent      = nil # 1-level up
            r_grandparent = nil # 2-level up

            r_parent = Region.find_by_id(r.parent_region_id) unless r.parent_region_id.blank?
            p.regions << r_parent if r_parent

            if r_parent
              r_grandparent = Region.find_by_id(r_parent.parent_region_id) unless r_parent.parent_region_id.blank?
              p.regions << r_grandparent if r_grandparent
            end

          end
        end
        multi_point = nil
        multi_point = "ST_MPointFromText('MULTIPOINT(#{locations.join(',')})',4326)" unless (locations.length<1)

        puts "Project: imported #{row.name}"
        p.save!

        # save the geom created before
        if(!multi_point.blank?)
          sql="UPDATE projects SET the_geom=#{multi_point} WHERE id=#{p.id}"
          DB.execute sql
        end

      end

      # set up relationship between projects and sites
      Site.all.each{ |site| site.save! }

    end

    desc 'Load settings: admin users, themes, site, ...'
    task :load_settings => :environment do

      User.create :name => 'amaneiro',
                  :email => 'amaneiro@icarto.es',
                  :password => 'admin',
                  :password_confirmation => 'admin',
                  :role => 'admin'
      puts "Settings: created admin user"

      settings = Settings.find_or_create_by_id(1)
      data = HashWithIndifferentAccess.new
      data[:main_site_host] = 'dondecooperamos.com'
      settings.data = data
      settings.save!
      puts "Settings: general"

      Theme.create :name => 'Garnet',
             :css_file => '/stylesheets/themes/garnet.css',
             :thumbnail_path => '/images/themes/1/thumbnail.png',
             :data => {
               :overview_map_chco => "F7F7F7,8BC856,336600",
               :overview_map_chf => "bg,s,2F84A3",
               :overview_map_marker_source => "/images/themes/1/",
               :georegion_map_chco => "F7F7F7,8BC856,336600",
               :georegion_map_chf => "bg,s,2F84A3",
               :georegion_map_marker_source => "/images/themes/1/",
               :georegion_map_stroke_color => "#000000",
               :georegion_map_fill_color => "#000000"
             }

      Theme.create :name => 'Pink',
             :css_file => '/stylesheets/themes/pink.css',
             :thumbnail_path => '/images/themes/2/thumbnail.png',
             :data => {
               :overview_map_chco => "F7F7F7,8BC856,336600",
               :overview_map_chf => "bg,s,2F84A3",
               :overview_map_marker_source => "/images/themes/2/",
               :georegion_map_chco => "F7F7F7,8BC856,336600",
               :georegion_map_chf => "bg,s,2F84A3",
               :georegion_map_marker_source => "/images/themes/2/",
               :georegion_map_stroke_color => "#000000",
               :georegion_map_fill_color => "#000000"
             }

      Theme.create :name => 'Blue',
             :css_file => '/stylesheets/themes/blue.css',
             :thumbnail_path => '/images/themes/3/thumbnail.png',
             :data => {
               :overview_map_chco => "F7F7F7,8BC856,336600",
               :overview_map_chf => "bg,s,2F84A3",
               :overview_map_marker_source => "/images/themes/3/",
               :georegion_map_chco => "F7F7F7,8BC856,336600",
               :georegion_map_chf => "bg,s,2F84A3",
               :georegion_map_marker_source => "/images/themes/3/",
               :georegion_map_stroke_color => "#000000",
               :georegion_map_fill_color => "#000000"
             }

      puts "Settings: 3 themes created"

      site = Site.new :name   => 'Bolivia',
                      :url    => 'bolivia.dondecooperamos.com',
                      :status => true,
                      :project_classification => 1,
                      :short_description => 'Mapa de la ayuda española en Bolivia',
                      :long_description  => 'Qué hacen las ONGs españolas en Bolivia',
                      :theme             => Theme.find_by_name('Garnet'),
                      :navigate_by_level3 => true

      site.overview_map_bbox_miny = -23.6445
      site.overview_map_bbox_minx = -72.8613
      site.overview_map_bbox_maxy =  -9.3624
      site.overview_map_bbox_maxx = -55.5469

      site.geographic_context_country_id = Country.find_by_name('Bolivia').id
      site.word_for_regions = "Regiones"
      site.save!
      puts "Settings: bolivia site created"

      site.pages.find_by_title('About').update_attribute(:body, <<-HTML
                    <p><a href="/">InterAction</a> is developing a web-based mapping platform and database that will ultimately map all of our members’
                    work worldwide. In 2010, InterAction will pilot the mapping platform with a focus on the NGO community’s response to the earthquake
                    in Haiti, as well as its efforts to improve food security in various countries around the world.</p>
                    <p>The mapping platform will be an effective, flexible and sustainable means of capturing information on NGO activities that will:</p>
                    <ul>
                      <li>Demonstrate NGOs’ commitment to transparency and accountability</li>
                      <li>Facilitate partnerships and improve coordination among humanitarian actors</li>
                      <li>Help NGOs and other actors make more informed decisions about where to direct resources</li>
                      <li>Highlight the global reach of NGOs to donors, the media and public</li>
                    </ul>
                    <h3>BENEFITS OF PARTICIPATING</h3>
                    <p>InterAction members who participate in the mapping initiative will have access to a powerful, user-friendly mapping software, GeoIQ, at no cost. With this tool, members will be able to:</p>
                    <ul>
                      <li>Create maps and easily share them with others</li>
                      <li>Identify potential partners</li>
                      <li>Identify underserved areas or areas with greatest needs</li>
                      <li>Access more than 20,000 data sets from organizations such as the United Nations or World Bank</li>
                      <li>Overlay project information with relevant statistical information, such as child malnutrition rates</li>
                      <li>Analyze large amounts of data</li>
                    </ul>
               HTML
                                                         )
      site.pages.find_by_title('Highlights').update_attribute(:body, <<-HTML
                   <p>On October 21, the Government of Haiti confirmed an outbreak of cholera, an acute and highly contagious diarrheal disease caused
                   by eating or drinking contaminated food or water. Unless immediately treated, cholera can be fatal. As of November 16 Haiti’s Ministry of
                   Health has confirmed 1,039 deaths and 16,799 hospitalized cases.</p>

                   <p>The Haitian Government, UN and NGOs have responded quickly to the epidemic. We have provided treatment to those affected, strengthened health
                   care centers so they are ready to respond, and attempted to prevent the further spread of the disease by distributing clean water and food and promoting good hygiene practices.
                   The provision of safe water and sanitation is critical to reducing the impact of cholera.</p>

                   <p>This map provides information on the number of water and sanitation projects established by InterAction members prior to the cholera outbreak.
                   Departments that have been directly affected by cholera are shaded in red, with darker shades indicating higher number of deaths and departments with no cases (in green).</p>

                   <p>For general information on how InterAction members are responding to the outbreak, please visit the Cholera Outbreak Crisis Response
                  List on InterAction’s website. For specific examples of members’ response please visit the Member Response to Cholera in Haiti map.</p>

                   <p>Source: Ministere de la Sante Publique et de la Population (MSPP) - November 16, 2010</p>
              HTML
                                                              )

    end

  end

end
