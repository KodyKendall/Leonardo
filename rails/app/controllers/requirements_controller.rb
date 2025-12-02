class RequirementsController < ApplicationController
  def index
    @current_path = params[:path] || ""
    @full_path = File.join("/rails", "requirements", @current_path)

    # Security: prevent directory traversal
    base_path = "/rails/requirements"
    if !@full_path.start_with?(base_path)
      return redirect_to requirements_path
    end

    # If path doesn't exist, redirect home
    if !File.exist?(@full_path)
      return redirect_to requirements_path
    end

    # If it's a file, show file content
    if File.file?(@full_path)
      # Only allow markdown and text files
      unless [".md", ".txt"].include?(File.extname(@full_path))
        return redirect_to requirements_path
      end
      @is_file = true
      @content = File.read(@full_path)
      @file_name = File.basename(@current_path)
    else
      # It's a directory, list files and folders
      @is_file = false
      @items = []
      Dir.glob(File.join(@full_path, "*")).sort.each do |item|
        name = File.basename(item)
        is_dir = File.directory?(item)
        @items << {
          name: name,
          path: File.join(@current_path, name),
          is_dir: is_dir,
          display_name: is_dir ? "📁 #{name}" : "📄 #{name}"
        }
      end
    end

    # Build breadcrumb
    @breadcrumbs = build_breadcrumbs(@current_path)
  end

  private

  def build_breadcrumbs(path)
    breadcrumbs = [{ name: "Requirements", path: "" }]
    parts = path.split("/").reject(&:empty?)
    
    parts.each_with_index do |part, index|
      breadcrumb_path = parts[0..index].join("/")
      breadcrumbs << { name: part, path: breadcrumb_path }
    end

    breadcrumbs
  end
end
