# TO START THE APP #

# Install the project's gems
bundle install

# Install the optional gem
install the gem rackup -> gem install rackup

# Database Setup
database setup:

create the user: createuser -U postgres roda
create the database production: createdb -U postgres -O roda roda_production
create the database test: createdb -U postgres -O roda roda_test
create the database development: createdb -U postgres -O roda roda_development

enable the postgis extension:
psql -U postgres -d roda_production -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -U postgres -d roda_test -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -U postgres -d roda_development -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# Set the environment variables
Create the .env.development from .env.development.template

# Start the rake's tasks
rake db:migrate

rake data:import

# Start the app
rackup
