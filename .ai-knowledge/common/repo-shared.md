# Tham chiếu đến kiến thức chung giữa các repository

## Redmine Plugin Development Best Practices

Thông tin này được chia sẻ chung giữa tất cả các Redmine plugin projects trong organization.

### Các quy ước chung
- Tuân theo Redmine Plugin Development Guidelines
- Sử dụng Ruby Style Guide và Rails conventions
- Implement proper testing với RSpec hoặc Rails Test Framework
- Sử dụng RuboCop cho code style enforcement
- Implement proper I18n support từ đầu

### Cấu trúc plugin chuẩn
```
plugins/plugin_name/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   └── helpers/
├── assets/
│   ├── javascripts/
│   ├── stylesheets/
│   └── images/
├── config/
│   ├── locales/
│   └── routes.rb
├── db/
│   └── migrate/
├── lib/
│   ├── tasks/
│   └── plugin_name/
├── test/
├── init.rb
└── README.md
```

### Environment Requirements
- **Production Redmine Version**: 5.0.6.stable
- **Ruby Version**: 3.0.6
- **Rails Version**: 6.1.7.6
- **Database**: MySQL/PostgreSQL
- **Web Server**: Nginx với server blocks

### Common Dependencies
```ruby
# Gemfile dependencies thường dùng
gem 'httpclient', '~> 2.8'    # Cho HTTP requests
gem 'chronic'                 # Cho date/time parsing
gem 'acts_as_list'           # Cho ordering functionality
```

### Security Guidelines
- Luôn validate user inputs
- Sử dụng HTTPS cho webhooks
- Implement proper authorization checks
- Sanitize HTML content
- Use Rails CSRF protection

### Performance Best Practices
- Sử dụng database indexes cho frequently queried fields
- Implement efficient scopes và queries
- Use includes() để tránh N+1 queries
- Implement caching khi cần thiết
- Monitor memory usage trong background jobs

### Testing Standards
- Unit tests cho tất cả models
- Functional tests cho controllers
- Integration tests cho complete workflows
- Fixtures hoặc factories cho test data
- Code coverage minimum 80%

### Documentation Requirements
- README.md với clear installation instructions
- Code comments cho complex business logic
- API documentation nếu có public APIs
- Migration notes cho database changes
- Troubleshooting guide

### Git Workflow
- GitFlow với main/develop branches
- Feature branches cho new features
- Semantic versioning (MAJOR.MINOR.PATCH)
- Conventional commit messages
- Pull request reviews required

### Deployment Practices
- Environment-specific configurations
- Database migration rollback plans
- Zero-downtime deployment strategies
- Health checks và monitoring
- Backup strategies

### Monitoring và Logging
- Structured logging với proper log levels
- Error tracking và alerting
- Performance monitoring
- User activity tracking (nếu cần thiết)
- System health monitoring

## Shared Resources

### Development Tools
- RuboCop configuration files
- Test fixtures và helpers
- Docker configurations cho development
- CI/CD pipeline templates

### Documentation Templates
- README.md template
- CHANGELOG.md format
- Issue templates
- Pull request templates

### Shared Libraries
Các utility classes và modules có thể được chia sẻ:
- HTTP client wrappers
- Date/time utilities
- Validation helpers
- Email notification services
- Webhook handling utilities

## Cross-Plugin Integration

### Event System
Sử dụng Rails callbacks và Redmine hooks để tạo loose coupling:
```ruby
# Plugin A publishes events
ActiveSupport::Notifications.instrument('plugin_a.item_created', item: @item)

# Plugin B subscribes to events
ActiveSupport::Notifications.subscribe('plugin_a.item_created') do |name, start, finish, id, payload|
  # Handle the event
end
```

### Shared Models
Đối với data cần chia sẻ giữa plugins:
- Use Redmine core models khi có thể
- Create shared gems cho common models
- Implement proper plugin dependencies

### Configuration Management
- Environment variables cho sensitive data
- Shared configuration files
- Plugin-specific settings trong init.rb
- Database-based configuration cho runtime settings 
