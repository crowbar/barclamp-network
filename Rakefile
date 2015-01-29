#
# Copyright 2011-2013, Dell
# Copyright 2013-2014, SUSE LINUX Products GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

begin
  require 'sprockets/standalone'

  Sprockets::Standalone::RakeTask.new(:assets) do |task, sprockets|
    task.assets = [
      '**/application.js'
    ]

    task.sources = [
      'crowbar_framework/app/assets/javascripts'
    ]

    task.output = 'crowbar_framework/public/assets'

    task.compress = true
    task.digest = true

    sprockets.js_compressor = :closure
    sprockets.css_compressor = :sass
  end
rescue
end

task :syntaxcheck do
  system('for f in `find -name \*.rb`; do echo -n "Syntaxcheck $f: "; ruby -c $f || exit $? ; done')
  exit $?.exitstatus
end

task :default => [
  :syntaxcheck
]
