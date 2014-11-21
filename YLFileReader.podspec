Pod::Spec.new do |s|
  s.name         = "YLFileReader"
  s.version      = "0.0.2"
  s.summary      = "YLFileReader is simple file reader."
  s.description  = <<-DESC
                   A longer description of YLFileReader in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC
  s.homepage     = "https://github.com/yaslab/YLFileReader"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "yaslab" => "yaslab99@gmail.com" }
  s.source       = { :git => "https://github.com/yaslab/YLFileReader.git", :tag => "0.0.2" }
  s.source_files = "YLFileReader/Classes/**/*.{h,m}"
  s.requires_arc = true
end
