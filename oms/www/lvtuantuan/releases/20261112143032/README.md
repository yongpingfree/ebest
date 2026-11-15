## environment

1. ruby 2.5.7
2. rails 5.2.1

## Start server

### Master

[Passbolt master key](https://passbolt.beansmile-dev.com/app/passwords/view/aa39136a-560e-4ec2-a3c7-c52c255fa17c)

### Prerequirement

macOS:

```
brew install opencc # 繁简中文转换依赖
brew install shared-mime-info # mimemagic gem 依赖
```

Ubuntu server:

```
sudo apt-get install opencc
sudo apt-get install libopencc-dev
sudo apt-get install libxrender1
sudo apt-get install fonts-wqy-zenhei
```

### Bundle

```
bundle install
```

### Database initialization

##### Add environment variable if your pg has set user_name and password

```
echo 'export DB_USERNAME=your_db_username' >> ~/.bashrc
echo 'export DB_PASSWORD=your_db_password' >> ~/.bashrc
source ~/.bashrc
```

##### Create database

```
rails db:create
rails db:migrate
rails db:seed
```

If you need to add test data

`rails db:seed_fu`

### Run server

```
rails s -p PORT
```

### API doc

visit app api doc via: `/app/api/doc`
visit admin api doc via: `/mgt/api/doc`
