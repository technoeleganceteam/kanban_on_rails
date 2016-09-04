# KanbanOnRails

[![GitHub version](https://badge.fury.io/gh/technoeleganceteam%2Fkanban_on_rails.svg)](https://badge.fury.io/gh/technoeleganceteam%2Fkanban_on_rails)
[![Build Status](https://travis-ci.org/technoeleganceteam/kanban_on_rails.svg?branch=master)](https://travis-ci.org/technoeleganceteam/kanban_on_rails)
[![Test Coverage](https://codeclimate.com/github/technoeleganceteam/kanban_on_rails/badges/coverage.svg)](https://codeclimate.com/github/technoeleganceteam/kanban_on_rails/coverage)
[![Code Climate](https://codeclimate.com/github/technoeleganceteam/kanban_on_rails/badges/gpa.svg)](https://codeclimate.com/github/technoeleganceteam/kanban_on_rails)
[![security](https://hakiri.io/github/technoeleganceteam/kanban_on_rails/master.svg)](https://hakiri.io/github/technoeleganceteam/kanban_on_rails/master)
[![Website](https://img.shields.io/website/https/kanbanonrails.com.svg?maxAge=2592000)](https://kanbanonrails.com)

**KanbanOnRails** is a complete open source solution for creating Kanban boards and project management.

![Example Kanban board](https://raw.githubusercontent.com/technoeleganceteam/kanban_on_rails/master/app/assets/images/welcome_image_example.jpg "Example Kanban board")

## Information

### Features

- **Two-way integration with Github, Bitbucket and Gitlab.** Your issues will be synced with these services via api. All external changes with issues will be also synced via webhooks.
- **Automatically build changelog** Your pull requests and related issues will be parsed, sent to specified emails and wrote to repository file automatically after receiving webhooks from Github, Bitbucket or Gitlab. Our [CHANGELOG.md](https://github.com/technoeleganceteam/kanban_on_rails/blob/master/CHANGELOG.md) is built by this way, check it out!
- **Inviting users to your boards** You can invite users that have no Github, Bitbucket or Gitlab accounts to your board as managers for example, so they will not see your project code but they could see your board and issues.
- **Real-time integration** You and your team will see all changes in real time via websockets. We use great rails framework Action Cable for this.
- **Multi-project boards** You can create board with multiple projects(even from Gitlab or Github together)
- **Multi-section boards** You can divide your board to multiple sections. For example you can create section with all issues(by click to checkbox "Or include all?" while creating the section) and section with only important issues(by creating section with tag "Important" for example, all issues with tag "Important" will display there)
- **Interactive boards** You can drag and drop issues between columns, so its tags will change accordingly. You can also close issue just drop it out of a board.
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

### How to run test suite and lints

After local installation you can run specs with command ```rake spec```. You can run all specs and lints with command ```rake kanban_on_rails:run_all_specs_and_lints```.

### How to contribute

Fork this repository, create a branch with some feature or bug fix, ensure that all tests are passed by running command ```rake spec``` push your branch and then create Pull Request for this repository.

### Support the project

We are looking for investors or partners. If you'd like to cooperate with us or invest to the project, please contact us at partnership@technoelegance.com or kopylov.german@gmail.com

### Licence

MIT License
