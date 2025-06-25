# Cursor Specific - Plugin Redmine Reminder

## Cấu hình Cursor cho Plugin Development

### Extensions Khuyến nghị
- **Ruby**: Hỗ trợ syntax highlighting và debugging cho Ruby
- **Rails**: Rails-specific snippets và commands
- **ERB**: Template syntax highlighting cho views
- **GitLens**: Git history và blame annotations
- **Ruby Solargraph**: Language server cho Ruby intellisense
- **YAML**: Để edit locale files và configuration

### Workspace Settings
```json
{
  "ruby.intellisense": "rubyLanguageServer",
  "ruby.codeCompletion": "rcodetools",
  "ruby.format": "rubocop",
  "emmet.includeLanguages": {
    "erb": "html"
  },
  "files.associations": {
    "*.erb": "erb",
    "*.rake": "ruby"
  }
}
```

### Code Snippets cho Redmine Plugin Development

#### Model Snippets
```ruby
# Trigger: redmine_model
class ${1:ModelName} < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  
  validates :${2:field}, presence: true
  
  scope :active, -> { where(active: true) }
  
  def ${3:method_name}
    # implementation
  end
end
```

#### Controller Snippets
```ruby
# Trigger: redmine_controller
class ${1:ControllerName}Controller < ApplicationController
  before_action :find_project, :authorize
  before_action :find_${2:model}, only: [:show, :edit, :update, :destroy]
  
  def index
    @${2:model}s = @project.${2:model}s.order(created_at: :desc)
  end
  
  def create
    @${2:model} = @project.${2:model}s.build(${2:model}_params)
    @${2:model}.created_by = User.current
    
    if @${2:model}.save
      flash[:notice] = l(:notice_${2:model}_created_successfully)
      redirect_to project_${2:model}s_path(@project)
    else
      render :new
    end
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def ${2:model}_params
    params.require(:${2:model}).permit(:${3:permitted_fields})
  end
end
```

#### Migration Snippets
```ruby
# Trigger: redmine_migration
class Create${1:TableName} < ActiveRecord::Migration[6.1]
  def change
    create_table :${2:table_name} do |t|
      t.references :project, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :${3:content}, null: false
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    add_index :${2:table_name}, [:project_id, :active]
  end
end
```

#### Hook Listener Snippets
```ruby
# Trigger: redmine_hook
module ${1:PluginName}
  class HooksListener < Redmine::Hook::ViewListener
    def ${2:hook_name}(context = {})
      ${3:issue} = context[:${3:issue}]
      project = context[:project]
      controller = context[:controller]
      
      return controller.render_to_string(
        partial: "${1:plugin_name}_hooks/${4:partial_name}",
        locals: { ${3:issue}: ${3:issue}, project: project }
      )
    end
  end
end
```

### File Templates

#### Plugin Init Template
```ruby
# File: init.rb
require 'redmine'

require File.expand_path('../lib/${plugin_name}/hooks_listener', __FILE__)

Redmine::Plugin.register :${plugin_name} do
  name '${Plugin Display Name}'
  author '${Author Name}'
  description '${Plugin Description}'
  version '0.1.0'
  url 'https://github.com/${author}/${plugin_name}'
  
  requires_redmine version_or_higher: '5.0.0'
  
  project_module :${module_name} do
    permission :view_${resource_name}, { :${controller_name} => [:index, :show] }
    permission :manage_${resource_name}, { :${controller_name} => [:new, :create, :edit, :update, :destroy] }
  end
  
  menu :project_menu, :${menu_item}, 
       { controller: '${controller_name}', action: 'index' },
       caption: :label_${menu_item}, 
       after: :activity, 
       param: :project_id
end
```

#### Rake Task Template
```ruby
# File: lib/tasks/${plugin_name}.rake
namespace :${plugin_name} do
  desc 'Description of the task'
  task :task_name => :environment do
    puts "Starting ${plugin_name} task..."
    
    # Task implementation
    
    puts "Task completed successfully"
  end
end
```

### Debug Configuration
```json
{
  "name": "Debug Rails Server",
  "type": "Ruby",
  "request": "launch",
  "program": "${workspaceRoot}/bin/rails",
  "args": ["server", "-p", "3000"],
  "env": {
    "RAILS_ENV": "development"
  }
}
```

### Cursor Composer Prompts

#### Common Prompts cho Plugin Development

**Tạo Model mới:**
```
Create a new Redmine plugin model called [ModelName] that:
- Belongs to project and created_by user
- Has fields: [list fields]
- Includes proper validations
- Has appropriate scopes
- Follows Redmine conventions
```

**Tạo Controller mới:**
```
Create a Redmine plugin controller for [ModelName] that:
- Includes proper before_actions
- Has CRUD operations
- Implements proper authorization
- Follows Redmine patterns
- Returns appropriate responses
```

**Tạo View templates:**
```
Create ERB view templates for [ModelName] that:
- Include index, show, new, edit, _form partials
- Use Redmine styling classes
- Include proper internationalization
- Have responsive design
- Follow Redmine UI patterns
```

**Database Migration:**
```
Create a database migration for [TableName] with:
- [list fields and types]
- Proper foreign keys
- Appropriate indexes
- Follows Rails 6.1 conventions
```

### AI Code Generation Guidelines

Khi sử dụng Cursor AI để generate code cho plugin:

1. **Context Setting**: Luôn mention đang làm việc với Redmine plugin
2. **Version Specification**: Chỉ rõ Redmine 5.x, Rails 6.1, Ruby 3.0
3. **Pattern Following**: Yêu cầu follow Redmine conventions
4. **Internationalization**: Nhớ include i18n support
5. **Testing**: Yêu cầu generate test cases
6. **Documentation**: Include comments và documentation

### Code Review Checklist cho Cursor

Khi review AI-generated code:

- [ ] Follows Redmine plugin structure
- [ ] Includes proper authorization checks
- [ ] Uses Redmine helpers và conventions
- [ ] Includes internationalization strings
- [ ] Has appropriate error handling
- [ ] Follows Ruby/Rails style guide
- [ ] Includes necessary validations
- [ ] Uses proper database relations
- [ ] Has appropriate indexes
- [ ] Includes test coverage

### Useful Cursor Commands

```bash
# Format Ruby code
Ctrl+Shift+P -> Format Document

# Show all symbols
Ctrl+T

# Go to definition
F12

# Find all references
Shift+F12

# Rename symbol
F2

# Quick fix
Ctrl+.
```

### Integration với Development Workflow

1. **Code Generation**: Sử dụng Cursor AI để generate boilerplate code
2. **Refactoring**: AI-assisted refactoring với context awareness
3. **Documentation**: Auto-generate comments và documentation
4. **Testing**: Generate test cases và fixtures
5. **Debugging**: AI-powered debugging suggestions
6. **Code Review**: AI-assisted code review comments

### Troubleshooting Common Issues

#### Ruby Language Server Issues
```bash
# Restart language server
Ctrl+Shift+P -> Ruby: Restart Language Server

# Rebuild Solargraph cache
bundle exec yard gems
```

#### Rails Issues
```bash
# Restart Rails server through Cursor
Ctrl+Shift+P -> Rails: Start Server

# Check Rails routes
bundle exec rails routes | grep plugin_name
``` 
