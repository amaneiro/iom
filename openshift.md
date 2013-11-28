### Documentation

* Create application

  * [Manual](https://access.redhat.com/site/documentation/en-US/OpenShift_Online/2.0/html/User_Guide/sect-Creating_an_Application.html)
  * RoR - [RoR 101](https://www.openshift.com/blogs/openshift-is-a-rails-friendly-paas-part-1) and [RoR 102](https://www.openshift.com/blogs/openshift-is-a-rails-friendly-paas-part-2)
  * Scaling - [HAProxy](https://www.openshift.com/blogs/how-haproxy-scales-openshift-apps) and [RoR Scaling](https://www.openshift.com/blogs/how-to-scale-your-ruby-on-rails-application)

* Add postgresql support

  * [Installation](https://www.openshift.com/blogs/deploying-and-managing-postgresql-on-openshift) and [video](https://www.openshift.com/videos/deploying-and-managing-postgresql-on-openshift)

* Add postgis support

  * [Spatial PowerUp](https://www.openshift.com/blogs/time-for-a-spatial-power-up-openshift-postgis) and [Create template PostGIS](https://gist.github.com/nosolosw/5976731)

* Develop / Deploy app

  * [Using existent git repo](https://geekwentfreak-raviteja.rhcloud.com/2013/02/openshift-use-external-git-repository-with-openshift/) and [some config](https://www.openshift.com/kb/kb-e1006-sync-new-git-repo-with-your-own-existing-git-repo#comment-24175)

### Steps

* Create application

        rhc app create <app-name> ruby-1.8 -s

* Add postgresql cartrige

        rhc cartridge add postgresql-8.4 -a <app-name>

* Add postgis support

        rhc ssh -a <app-name>
        createdb -h $OPENSHIFT_POSTGRESQL_DB_HOST -p $OPENSHIFT_POSTGRESQL_DB_PORT -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -O $OPENSHIFT_POSTGRESQL_DB_USERNAME template_postgis -W
        createlang -h $OPENSHIFT_POSTGRESQL_DB_HOST -p $OPENSHIFT_POSTGRESQL_DB_PORT -U $OPENSHIFT_POSTGRESQL_DB_USERNAME plpgsql template_postgis
        psql -d template_postgis -f /usr/share/pgsql/contrib/postgis-64.sql
        psql -d template_postgis -f /usr/share/pgsql/contrib/spatial_ref_sys.sql
        dropdb -h $OPENSHIFT_POSTGRESQL_DB_HOST -p $OPENSHIFT_POSTGRESQL_DB_PORT -U $OPENSHIFT_POSTGRESQL_DB_USERNAME <app-name> # will use a differente name for the DB
        CREATE ROLE geoiq WITH LOGIN;
        # DB create will be done by rake
        # createdb -h $OPENSHIFT_POSTGRESQL_DB_HOST -p $OPENSHIFT_POSTGRESQL_DB_PORT -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -O $OPENSHIFT_POSTGRESQL_DB_USERNAME -T template_postgis donde_cooperamos -W

* Develop - get the code

        git clone git@github.com:iCarto/donde-cooperamos.git dondecooperamos.org
        cd dondecooperamos.org
        git remote add openshift -f <openshift-git-repo-url>
        git merge openshift/master -s recursive -X ours

* Deploy app

        git push openshift openshift:master
        git push github openshift:openshift

* Deploy bd

        rhc ssh -a <app-name>
        cd <~/app-root/repo>
        bundle exec rake dc:load_schema
        bundle exec rake dc:data:load
        bundle exec rake dc:data:update_project_budget
        bundle exec rake dc:data:load_project_additional_info
