#!/bin/bash
#=======================================================================================================================
# Tên tập lệnh: vns-web-debian.sh
# Mô tả: Tạo web cho user với Python và Next.js thông qua proxy NGINX trên hệ điều hành Debian.
# Đường dẫn: public/vns/platforms/vns-web-debian.sh
# Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>
# Ngày: 2023-08-25
# Phiên bản: 1.0.0
# Giấy phép: Giấy phép MIT
# Sử dụng: curl -sO https://vnscdn.com/platforms/vns-web-debian.sh && chmod +x vns-web-debian.sh && bash vns-web-debian.sh
#=======================================================================================================================

# Tạo user
echo "Tạo user"
read -p "Nhập tên user: " username
adduser $username

# Chuyển sang user vừa tạo
echo "Chuyển sang user vừa tạo"
su - $username

# Cài omyzsh cho user
curl -L http://install.ohmyz.sh | sh

# Kích hoạt omyzsh cho user
chsh -s /bin/zsh
exec zsh

# Tạo các thư mục cần thiết
mkdir -p ~/configs
mkdir -p ~/logs
mkdir -p ~/commands
mkdir -p ~/django/src
mkdir -p ~/nextjs
mkdir -p ~/ssl

# Thông tin người dùng và cơ sở dữ liệu
USERNAME="'$username'_user"
# Nhập password cho user
echo "Nhập password cho user"
read -p "Nhập password cho user: " password
PASSWORD="'$password'"
DATABASE="'$username'_db"

# Đăng nhập vào PostgreSQL và thực hiện tạo người dùng và cơ sở dữ liệu
sudo -u postgres psql << EOF
CREATE USER $USERNAME WITH PASSWORD '$PASSWORD';
CREATE DATABASE $DATABASE WITH OWNER $USERNAME;
GRANT ALL PRIVILEGES ON DATABASE $DATABASE TO $USERNAME;
GRANT CONNECT ON DATABASE $DATABASE TO $USERNAME;
GRANT USAGE ON SCHEMA public TO $USERNAME;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $USERNAME;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $USERNAME;
EOF

# Thông báo hoàn thành
echo "User $USERNAME and database $DATABASE have been created with appropriate privileges."