# KanbanOnRails
[![Build Status](https://travis-ci.org/technoeleganceteam/kanban_on_rails.svg?branch=master)](https://travis-ci.org/technoeleganceteam/kanban_on_rails)
[![Coverage Status](https://coveralls.io/repos/github/technoeleganceteam/kanban_on_rails/badge.svg?branch=master)](https://coveralls.io/github/technoeleganceteam/kanban_on_rails?branch=master)

**KanbanOnRails** is a complete open source solution for creating Kanban boards and project management.

![Example Kanban board](https://raw.githubusercontent.com/technoeleganceteam/kanban_on_rails/master/app/assets/images/welcome_image_example.jpg "Example Kanban board")

### Features
- **Integration with Github, Bitbucket and Gitlab.** Your projects and issues can be synced with these services. All changes with issues will be synced via webhooks and api.
- **Inviting users to your projects** You can invite user that has no Github, Bitbucket or Gitlab account to your project as manager for example, so he will not see your project code but he will see your issues.
- **Real-time integration** You can see all changes in real time via websockets. We use great rails framework Action Cable for this. 
- **Multi-project boards** You can create board with multiple projects(even from Gitlab or Github together)
- **Multi-section boards** You can divide your board to multiple sections. For example you can create section with all issues(by click to checkbox "Or include all?" while creating the section) and section with only important issues(by creating section with tag "Important" for example, all issues with tag "Important" will display there)
- **Multi-language** Service is translated in more than 70 languages.
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
Installation is quite simple if you have already some experience with Ruby on Rails applications. Here an example for Ubuntu:
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
Easiest way is to clone this repository to your computer, check that your server meets dependencies listed above and run ```cap deploy production``` from your computer. You can also create Github, Bitbucket or Gitlab Oauth app and specify it credentials in omniauth section in ```config/settings.local.yml``` on your server.
### How to integrate with your own Gitlab server
If you'd like to integrate with your own Gitlab server, first you must deploy this service to your server too and then you must specify Settings.omniauth.gitlab.client_options of gitlab service. It contains 3 keys: ```site```(url of your gitlab service), ```authorize_url```(usually '/oauth/authorize') and ```token_url```(usually '/oauth/token'). After this you could sign in with your Gitlab service and use your own Gitlab service api to sync your projects. Your should alse set your Gitlab api endpoint url in ```Settings.gitlab_endpoint```. 
### How to run test suite
After local installation you can run specs with command ```rake spec```
### How to contribute
Fork this repository, create a branch with some feature or bug fix, ensure that all tests are passed by running command ```rake spec``` push your branch and then create Pull Request for this repository.
### Licence
MIT License

