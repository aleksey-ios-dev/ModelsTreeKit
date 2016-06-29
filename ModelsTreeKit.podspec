Pod::Spec.new do |s|

  s.name         = "ModelsTreeKit"
  s.version      = "1.0.0"
  s.summary      = "Set of tools for building 'Tree of models' architecture"

  s.description  = <<-DESC
                Set of tools for building 'Tree of models' architecture
                   DESC

  s.homepage     = "https://github.com/mmrmmlrr/ModelsTreeKit"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "aleksey" => "aleksey.chernish@yalantis.com" }

  s.platform     = :ios
  s.ios.deployment_target = "8.0"

  s.dependency 'JetPack', :git => "https://github.com/mmrmmlrr/JetPack"
  
end
