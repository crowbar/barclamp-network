task :default => [:syntaxcheck]

task :syntaxcheck do
  system('for f in `find -name \*.rb` ; do echo -n "Syntaxcheck $f: "; ruby -c $f || exit $? ; done')
  exit $?.exitstatus
end
