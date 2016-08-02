module Haml::Helpers
  def render(partial, locals = {})
    dir      = File.dirname(__FILE__)
    filepath = File.join(dir, '..', 'assets', "_#{partial}.html.haml")
    file     = File.read(filepath)
    Haml::Engine.new(file).render(Object.new, locals)
  end
end
