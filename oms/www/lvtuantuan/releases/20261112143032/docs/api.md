# API

## API doc

visit app api doc via: `/app/api/doc`
visit admin api doc via: `/admin/api/doc`

## API Entities

### Entities 基础声明与继承

所有基础的Entities放在 `/app/services/common_entities/` 下定义：

```ruby
module CommonEntities
  class Model < Grape::Entity
    expose :id, :created_at, :updated_at
  end
end

module CommonEntities
  class User < Model
    expose :nickname, :avatar
  end
end
```

当需要自定义不同的Entities返回给不同的API环境时，例如需要返回User的 `open_id` 给Admin端API，可以增加Entity配置文件：
`/app/services/beans_admin/api/entities/user.rb`:

```ruby
module BeansAdmin::API::Entities
  class User < ::CommonEntities::User
    expose :open_id
  end
end
```

### Entity 使用

上诉情况中，APP端接口使用 `common_entities/user.rb` :
```ruby
module BeansApp
  ...
  present user, with: ::CommonEntities::User
  ...
end
```

Admin端接口使用 `beans_admin/api/entities/user.rb` :
```ruby
module BeansAdmin
  ...
  present user, with: API::Entities::User
  ...
end
```
