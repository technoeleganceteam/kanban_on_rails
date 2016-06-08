# KanbanOnRails
[![Build Status](https://travis-ci.org/technoeleganceteam/kanban_on_rails.svg?branch=master)](https://travis-ci.org/technoeleganceteam/kanban_on_rails)
**KanbanOnRails** is a complete open source solution for creating Kanban boards built with Ruby on Rails.
![Example Kanban board](https://raw.githubusercontent.com/technoeleganceteam/kanban_on_rails/master/app/assets/images/welcome_image_example.jpg "Example Kanban board")

### Features
- **Integration with Bitbucket and Github.** Your projects and issues can be synced with these services. All changes with issues will be synced via webhooks and api.
- **Inviting users to your projects** You can invite user that has no Github or Gitlab account to your project as manager for example, so he will not see your project code but he will see your issues.
- **Completely open source** This servise is licensed under MIT License and you can fork this repository or do whatever you want with the code. You can also deploy this service to your own server.

### System dependencies
To install this application to your server you need these services and packages:
- PostgreSQL
- Ruby
- Memcached
- Git
- libpq-dev
- Ubuntu(or some Unix)
- Nginx
- Sidekiq
- RVM

You can deploy it with Capistrano(config is in repository) and Puppet provisioning. May be in some future we put puppet module for this project to open source too.

### Local installation
Installation is quite simple if you have already some expierence with Ruby on Rails applications. Here an example for Ubuntu:
#### Ubuntu(14.04)
##### RVM
```bash
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
```
```bash
\curl -sSL https://get.rvm.io | bash
```
##### Ruby
```bash
rvm install ruby-2.3.1
```
##### PostgreSQL
```bash
deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main
```
```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-9.4
```
```bash
sudo apt-get install libpq-dev
```
##### Redis
```bash
sudo apt-get install redis-server
```
After installation packages listed above you should clone this github repository to your computer and run ```bundle install``` at the root of the project directory. Create file ```config/settings.local.yml``` with your local settings and run ```rake db:migrate```  
### How to deploy to your server
Easiest way is to clone this repository to your computer, check that your server meets dependencies listed above and run ```cap deploy production``` from your computer. You can also create Github or Bitbucket Oauth app and specify it credentials in omniauth section in ```config/settings.local.yml``` on your server.
### How to run test suite
After local installation you can run specs with command ```rake spec```
### How to contribute
Fork this repository, create a branch with some feature or bug fix, ensure that all tests are passed by running command ```rake spec``` push your branch and then create Pull Request for this repository.
### Licence
MIT License
