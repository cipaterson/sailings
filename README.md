# README

A rails app to manage sailings and assignment of crew.

Dev set-up:
Install ruby and rails acording to:
https://guides.rubyonrails.org/install_ruby_on_rails.html
git clone https://github.com/sailings.git

* Ruby version
ruby 3.4.2

* System dependencies

* Configuration

* Database creation
bin/rails db:create
bin/rails db:migrate

* Database initialization
bin/rails db:seed
will populate the database with sample data.

There are several users with different roles (all passwords are "qqq"):
office@example.com
crewing@ladynelson.org.au
pleb@example.com
admin@example.com - has both office and crewing roles

* How to run the test suite
???

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions
Used fly.io for deployment.

* ...
