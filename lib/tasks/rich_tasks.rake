# == Assetize CKEditor
#
# This rake taks copies all CKEditor files from <tt>/vendor</tt> 
# to <tt>/public/assets/</tt>. Required when running Rich in production mode.
namespace :rich do
  
  desc "Copy CKEditor files to /public/assets for production"
  task :assetize_ckeditor => :environment do
    require 'find'
    puts "Rich - Copying CKEditor to your assets folder"
    
    if Rich.s3assets_force
      require 'find'
      s3config = YAML::load(File.open("#{Rails.root}/config/s3.yml"))
      s3 = AWS::S3.new(
        :access_key_id     => s3config[Rails.env.to_s]["access_key_id"],
        :secret_access_key => s3config[Rails.env.to_s]["secret_access_key"]
      )
      
      bucket = s3.buckets[s3config[Rails.env.to_s]["bucket"]]
      
      array = Array.new
      
      Find.find(Rich::Engine.root.join('vendor/assets/ckeditor/ckeditor/')) do |f|
        array << f.to_s
      end
      
      array.each do |f|
        if !File.directory? f.to_s
          file = f.to_s.split("vendor/assets/ckeditor/ckeditor/").last
          obj = bucket.objects["assets/ckeditor/ckeditor/" + file]
          content = File.read(f.to_s)
          obj.write(content)
          obj.acl=:public_read
        end
      end
      
      array = Array.new
      
      Find.find(Rich::Engine.root.join('vendor/assets/ckeditor/ckeditor-contrib/')) do |f|
        array << f.to_s
      end
      
      array.each do |f|
        if !File.directory? f.to_s
          file = f.to_s.split("vendor/assets/ckeditor/ckeditor-contrib/").last
          obj = bucket.objects["assets/ckeditor/ckeditor-contrib/" + file]
          content = File.read(f.to_s)
          obj.write(content)
          obj.acl=:public_read
        end
      end
      
    elsif Rich.s3assets_sync
      #Nothing sense its handle by another gem
    else
      mkdir_p Rails.root.join('public/assets/ckeditor')
      cp_r Rich::Engine.root.join('vendor/assets/ckeditor/ckeditor/.'), Rails.root.join('public/assets/ckeditor')
    
      mkdir_p Rails.root.join('public/assets/ckeditor-contrib')
      cp_r Rich::Engine.root.join('vendor/assets/ckeditor/ckeditor-contrib/.'), Rails.root.join('public/assets/ckeditor-contrib')
    end
  end
  
  desc "Clear CKEditor files from /public/assets"
  task :clean_ckeditor => :environment do
    puts "Rich - Removing CKEditor from your assets folder"
    begin
      rm_r Rails.root.join('public/assets/ckeditor')
      rm_r Rails.root.join('public/assets/ckeditor-contrib')
    rescue
      # the folder may not exist
    end
  end
  
  desc "Re-generate image styles"
  task :refresh_assets => :environment do
    # re-generate images
    ENV['CLASS'] = "Rich::RichFile"
    Rake::Task["paperclip:refresh"].invoke
    
    # re-generate uri cache
    Rich::RichFile.find_each(&:save)
  end
end

# Hook to automatically assetize ckeditor when precompiling assets
namespace :assets do
  task :precompile => 'rich:assetize_ckeditor'
  task :clean => 'rich:clean_ckeditor'
end