class ErbRenderer
    def initialize(model = nil)
        @locals = {}
        @current_template = ""
    end

    def infer_template_path(template_name)
        "#{__dir__}/templates/#{template_name}.erb"
    end

    def get_binding
        binding
    end

    def method_missing(method_name, *args)
        return @locals[method_name]
    end

    def render_template_new_binding(template_name, binding)
        template = ERB.new(File.open(infer_template_path(template_name), 'rb', &:read))
        exit("Could not find template for #{template_name}") if template.nil?
        @current_template = template_name
        template.result(binding)
    end

    def render_template(template_name, **locals)
        Log.instance.info "rendering #{template_name}, args name are #{locals.keys}"
        @locals = @locals.merge(locals)
        template = ERB.new(File.open(infer_template_path(template_name), 'rb', &:read))
        exit("Could not find template for #{template_name}") if template.nil?
        @current_template = template_name
        result = template.result(get_binding)
        result
    end
end
