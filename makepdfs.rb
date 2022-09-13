#!/usr/bin/env ruby
command_base = 'google-chrome-stable --headless --run-all-compositor-stages-before-draw --disable-gpu --window-size=1440,900 --virtual-time-budget=1000000 --print-to-pdf='
#slides.pdf ${{steps.gh-pages-url.outputs.URL}}
command_end = '?print-pdf&pdfSeparateFragments=false'
root = ARGV[0] || raise("Bad usage, missing argument: launch as ./makepdfs.rb ROOT_OF_THE_WEBSITE")
puts "Working inside #{root}"
remote = `git -C '#{root}' remote get-url origin`
puts "Detected remote: #{remote}"
url = remote.match(/^(git@|https:\/\/)github\.com(\/|:)(?<owner>[^\/]+)\/(?<repo>[^\/]+?)(\.git)?$/)
owner = url[:owner]
repo = url[:repo] == "#{owner}.github.io" ? "" : "/#{url[:repo]}"
files = Dir.glob("#{root}/**/index.html")
puts "Detected the following HTML roots:"
puts files
paths = Hash[
    files.map { |path|
        route = path.sub(root, '').gsub(/^\/?(.*)\/index.html$/) { $1 }
        [route.nil? || route.strip.empty? ? "index" : route.gsub('/', '_'), "https://#{owner}.github.io#{repo}/#{route}#{command_end}"]
    }
]
for name, path in paths do
    puts "Working on #{name} built from #{path}"
    output = "#{name}.pdf"
    command = "time #{command_base}#{output} '#{path}'"
    attempt = 0
    until (File.size?(output) || 0) / 1024 >= 3 do
        attempt = attempt + 1
        puts "ATTEMPT #{attempt}: launching #{command}"
        `#{command}`
    end
end
