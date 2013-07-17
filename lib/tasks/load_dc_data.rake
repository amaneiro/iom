namespace :dc do

  desc 'Create database'
  task :load_schema => %w(db:drop db:create db:migrate)

  namespace :data do

    desc 'Load administrative boundaries: countries & regions'
    task :load_adm => %w(iom:data:load_countries iom:data:load_adm_levels coop_beta:data:load_adm_bolivia)

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
        r.parent_region_id = Region.where("name = ?", row.parent_region).first.id
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
        end
      end
    end

    desc 'Load organizations'
    task :load_organizations => :environment do
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

  end

end
