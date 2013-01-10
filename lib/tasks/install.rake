namespace :install do
  desc "Setup PIL for MAC or LINUX"
  task :pil do
    `cd ./tmp/files/ && curl -O -L http://effbot.org/downloads/Imaging-1.1.7.tar.gz`
    `cd ./tmp/files/ && tar -xzf Imaging-1.1.7.tar.gz`
    `python ./tmp/files/Imaging-1.1.7/setup.py clean`
    `python ./tmp/files/Imaging-1.1.7/setup.py build`
    `sudo python ./tmp/files/Imaging-1.1.7/setup.py install`
    `rm -rf ./tmp/files/Imaging-1.1.7.tar.gz`
  end
end