class Monroe
  def erb(view, local = {})
    b = binding
    message = local[:message]
    template = File.read("views/#{view}.erb")
    ERB.new(template).result(b)
  end
  
  def response(status, headers, body = '')
    body = yield if block_given?
    [status, headers, [body]]
  end
end
