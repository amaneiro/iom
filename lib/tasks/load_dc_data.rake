namespace :dc do

  desc 'Create database'
  task :load_schema => %w(db:drop db:create db:migrate)

  namespace :data do

    desc 'Load administrative boundaries: countries & regions'
    task :load_bolivia => %w(dc:data:load_adm_bolivia dc:data:load_sectors dc:data:load_organizations dc:data:load_projects)

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
  end

end
