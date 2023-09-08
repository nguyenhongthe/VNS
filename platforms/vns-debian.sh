#!/bin/bash
#=======================================================================================================================
# Tên tập lệnh: vns-debian.sh
# Mô tả: Xây dựng máy chủ chạy web với Python và Next.js thông qua proxy NGINX trên hệ điều hành Debian.
# Đường dẫn: public/vns/platforms/vns-debian.sh
# Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>
# Ngày: 2023-08-25
# Phiên bản: 1.0.0
# Giấy phép: Giấy phép MIT
# Sử dụng: curl -sO https://vnscdn.com/platforms/vns-debian.sh && chmod +x vns-debian.sh && bash vns-debian.sh
#=======================================================================================================================

# Biến cho phiên bản và URL script
vns_version="1.0.0"
vns_debian_version="1.0.0"
vns_website_version="1.0.0"
script_url="https://vnscdn.com/"
desired_nginx_version="1.25.2"
low_ram='400000' # 400MB
recommended_ram='512000' # 512MB

#######################################################

echo
echo 'BẮT ĐẦU KIỂM TRA SWAP...'
echo

# Kiểm tra swap trên máy chủ
grep -q "swapfile" /etc/fstab

# Nếu chưa tồn tại thì tạo nó
if [ $? -ne 0 ]; then
  echo
  echo '#------------------------------------------------------#'
  echo '#    Không tìm thấy swapfile. Bắt đầu tạo swapfile    #'
  echo '#------------------------------------------------------#'
  echo

  echo -n "Nhập kích thước swap (MB): "
  read -r swapsize
  fallocate -l "${swapsize}"M /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap defaults 0 0' >> /etc/fstab
  chown -R root:root /swapfile
  chmod 0600 /swapfile
  sysctl vm.swappiness=10
  echo 'vm.swappiness=10' >> /etc/sysctl.conf
else
  echo
  echo '#------------------------------------------------------#'
  echo '#     Đã tìm thấy swap, không thực hiện thay đổi.      #'
  echo '#------------------------------------------------------#'
  echo
fi

echo
echo '#------------------------------------------------------#'
echo '#                   THÔNG TIN SWAP!                    #'
echo '#------------------------------------------------------#'
echo

# In kết quả ra terminal
cat /proc/swaps
# shellcheck disable=SC2002
cat /proc/meminfo | grep Swap

echo
echo '#------------------------------------------------------#'
echo '#                ĐÃ CÀI XONG SWAP!                     #'
echo '#------------------------------------------------------#'
echo


# Đọc thông tin về CPU, RAM, ổ đĩa và IP của máy chủ
cpu_name=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo)
cpu_cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
cpu_freq=$(awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo)
server_ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
server_ram_mb=`echo "scale=0;$server_ram_total/1024" | bc`
low_ram_mb=`echo "scale=0;$low_ram/1024" | bc`
recommended_ram_mb=`echo "scale=0;$recommended_ram/1024" | bc`
server_hdd=$(echo `df -h --total | grep 'total' | awk '{print $2}'` | sed 's/[^0-9]*//g')
server_swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
server_swap_mb=`echo "scale=0;$server_swap_total/1024" | bc`
server_ip=$(hostname -I | awk ' {print $1}')

clear

# In ra thông tin server
printf "===============================================================\n"
printf "               Thông số server của bạn như sau: \n"
echo "Loại CPU : $cpu_name"
echo "Tổng số CPU core : $cpu_cores"
echo "Tốc độ mỗi core : $cpu_freq MHz"
echo "Tổng dung lượng RAM : $server_ram_mb MB"
echo "Tổng dung lượng swap : $server_swap_mb MB"
echo "Tổng dung lượng ổ đĩa : $server_hdd GB"
echo "IP của server là : $server_ip"
printf "===============================================================\n"

# Kiểm tra dung lượng RAM của máy chủ
if [ $server_ram_total -lt $low_ram ]; then
    echo -e "Cảnh báo: RAM của máy chủ của bạn là $server_ram_mb MB, thấp hơn giá trị tối thiểu để có thể miễn cưỡng cài đặt là $low_ram_mb MB.\n"
    echo "Cài đặt đã bị hủy."
    exit 1
elif [ $server_ram_total -lt $recommended_ram ]; then
    echo -e "Cảnh báo: RAM của máy chủ của bạn là $server_ram_mb MB, thấp hơn giá trị tối thiểu khuyến nghị là $recommended_ram_mb MB để cài đặt VNS Script.\n"
    read -p "Bạn có muốn tiếp tục với việc cài đặt không? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "Cài đặt đã bị hủy."
        exit 1
    fi
fi

# Kiểm tra xem đã cài đặt zsh và oh-my-zsh chưa
if ! command -v zsh &> /dev/null; then
    echo "Cài đặt zsh và oh-my-zsh..."
    apt-get install git zsh
    curl -L http://install.ohmyz.sh | sh
    chsh -s /bin/zsh
    zsh
else
    echo "Đã cài đặt zsh và oh-my-zsh trước đó. Bỏ qua..."
fi

# Cài đặt ngôn ngữ
cat > /etc/default/locale <<EOT
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
EOT
sudo locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales

# Cài đặt thời gian sống của SSH
echo "ClientAliveInterval 120" >> /etc/ssh/sshd_config && service sshd restart

# Những lệnh sau đây nên chạy với quyền root hoặc sudo
# Có thể thêm -y để bỏ qua các thông báo xác nhận
# Điều chỉnh các tệp theo nhu cầu của bạn

# Cập nhật apt cache trước
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

# Cài đặt các gói cơ bản
sudo apt-get install -y \
    gawk bc wget curl memcached libmemcached-dev gettext lsof gnupg2 ca-certificates lsb-release debian-archive-keyring \
    curl xclip git webp build-essential libgd-dev libssl-dev tcl8.6 \
    software-properties-common apt-transport-https dirmngr \
    vim unzip htop mosh sudo ncdu multitail ncftp tmux rsync zip jq lftp \
    libncurses5-dev libncursesw5-dev libreadline6-dev libdb-dev \
    libgdbm-dev libsqlite3-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev \
    libcurl4-openssl-dev libpam0g-dev libsystemd-dev libffi-dev liblzma-dev \
    libxml2-dev libxslt1-dev libxslt-dev python-dev-is-python3 \
    python3-dev python3-setuptools libtiff-dev libjpeg62-turbo-dev zlib1g-dev \
    libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk \
    libgraphicsmagick++1-dev libboost-python-dev libmagic1 python3-pil \
    python3-pip python3-virtualenv python3-wheel python3-cffi python3-lxml python3.11-venv

# certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Cài đặt iptables
sudo apt-get install -y fail2ban

# auto load iptables
sudo apt-get install -y iptables-persistent

# Cấu hình rules cho iptables
echo "Cấu hình iptables..."
sudo tee /etc/iptables.rules > /dev/null << EOT
*filter
-A INPUT -i lo -j ACCEPT
-A INPUT -d 127.0.0.0/8 -j REJECT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -p tcp --dport 8080 -j ACCEPT
-A INPUT -i eno2 -s 192.168.0.0/24 -j ACCEPT
-A INPUT -p udp --dport 60000:60005 -j ACCEPT
-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
-A INPUT -j DROP
-A FORWARD -j DROP
COMMIT
EOT

sudo iptables-restore < /etc/iptables.rules

# Cài đặt netstat và công cụ theo dõi
sudo apt-get install -y net-tools nethogs iftop

# Cài đặt Nginx nếu chưa được cài đặt hoặc phiên bản không phù hợp
if ! command -v nginx &> /dev/null || nginx -v 2>&1 | grep -qF "$desired_nginx_version"; then
    echo "Cài đặt hoặc phiên bản Nginx phù hợp đã tồn tại. Bỏ qua..."
else
    echo "Bắt đầu quá trình biên dịch và cài đặt Nginx..."
    
    # Thư mục tạm để tải và giải nén mã nguồn Nginx
    temp_dir="/tmp/nginx_build"
    
    # Tạo thư mục tạm nếu chưa tồn tại
    mkdir -p "$temp_dir"
    
    # Di chuyển vào thư mục tạm
    cd "$temp_dir"
    
    # Tải mã nguồn Nginx từ trang chính thức
    curl -LO "https://nginx.org/download/nginx-$desired_nginx_version.tar.gz"
    
    # Giải nén mã nguồn
    tar -xzf "nginx-$desired_nginx_version.tar.gz"
    
    # Di chuyển vào thư mục mã nguồn Nginx
    cd "nginx-$desired_nginx_version"
    
    # Cài đặt các gói cần thiết để biên dịch
    sudo apt-get update
    sudo apt-get install -y build-essential zlib1g-dev libpcre3-dev libssl-dev libgeoip-dev libfl-dev libperl-dev
    
    # Configure và biên dịch Nginx
    ./configure \
        --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
        --prefix=/usr/share/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=stderr \
        --lock-path=/var/lock/nginx.lock \
        --pid-path=/run/nginx.pid \
        --modules-path=/usr/lib/nginx/modules \
        --http-client-body-temp-path=/var/lib/nginx/body \
        --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
        --http-proxy-temp-path=/var/lib/nginx/proxy \
        --http-scgi-temp-path=/var/lib/nginx/scgi \
        --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
        --with-debug \
        --with-pcre-jit \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-http_auth_request_module \
        --with-http_v2_module \
        --with-http_dav_module \
        --with-http_slice_module \
        --with-threads \
        --with-http_addition_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_sub_module \
        --with-mail_ssl_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-http_geoip_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_perl_module=dynamic \
        --with-http_xslt_module=dynamic \
        --with-mail=dynamic \
        --with-stream=dynamic \
        --with-stream_geoip_module=dynamic
    make
    sudo make install
    mv /usr/sbin/nginx /usr/sbin/nginx.bak
    cp objs/nginx /usr/sbin/nginx
    
    # Xóa thư mục tạm
    cd ~
    rm -rf "$temp_dir"
    
    # Kiểm tra và khởi động Nginx
    if ! command -v nginx &> /dev/null; then
        echo "Cài đặt Nginx không thành công."
    else
        echo "Cài đặt Nginx thành công."
        sudo systemctl restart nginx
        sudo systemctl enable nginx
    fi
fi


# Cài đặt Node.js phiên bản 18.x
if ! command -v node &> /dev/null; then
    echo "Cài đặt Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    node -v
    npm -v
else
    echo "Đã cài đặt Node.js trước đó. Bỏ qua..."
fi

# Kiểm tra xem đã cài đặt yarn chưa và cài đặt nếu chưa
if ! command -v yarn &> /dev/null; then
    echo "Cài đặt yarn..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get -y update
    sudo apt-get -y install yarn
else
    echo "Đã cài đặt yarn trước đó. Bỏ qua..."
fi

# Cài đặt PostgreSQL 15
# https://apt.postgresql.org/pub/repos/apt/README
if [ ! -d /var/lib/postgresql ]; then 
    echo "Cài đặt PostgreSQL..."
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt-get -y update
    sudo apt-get -y install postgresql-15
    sudo apt-get install -y libpq-dev
    sudo apt-get install -y postgresql-server-dev-all
    sudo apt-get install -y postgresql-common
else
    echo "Đã cài đặt PostgreSQL trước đó. Bỏ qua..."
fi

# Kiểm tra xem đã cài đặt Supervisor chưa
if ! command -v supervisord &> /dev/null; then
    echo "Cài đặt Supervisor..."
    sudo apt-get update
    sudo apt-get install -y supervisor
    
    # Khởi động dịch vụ Supervisor và cài đặt tự khởi động cùng hệ thống
    sudo systemctl start supervisor
    sudo systemctl enable supervisor
    
    echo "Đã cài đặt và khởi động Supervisor."
else
    echo "Đã cài đặt Supervisor trước đó. Bỏ qua..."
fi

# In ra thông tin chi tiết về phiên bản các package đã cài đặt
echo
echo '==============================================================='
echo '                THÔNG TIN PHIÊN BẢN PACKAGE                    '
echo '==============================================================='
echo "Phiên bản VNS Script: $vns_version"
echo "Phiên bản VNS Script cho Debian: $vns_debian_version"
echo "Phiên bản VNS Script cho Website: $vns_website_version"
echo "Phiên bản Node.js: $(node -v)"
echo "Phiên bản Yarn: $(yarn -v)"
echo "Phiên bản PostgreSQL: $(psql --version)"
echo "Phiên bản Nginx: $(nginx -v 2>&1 | grep -o '[0-9.]*')"
echo '==============================================================='

# Hoàn thành thông báo cài đặt
echo "Hoàn thành cài đặt trên hệ điều hành Debian."
echo "Vui lòng kiểm tra các bước cài đặt thêm sau khi hoàn tất."
echo "==============================================================="

exit 0
