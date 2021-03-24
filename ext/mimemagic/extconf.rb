require "mkmf"

def locate_mime_database
  # User provided path.
  unless ENV["FREEDESKTOP_MIME_TYPES_PATH"].nil?
    path = File.expand_path(ENV["FREEDESKTOP_MIME_TYPES_PATH"])
    unless File.exist?(path)
      raise "The path #{path} was provided for the MIME types database, but no file exists at that path."
    end
    return path
  end

  # Default path on Linux installs for the MIME types database.
  return "/usr/share/mime/packages/freedesktop.org.xml" if File.exist?("/usr/share/mime/packages/freedesktop.org.xml")

  raise "No database of MIME types could be found. Ensure you have either installed the shared-mime-types package for your distribution, or obtain a version of freedesktop.org.xml, and set FREEDESKTOP_MIME_TYPES_PATH to the location of that file."
end

mime_database_path = locate_mime_database
$defs.push("-DMIMEDB_PATH=\\\"#{mime_database_path}\\\"")
create_header
create_makefile("mimemagic/mimemagic")