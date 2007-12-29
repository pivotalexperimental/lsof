class SpecSuite
  def run
    dir = File.dirname(__FILE__)
    Dir["#{dir}/**/*_spec.rb"].each do |file|
      require file
    end
  end
end

if __FILE__ == $0
  SpecSuite.new.run
end