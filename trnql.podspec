Pod::Spec.new do |s|

    s.name         = "trnql"
    s.platform     = :ios, "8.0"
    s.version      = "1.8"
    s.summary      = "Easily integrate 'contextual awareness' from sensors, phone data & cloud services into engaging applications"
    s.homepage     = "http://trnql.com/"
    s.license      = { :type => "Copyright (C) 2015 trnql, Inc.", :file => "LICENSE" }
    s.author       = "trnql"
    s.source       = { :git => "https://github.com/trnql/trnql_ios.git", :tag => "1.8" }
    s.vendored_frameworks = 'trnql/trnql.framework'
    s.requires_arc = true

end