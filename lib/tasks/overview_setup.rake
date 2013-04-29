# This is the setup information. Root path names and other things like that go here 
home_path                 = `echo $HOME`.gsub("\n", "") # This will resolve the absolute path of your home directory
shared_path               = "#{home_path}/shared"
shared_public_path        = "#{shared_path}/public"

# This is path information for the current application that you are working on
temp_downloads_path       = "#{Rails.root}/tmp/downloads" # These are all the files downloaded
javascript_path           = "#{Rails.root}/public/javascript"
maps_path                 = "#{Rails.root}/public/maps"
minecraft_bin_path        = "#{home_path}/.minecraft/bin"
world_maps_path           = maps_path + "/world"
download_maps_path        = maps_path + "/downloaded"

sys_download_maps_path    = "#{shared_public_path}/maps/downloaded"

# This is the public constant data. Information that should not change when you do a cap deploy or any type of deploy
sys_maps_path             = "#{shared_public_path}/maps" # These show a mirror to the application however they are not required. Please mirror to deploy.rb
sys_javascript_path       = "#{shared_public_path}/javascript" # These show a mirror to the application however they are not required. Please mirror to deploy.rb

# Config Information
overviewer_config_path    = "#{Rails.root}/config/overviewer_config.py" # This is the configuration information for overviewer generator
overviewer_generator_path = "#{Rails.root}/lib/tasks/overview_generator"

# Python Image Library or the url to the python_image
python_imaging_url = "http://effbot.org/downloads/Imaging-1.1.7.tar.gz"

complete_message  = "complete".green
failed_message    = "failed".red
success_message   = "Task has been completed".green
error_message     = "Task could not be completed".red

namespace :doctor do
  desc "This is just a nice way to check the health of everything. It will check to see if all your paths are there."
  task :who do
    paths = [home_path, shared_path, shared_public_path, temp_downloads_path, javascript_path, maps_path, minecraft_bin_path, world_maps_path, download_maps_path, sys_maps_path, sys_javascript_path, overviewer_config_path, overviewer_generator_path, "#{maps_path}/world"]
    paths.each do |path|
      print "Checking #{path}....."
      puts File.exists?(path) ? "Found".green : "Missing".red
    end
  end
end


namespace :setup do
  
  desc "Setup for mac and linux cold it will discover what OS your using and choose correctly"
  task :cold do

    Rake::Task['setup:paths:cold'].invoke
    
    case RUBY_PLATFORM
    when "x86_64-darwin11.3.0"
      puts "I Believe this OS is MAC OS X 10.7.5 I will not run the mkdir -p #{minecraft_bin_path}".cyan
      puts "Please install minecraft.jar file into the correct path. Have not total looked this information over so be careful".cyan
    else
      `mkdir -p #{minecraft_bin_path}`
      print "Downloading mincraft.jar and placing it into #{minecraft_bin_path} ... ".yellow
      `wget --quiet -N http://s3.amazonaws.com/MinecraftDownload/minecraft.jar -P #{minecraft_bin_path}`
      puts (File.exists?(minecraft_bin_path) ? complete_message : failed_message)
    end
    
    Rake::Task['compile:python_imaging'].invoke
    
    Rake::Task['compile:overviewer'].invoke
    
    Rake::Task['map:cold'].invoke
  end
  
  
  namespace :paths do
    
    create_paths = [temp_downloads_path, shared_path, shared_public_path, sys_maps_path, sys_javascript_path, sys_download_maps_path]
    destroy_paths = create_paths + [maps_path]
    
    # It will create all the directories/folders/files
    task :create do
      for path in create_paths
        print ("mkdir -p " + path + "... ").yellow
        system "mkdir -p " + path
        puts (File.exists?(path) ? complete_message : failed_message)
      end
    end
    
    
    desc "First Time building the paths"
    task :cold do
      
      Rake::Task['setup:paths:create'].invoke
      
      Rake::Task['setup:paths:symlink'].invoke
      
      puts "Asking The Doctor what he thinks".yellow
      Rake::Task['doctor:who'].invoke
    end
    desc "Destroy all the paths created by build "
    task :destroy do
      for path in destroy_paths
        print ("rm -rf " + path + "... ").yellow
        system "rm -rf " + path
        puts (File.exists?(path) ? failed_message : complete_message)
      end
      
      puts "Asking The Doctor what he thinks".yellow
      
      Rake::Task['doctor:who'].invoke
    end
    
    desc "Create system links between maps, and javascript paths"
    task :symlink do
      print "ln -nfs #{sys_maps_path} #{maps_path} ... ".yellow
      `ln -nfs #{sys_maps_path} #{maps_path}` # Don't need the -nfs but it is a nice extra PLEASE LOOK UP before removing
      puts (File.exists?(sys_maps_path) ? complete_message : failed_message)
    
      print "ln -nfs #{sys_javascript_path} #{javascript_path} ... ".yellow
      `ln -nfs #{sys_javascript_path} #{javascript_path}` # Don't need the -nfs but it is a nice extra PLEASE LOOK UP before removing
      puts (File.exists?(sys_javascript_path) ? complete_message : failed_message)
    end
  end
  

  
  desc "Setup For Mac"
  task :mac do
    puts "Currently there is nothing needed for setup for mac. Just run rake setup:cold and everything will be ready.".yellow
  end
  
  desc "Setup For Linux"
  task :linux do
    `apt-get install python-imaging`
    `apt-get install python-dev`
    `apt-get install python-numpy`
    `apt-get install python-scipy`
    
    `ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib` # link the correct image paths to the correct dirrectory
    `ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib` # link the correct image paths to the correct dirrectory
    `ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib` # link the correct image paths to the correct dirrectory
  end
end

namespace :compile do
  
  desc "Python Imaging library downloaded from #{python_imaging_url}"
  task :python_imaging do
    `cd #{temp_downloads_path} && curl -O -L #{python_imaging_url}`
    `cd #{temp_downloads_path} && tar -xzf Imaging-1.1.7.tar.gz`
    `python #{temp_downloads_path}/Imaging-1.1.7/setup.py clean`
    `python #{temp_downloads_path}/Imaging-1.1.7/setup.py build`
    `python #{temp_downloads_path}/Imaging-1.1.7/setup.py install`
  end
  
  desc "Setup overview generater or better we are going to compile the setup.py information"
  task :overviewer do
    setup_python = "#{overviewer_generator_path}/setup.py"
    lib_imaging  = "#{temp_downloads_path}/Imaging-1.1.7/libImaging"
    if FileTest.exists?(setup_python) && FileTest.exists?(lib_imaging) 
      `python #{setup_python} clean`
      `PIL_INCLUDE_DIR='#{lib_imaging}' python #{setup_python} build`
      puts success_message
    else
      puts "We are missing #{setup_python} or #{lib_imaging} is missing. If you have run into this error please run rake compile:python_imaging".red
    end
  end
end

namespace :map do
  desc "First Time setup for you maps"
  task :cold do
    
    Rake::Task['map:copy'].invoke
    
    Rake::Task['map:unzip'].invoke
    
    Rake::Task['map:generate'].invoke
  end
  
  desc "It will destroy all your map information will not ask it just does"
  task :implode do
    print "DESTROYING ALL MAP INFORMATION.....".red
    `rm -rf #{download_maps_path}/world.tar.gz`
    `rm -rf #{maps_path}/world`
    puts complete_message
  end
  
  desc "Generate the map located in #{sys_javascript_path}"
  task :generate do
    
    puts "We could not located a map in this path #{maps_path}/world".red unless File.exists?("#{world_maps_path}")
    puts `python #{overviewer_generator_path}/overviewer.py --config=#{overviewer_config_path}`
    puts (File.exists?(overviewer_generator_path) ? complete_message : failed_message)
  end
  
  desc "Copy the map from the sever. This will be removed an not used in the future."
  task :copy do
    # Static informaiton for now. Update in the future
    puts "Copying the Map information from the server".yellow
    `ssh mcmyadmin@mcadmin.r3dux.net 'rm -rf world.tar.gz && cd ~/mcmyadmin/Minecraft/ && tar -cvf ~/world.tar world && gzip ~/world.tar'`
    puts "logged-in and ran commands".green
    
    # Remote old world file. Switching commmand to version in future.
    `rm -rf #{download_maps_path}/world.tar.gz`
    puts "Removed world.tar.gz from folder".green
    
    puts "Downloading file from server ...".yellow
    `scp mcmyadmin@mcadmin.r3dux.net:~/world.tar.gz #{download_maps_path}/world.tar.gz`
    puts (File.exists?("#{download_maps_path}/world.tar.gz") ? success_message : error_message)
  end
  
  desc "Unzip your downloaded map run rake map:copy first"
  task :unzip do
    
    puts "We could not locate needed file in this path #{download_maps_path}/world.tar.gz".red unless File.exists?("#{download_maps_path}/world.tar.gz")
      
    puts "Unziping #{download_maps_path}/world.tar.gz and moving it to #{maps_path}".yellow
    `tar xvzf #{download_maps_path}/world.tar.gz -C #{maps_path}`
    puts (File.exists?("#{world_maps_path}") ? success_message : error_message)
  end
end