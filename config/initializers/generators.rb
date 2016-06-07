Rails.application.configure do
  config.generators do |g|
    g.test_framework :rspec, :fixtures => false, :fixture_replacement => :factory_girl
    g.helper false
    g.controller :assets => false
    g.template_engine :slim
  end
end
